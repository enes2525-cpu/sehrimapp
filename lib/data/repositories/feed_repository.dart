import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/constants/app_constants.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'token_repository.dart';

/// Feed (Sosyal) işlemlerini yöneten Repository
/// Post + Comment + Like + Token
class FeedRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TokenRepository _tokenRepository;

  FeedRepository({
    TokenRepository? tokenRepository,
  }) : _tokenRepository = tokenRepository ?? TokenRepository();

  // ========== POST İŞLEMLERİ ==========

  /// Post oluştur
  Future<Result<String>> createPost({
    required String userId,
    required String content,
    List<String>? images,
  }) async {
    try {
      // İçerik kontrolü
      if (content.trim().isEmpty) {
        return Result.error('İçerik boş olamaz');
      }

      if (content.length > AppConstants.maxPostLength) {
        return Result.error(
          'İçerik maksimum ${AppConstants.maxPostLength} karakter olabilir',
        );
      }

      // Resim sayısı kontrolü
      if (images != null && images.length > AppConstants.maxPostImages) {
        return Result.error(
          'Maksimum ${AppConstants.maxPostImages} resim eklenebilir',
        );
      }

      // Kullanıcı bilgisi
      final userDoc = await _db
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return Result.error('Kullanıcı bulunamadı');
      }

      final userData = userDoc.data()!;
      final userName = userData['name'] ?? 'İsimsiz';
      final userPhotoUrl = userData['photoUrl'];

      // Post oluştur
      final postData = {
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'content': content,
        'images': images ?? [],
        'likeCount': 0,
        'commentCount': 0,
        'likedBy': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      final postDoc = await _db
          .collection(AppConstants.collectionPosts)
          .add(postData);

      return Result.success(postDoc.id);
    } catch (e) {
      return Result.error('Post oluşturulurken hata: ${e.toString()}');
    }
  }

  /// Post sil
  Future<Result<void>> deletePost(String postId, String userId) async {
    try {
      final postDoc = await _db
          .collection(AppConstants.collectionPosts)
          .doc(postId)
          .get();

      if (!postDoc.exists) {
        return Result.error('Post bulunamadı');
      }

      final postUserId = postDoc.data()?['userId'];
      if (postUserId != userId) {
        return Result.error('Bu post\'u silme yetkiniz yok');
      }

      // Yorumları da sil
      final comments = await _db
          .collection(AppConstants.collectionComments)
          .where('postId', isEqualTo: postId)
          .get();

      final batch = _db.batch();
      for (var comment in comments.docs) {
        batch.delete(comment.reference);
      }

      // Post'u sil
      batch.delete(postDoc.reference);
      await batch.commit();

      return Result.success(null);
    } catch (e) {
      return Result.error('Post silinirken hata: ${e.toString()}');
    }
  }

  /// Post getir
  Future<Result<PostModel>> getPost(String postId) async {
    try {
      final postDoc = await _db
          .collection(AppConstants.collectionPosts)
          .doc(postId)
          .get();

      if (!postDoc.exists) {
        return Result.error('Post bulunamadı');
      }

      final post = PostModel.fromFirestore(postDoc);
      return Result.success(post);
    } catch (e) {
      return Result.error('Post yüklenirken hata: ${e.toString()}');
    }
  }

  // ========== POST LİSTELEME ==========

  /// Tüm post'ları getir (Stream)
  Stream<List<PostModel>> getPosts({int limit = 20}) {
    return _db
        .collection(AppConstants.collectionPosts)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  /// Kullanıcının post'larını getir
  Stream<List<PostModel>> getUserPosts(String userId, {int limit = 20}) {
    return _db
        .collection(AppConstants.collectionPosts)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  /// Takip edilen kullanıcıların post'ları
  Future<Result<List<PostModel>>> getFollowingPosts(
    String userId, {
    int limit = 20,
  }) async {
    try {
      // Takip edilen kullanıcıları getir
      final followingSnapshot = await _db
          .collection(AppConstants.collectionFollows)
          .where('followerId', isEqualTo: userId)
          .get();

      final followingIds = followingSnapshot.docs
          .map((doc) => doc.data()['followingId'] as String)
          .toList();

      if (followingIds.isEmpty) {
        return Result.success([]);
      }

      // Firestore 'in' query limiti 10
      if (followingIds.length > 10) {
        followingIds.removeRange(10, followingIds.length);
      }

      // Post'ları getir
      final postsSnapshot = await _db
          .collection(AppConstants.collectionPosts)
          .where('userId', whereIn: followingIds)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final posts = postsSnapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();

      return Result.success(posts);
    } catch (e) {
      return Result.error('Post'lar yüklenirken hata: ${e.toString()}');
    }
  }

  // ========== LIKE İŞLEMLERİ ==========

  /// Post'u beğen/beğeniyi kaldır
  Future<Result<void>> toggleLike(String postId, String userId) async {
    try {
      // Token kontrolü (beğeni için)
      final isLiked = await _isPostLiked(postId, userId);

      if (!isLiked) {
        // Beğenirken token kontrolü
        final hasEnough = await _tokenRepository.hasEnoughTokens(
          userId,
          AppConstants.tokenPerLike,
        );

        if (!hasEnough) {
          return Result.error(
            'Yetersiz token. Beğenmek için ${AppConstants.tokenPerLike} token gerekli.',
          );
        }

        // Beğen
        await _db.runTransaction((transaction) async {
          final postRef = _db.collection(AppConstants.collectionPosts).doc(postId);
          final postDoc = await transaction.get(postRef);

          if (!postDoc.exists) {
            throw Exception('Post bulunamadı');
          }

          final likedBy = List<String>.from(postDoc.data()?['likedBy'] ?? []);
          likedBy.add(userId);

          transaction.update(postRef, {
            'likedBy': likedBy,
            'likeCount': FieldValue.increment(1),
          });
        });

        // Token düş
        await _tokenRepository.deductTokens(
          userId,
          AppConstants.tokenPerLike,
          reason: 'Post beğenme',
          metadata: {'postId': postId},
        );

        // Post sahibine bildirim gönder
        await _sendLikeNotification(postId, userId);
      } else {
        // Beğeniyi kaldır
        await _db.runTransaction((transaction) async {
          final postRef = _db.collection(AppConstants.collectionPosts).doc(postId);
          final postDoc = await transaction.get(postRef);

          if (!postDoc.exists) {
            throw Exception('Post bulunamadı');
          }

          final likedBy = List<String>.from(postDoc.data()?['likedBy'] ?? []);
          likedBy.remove(userId);

          transaction.update(postRef, {
            'likedBy': likedBy,
            'likeCount': FieldValue.increment(-1),
          });
        });

        // Token iade et
        await _tokenRepository.addTokens(
          userId,
          AppConstants.tokenPerLike,
          reason: 'Beğeni kaldırma',
          metadata: {'postId': postId},
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.error('Beğeni işlemi başarısız: ${e.toString()}');
    }
  }

  /// Post beğenilmiş mi?
  Future<bool> _isPostLiked(String postId, String userId) async {
    try {
      final postDoc = await _db
          .collection(AppConstants.collectionPosts)
          .doc(postId)
          .get();

      if (!postDoc.exists) return false;

      final likedBy = List<String>.from(postDoc.data()?['likedBy'] ?? []);
      return likedBy.contains(userId);
    } catch (e) {
      return false;
    }
  }

  // ========== YORUM İŞLEMLERİ ==========

  /// Yorum ekle
  Future<Result<String>> addComment({
    required String postId,
    required String userId,
    required String text,
  }) async {
    try {
      if (text.trim().isEmpty) {
        return Result.error('Yorum boş olamaz');
      }

      if (text.length > AppConstants.maxCommentLength) {
        return Result.error(
          'Yorum maksimum ${AppConstants.maxCommentLength} karakter olabilir',
        );
      }

      // Kullanıcı bilgisi
      final userDoc = await _db
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return Result.error('Kullanıcı bulunamadı');
      }

      final userData = userDoc.data()!;
      final userName = userData['name'] ?? 'İsimsiz';
      final userPhotoUrl = userData['photoUrl'];

      // Yorum ekle
      final commentData = {
        'postId': postId,
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final commentDoc = await _db
          .collection(AppConstants.collectionComments)
          .add(commentData);

      // Post'un yorum sayısını artır
      await _db.collection(AppConstants.collectionPosts).doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Post sahibine bildirim gönder
      await _sendCommentNotification(postId, userId, text);

      return Result.success(commentDoc.id);
    } catch (e) {
      return Result.error('Yorum eklenirken hata: ${e.toString()}');
    }
  }

  /// Yorum sil
  Future<Result<void>> deleteComment(
    String commentId,
    String userId,
  ) async {
    try {
      final commentDoc = await _db
          .collection(AppConstants.collectionComments)
          .doc(commentId)
          .get();

      if (!commentDoc.exists) {
        return Result.error('Yorum bulunamadı');
      }

      final commentData = commentDoc.data()!;
      final commentUserId = commentData['userId'];
      final postId = commentData['postId'];

      // Yorum sahibi veya post sahibi silebilir
      final postDoc = await _db
          .collection(AppConstants.collectionPosts)
          .doc(postId)
          .get();

      final postOwnerId = postDoc.data()?['userId'];

      if (commentUserId != userId && postOwnerId != userId) {
        return Result.error('Bu yorumu silme yetkiniz yok');
      }

      // Yorumu sil
      await commentDoc.reference.delete();

      // Post'un yorum sayısını azalt
      await _db.collection(AppConstants.collectionPosts).doc(postId).update({
        'commentCount': FieldValue.increment(-1),
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Yorum silinirken hata: ${e.toString()}');
    }
  }

  /// Post yorumlarını getir (Stream)
  Stream<List<CommentModel>> getComments(String postId) {
    return _db
        .collection(AppConstants.collectionComments)
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromFirestore(doc))
            .toList());
  }

  // ========== BİLDİRİM ==========

  /// Beğeni bildirimi gönder
  Future<void> _sendLikeNotification(String postId, String likerId) async {
    try {
      final post = await getPost(postId);
      if (!post.isSuccess) return;

      final postOwnerId = post.data!.userId;
      if (postOwnerId == likerId) return; // Kendine bildirim gönderme

      final likerDoc = await _db
          .collection(AppConstants.collectionUsers)
          .doc(likerId)
          .get();

      final likerName = likerDoc.data()?['name'] ?? 'Bir kullanıcı';

      await NotificationService.notifyPostLike(
        postOwnerId: postOwnerId,
        likerName: likerName,
        postId: postId,
      );
    } catch (e) {
      print('Bildirim gönderilemedi: $e');
    }
  }

  /// Yorum bildirimi gönder
  Future<void> _sendCommentNotification(
    String postId,
    String commenterId,
    String commentText,
  ) async {
    try {
      final post = await getPost(postId);
      if (!post.isSuccess) return;

      final postOwnerId = post.data!.userId;
      if (postOwnerId == commenterId) return; // Kendine bildirim gönderme

      final commenterDoc = await _db
          .collection(AppConstants.collectionUsers)
          .doc(commenterId)
          .get();

      final commenterName = commenterDoc.data()?['name'] ?? 'Bir kullanıcı';

      await NotificationService.notifyComment(
        postOwnerId: postOwnerId,
        commenterName: commenterName,
        postId: postId,
        commentText: commentText,
      );
    } catch (e) {
      print('Bildirim gönderilemedi: $e');
    }
  }

  // ========== İSTATİSTİKLER ==========

  /// Post istatistikleri
  Future<Result<Map<String, dynamic>>> getPostStats(String postId) async {
    try {
      final post = await getPost(postId);
      if (!post.isSuccess) {
        return Result.error(post.error ?? 'Post bulunamadı');
      }

      final postData = post.data!;

      final stats = {
        'postId': postId,
        'userId': postData.userId,
        'likeCount': postData.likeCount,
        'commentCount': postData.commentCount,
        'createdAt': postData.createdAt,
      };

      return Result.success(stats);
    } catch (e) {
      return Result.error('İstatistikler yüklenirken hata: ${e.toString()}');
    }
  }

  /// Kullanıcı post istatistikleri
  Future<Result<Map<String, dynamic>>> getUserPostStats(String userId) async {
    try {
      final posts = await _db
          .collection(AppConstants.collectionPosts)
          .where('userId', isEqualTo: userId)
          .get();

      int totalLikes = 0;
      int totalComments = 0;

      for (var post in posts.docs) {
        totalLikes += (post.data()['likeCount'] ?? 0) as int;
        totalComments += (post.data()['commentCount'] ?? 0) as int;
      }

      final stats = {
        'totalPosts': posts.docs.length,
        'totalLikes': totalLikes,
        'totalComments': totalComments,
        'averageLikes': posts.docs.isEmpty ? 0 : totalLikes / posts.docs.length,
      };

      return Result.success(stats);
    } catch (e) {
      return Result.error('İstatistikler hesaplanırken hata: ${e.toString()}');
    }
  }
}
