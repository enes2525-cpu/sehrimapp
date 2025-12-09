import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';

/// Engelleme sistemi Repository (Güvenlik)
class BlockRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Kullanıcıyı engelle
  Future<Result<void>> blockUser(String blockedUserId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return Result.error('Giriş yapmalısınız');
      if (userId == blockedUserId) return Result.error('Kendinizi engelleyemezsiniz');

      await _db.collection(AppConstants.collectionBlocks).add({
        'blockerId': userId,
        'blockedUserId': blockedUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Engellenemedi: ${e.toString()}');
    }
  }

  // Engeli kaldır
  Future<Result<void>> unblockUser(String blockedUserId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return Result.error('Giriş yapmalısınız');

      final docs = await _db
          .collection(AppConstants.collectionBlocks)
          .where('blockerId', isEqualTo: userId)
          .where('blockedUserId', isEqualTo: blockedUserId)
          .get();

      for (var doc in docs.docs) {
        await doc.reference.delete();
      }

      return Result.success(null);
    } catch (e) {
      return Result.error('Engel kaldırılamadı: ${e.toString()}');
    }
  }

  // Engellenmiş mi?
  Future<bool> isBlocked(String userId, String blockedUserId) async {
    final docs = await _db
        .collection(AppConstants.collectionBlocks)
        .where('blockerId', isEqualTo: userId)
        .where('blockedUserId', isEqualTo: blockedUserId)
        .limit(1)
        .get();
    return docs.docs.isNotEmpty;
  }

  // Engellenmiş kullanıcılar
  Stream<List<String>> getBlockedUsers(String userId) {
    return _db
        .collection(AppConstants.collectionBlocks)
        .where('blockerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data()['blockedUserId'] as String)
            .toList());
  }
}
