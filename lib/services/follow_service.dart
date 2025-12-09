import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class FollowService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Kullanıcı takip et
  static Future<void> followUser({
    required String followerId,
    required String followingId,
    required String followerName,
  }) async {
    if (followerId == followingId) return;

    // Follow kaydı oluştur
    await _db.collection('follows').add({
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Takipçi ve takip edilen sayılarını güncelle
    await _db.collection('users').doc(followerId).update({
      'followingCount': FieldValue.increment(1),
    });

    await _db.collection('users').doc(followingId).update({
      'followerCount': FieldValue.increment(1),
    });

    // Bildirim gönder
    await NotificationService.notifyFollow(
      followedUserId: followingId,
      followerName: followerName,
      followerId: followerId,
    );
  }

  // Takipten çık
  static Future<void> unfollowUser({
    required String followerId,
    required String followingId,
  }) async {
    final snapshot = await _db
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followingId', isEqualTo: followingId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }

    // Sayıları güncelle
    await _db.collection('users').doc(followerId).update({
      'followingCount': FieldValue.increment(-1),
    });

    await _db.collection('users').doc(followingId).update({
      'followerCount': FieldValue.increment(-1),
    });
  }

  // Takip ediyor mu kontrol
  static Future<bool> isFollowing({
    required String followerId,
    required String followingId,
  }) async {
    final snapshot = await _db
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followingId', isEqualTo: followingId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Takipçiler listesi (Stream)
  static Stream<List<Map<String, dynamic>>> getFollowers(String userId) {
    return _db
        .collection('follows')
        .where('followingId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> followers = [];

      for (var follow in snapshot.docs) {
        final followerId = follow.data()['followerId'];
        final userDoc = await _db.collection('users').doc(followerId).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          followers.add({
            'id': followerId,
            'name': userData['name'] ?? '',
            'photoUrl': userData['photoUrl'],
            'followedAt': (follow.data()['createdAt'] as Timestamp?)?.toDate(),
          });
        }
      }

      return followers;
    });
  }

  // Takip edilenler listesi (Stream)
  static Stream<List<Map<String, dynamic>>> getFollowing(String userId) {
    return _db
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> following = [];

      for (var follow in snapshot.docs) {
        final followingId = follow.data()['followingId'];
        final userDoc = await _db.collection('users').doc(followingId).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          following.add({
            'id': followingId,
            'name': userData['name'] ?? '',
            'photoUrl': userData['photoUrl'],
            'followedAt': (follow.data()['createdAt'] as Timestamp?)?.toDate(),
          });
        }
      }

      return following;
    });
  }

  // Takipçi sayısı
  static Future<int> getFollowerCount(String userId) async {
    final snapshot = await _db
        .collection('follows')
        .where('followingId', isEqualTo: userId)
        .get();

    return snapshot.docs.length;
  }

  // Takip edilen sayısı
  static Future<int> getFollowingCount(String userId) async {
    final snapshot = await _db
        .collection('follows')
        .where('followerId', isEqualTo: userId)
        .get();

    return snapshot.docs.length;
  }

  // Karşılıklı takip kontrolü (mutual follow)
  static Future<bool> isMutualFollow({
    required String user1Id,
    required String user2Id,
  }) async {
    final follow1 = await isFollowing(followerId: user1Id, followingId: user2Id);
    final follow2 = await isFollowing(followerId: user2Id, followingId: user1Id);

    return follow1 && follow2;
  }
}
