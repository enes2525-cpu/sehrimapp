import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import 'notification_repository.dart';
import 'user_repository.dart';

/// Takip sistemi Repository
class FollowRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationRepository _notificationRepo = NotificationRepository();
  final UserRepository _userRepo = UserRepository();

  // Takip et
  Future<Result<void>> followUser(String followingId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return Result.error('Giriş yapmalısınız');
      if (userId == followingId) return Result.error('Kendinizi takip edemezsiniz');

      await _db.collection(AppConstants.collectionFollows).add({
        'followerId': userId,
        'followingId': followingId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Kullanıcı bilgisi
      final user = await _userRepo.getUser(userId);
      if (user.isSuccess) {
        await _notificationRepo.notifyFollow(
          recipientId: followingId,
          followerName: user.data!.name,
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.error('Takip edilemedi: ${e.toString()}');
    }
  }

  // Takipten çık
  Future<Result<void>> unfollowUser(String followingId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return Result.error('Giriş yapmalısınız');

      final docs = await _db
          .collection(AppConstants.collectionFollows)
          .where('followerId', isEqualTo: userId)
          .where('followingId', isEqualTo: followingId)
          .get();

      for (var doc in docs.docs) {
        await doc.reference.delete();
      }

      return Result.success(null);
    } catch (e) {
      return Result.error('Takip çıkılamadı: ${e.toString()}');
    }
  }

  // Takip ediyor mu?
  Future<bool> isFollowing(String userId, String followingId) async {
    final docs = await _db
        .collection(AppConstants.collectionFollows)
        .where('followerId', isEqualTo: userId)
        .where('followingId', isEqualTo: followingId)
        .limit(1)
        .get();
    return docs.docs.isNotEmpty;
  }

  // Takip listesi
  Stream<List<String>> getFollowing(String userId) {
    return _db
        .collection(AppConstants.collectionFollows)
        .where('followerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['followingId'] as String)
            .toList());
  }

  // Takipçi listesi
  Stream<List<String>> getFollowers(String userId) {
    return _db
        .collection(AppConstants.collectionFollows)
        .where('followingId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['followerId'] as String)
            .toList());
  }
}
