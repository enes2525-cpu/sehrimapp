import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/post_model.dart';
import '../data/models/comment_model.dart';

class FeedService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Post oluştur
  static Future<String> createPost({
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String content,
    List<String>? images,
  }) async {
    final post = PostModel(
      id: '',
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      content: content,
      images: images,
      createdAt: DateTime.now(),
    );

    final docRef = await _db.collection('posts').add(post.toMap());
    return docRef.id;
  }

  // Post'ları getir (stream)
  static Stream<List<PostModel>> getPosts({int limit = 20}) {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  // Kullanıcının post'larını getir
  static Stream<List<PostModel>> getUserPosts(String userId) {
    return _db
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList());
  }

  // Post'u beğen/beğeniyi kaldır
  static Future<void> toggleLike(String postId, String userId) async {
    final postRef = _db.collection('posts').doc(postId);
    
    await _db.runTransaction((transaction) async {
      final postDoc = await transaction.get(postRef);
      if (!postDoc.exists) return;

      final post = PostModel.fromFirestore(postDoc);
      final likedBy = List<String>.from(post.likedBy);

      if (likedBy.contains(userId)) {
        // Beğeniyi kaldır
        likedBy.remove(userId);
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likeCount': FieldValue.increment(-1),
        });
      } else {
        // Beğen
        likedBy.add(userId);
        transaction.update(postRef, {
          'likedBy': likedBy,
          'likeCount': FieldValue.increment(1),
        });
      }
    });
  }

  // Yorum ekle
  static Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userPhotoUrl,
    required String content,
  }) async {
    final comment = CommentModel(
      id: '',
      postId: postId,
      userId: userId,
      userName: userName,
      userPhotoUrl: userPhotoUrl,
      content: content,
      createdAt: DateTime.now(),
    );

    await _db.collection('comments').add(comment.toMap());

    // Post'un yorum sayısını artır
    await _db.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  // Post'un yorumlarını getir
  static Stream<List<CommentModel>> getComments(String postId) {
    return _db
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromFirestore(doc))
            .toList());
  }

  // Post sil
  static Future<void> deletePost(String postId) async {
    // Yorumları sil
    final comments = await _db
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .get();

    for (var doc in comments.docs) {
      await doc.reference.delete();
    }

    // Post'u sil
    await _db.collection('posts').doc(postId).delete();
  }

  // Yorum sil
  static Future<void> deleteComment(String commentId, String postId) async {
    await _db.collection('comments').doc(commentId).delete();

    // Post'un yorum sayısını azalt
    await _db.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }
}
