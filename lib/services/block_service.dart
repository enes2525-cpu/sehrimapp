import 'package:cloud_firestore/cloud_firestore.dart';

class BlockService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Kullanıcı engelle
  static Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    if (blockerId == blockedId) return;

    await _db.collection('blocks').add({
      'blockerId': blockerId,
      'blockedId': blockedId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Engeli kaldır
  static Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    final snapshot = await _db
        .collection('blocks')
        .where('blockerId', isEqualTo: blockerId)
        .where('blockedId', isEqualTo: blockedId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Kullanıcı engellenmiş mi?
  static Future<bool> isBlocked({
    required String blockerId,
    required String blockedId,
  }) async {
    final snapshot = await _db
        .collection('blocks')
        .where('blockerId', isEqualTo: blockerId)
        .where('blockedId', isEqualTo: blockedId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Karşılıklı engelleme kontrolü (A, B'yi veya B, A'yı engellemiş mi?)
  static Future<bool> isBlockedBidirectional({
    required String user1Id,
    required String user2Id,
  }) async {
    final snapshot = await _db
        .collection('blocks')
        .where('blockerId', whereIn: [user1Id, user2Id])
        .where('blockedId', whereIn: [user1Id, user2Id])
        .get();

    return snapshot.docs.isNotEmpty;
  }

  // Engellenen kullanıcılar listesi
  static Stream<List<Map<String, dynamic>>> getBlockedUsers(String userId) {
    return _db
        .collection('blocks')
        .where('blockerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> users = [];

      for (var block in snapshot.docs) {
        final blockedId = block.data()['blockedId'];
        final userDoc = await _db.collection('users').doc(blockedId).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          users.add({
            'id': blockedId,
            'name': userData['name'] ?? '',
            'photoUrl': userData['photoUrl'],
            'blockedAt': (block.data()['createdAt'] as Timestamp?)?.toDate(),
          });
        }
      }

      return users;
    });
  }

  // Beni engelleyenler listesi
  static Future<List<String>> getBlockerIds(String userId) async {
    final snapshot = await _db
        .collection('blocks')
        .where('blockedId', isEqualTo: userId)
        .get();

    return snapshot.docs.map((doc) => doc.data()['blockerId'] as String).toList();
  }

  // Engellenen kullanıcı sayısı
  static Future<int> getBlockedCount(String userId) async {
    final snapshot = await _db
        .collection('blocks')
        .where('blockerId', isEqualTo: userId)
        .get();

    return snapshot.docs.length;
  }
}
