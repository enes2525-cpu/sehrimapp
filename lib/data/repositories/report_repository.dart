import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';

/// Şikayet sistemi Repository (Google Play zorunlu)
class ReportRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Şikayet oluştur
  Future<Result<String>> createReport({
    required String targetId,
    required String targetType, // 'user', 'ad', 'post', 'business'
    required String reason, // 'spam', 'inappropriate', 'fraud', 'harassment'
    String? description,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return Result.error('Giriş yapmalısınız');

      final reportData = {
        'reporterId': userId,
        'targetId': targetId,
        'targetType': targetType,
        'reason': reason,
        'description': description,
        'status': 'pending', // pending, reviewed, resolved
        'createdAt': FieldValue.serverTimestamp(),
      };

      final doc = await _db.collection(AppConstants.collectionReports).add(reportData);

      return Result.success(doc.id);
    } catch (e) {
      return Result.error('Şikayet gönderilemedi: ${e.toString()}');
    }
  }

  // Kullanıcının şikayetlerini getir
  Stream<List<Map<String, dynamic>>> getUserReports(String userId) {
    return _db
        .collection(AppConstants.collectionReports)
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  // Şikayet durumunu güncelle (Admin)
  Future<Result<void>> updateReportStatus(String reportId, String status) async {
    try {
      await _db.collection(AppConstants.collectionReports).doc(reportId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Durum güncellenemedi: ${e.toString()}');
    }
  }
}
