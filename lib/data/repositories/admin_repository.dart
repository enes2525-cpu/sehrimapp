import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'package:sehrimapp/data/models/ad_model.dart';
import 'token_repository.dart';

/// Admin Repository - Moderasyon ve Yönetim
class AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TokenRepository _tokenRepo = TokenRepository();

  // ========== DASHBOARD İSTATİSTİKLERİ ==========

  /// Genel istatistikler
  Future<Result<Map<String, dynamic>>> getDashboardStats() async {
    try {
      // Kullanıcı sayısı
      final usersSnapshot = await _db.collection(AppConstants.collectionUsers).count().get();
      final totalUsers = usersSnapshot.count ?? 0;

      // İlan sayısı
      final adsSnapshot = await _db.collection(AppConstants.collectionAds).count().get();
      final totalAds = adsSnapshot.count ?? 0;

      // Aktif ilanlar
      final activeAdsSnapshot = await _db
          .collection(AppConstants.collectionAds)
          .where('status', isEqualTo: 'active')
          .count()
          .get();
      final activeAds = activeAdsSnapshot.count ?? 0;

      // Şikayetler
      final reportsSnapshot = await _db
          .collection(AppConstants.collectionReports)
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      final pendingReports = reportsSnapshot.count ?? 0;

      // İşletme sayısı
      final shopsSnapshot = await _db.collection(AppConstants.collectionShops).count().get();
      final totalShops = shopsSnapshot.count ?? 0;

      final stats = {
        'totalUsers': totalUsers,
        'totalAds': totalAds,
        'activeAds': activeAds,
        'pendingReports': pendingReports,
        'totalShops': totalShops,
        'timestamp': DateTime.now().toIso8601String(),
      };

      return Result.success(stats);
    } catch (e) {
      return Result.error('İstatistikler yüklenemedi: ${e.toString()}');
    }
  }

  // ========== KULLANICI YÖNETİMİ ==========

  /// Kullanıcı banla
  Future<Result<void>> banUser(String userId, String reason) async {
    try {
      await _db.collection(AppConstants.collectionUsers).doc(userId).update({
        'isBanned': true,
        'banReason': reason,
        'bannedAt': FieldValue.serverTimestamp(),
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Kullanıcı banlanamadı: ${e.toString()}');
    }
  }

  /// Kullanıcı ban'ı kaldır
  Future<Result<void>> unbanUser(String userId) async {
    try {
      await _db.collection(AppConstants.collectionUsers).doc(userId).update({
        'isBanned': false,
        'banReason': FieldValue.delete(),
        'bannedAt': FieldValue.delete(),
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Ban kaldırılamadı: ${e.toString()}');
    }
  }

  /// Tüm kullanıcıları getir (sayfalama ile)
  Stream<List<UserModel>> getAllUsers({int limit = 50}) {
    return _db
        .collection(AppConstants.collectionUsers)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // ========== İLAN YÖNETİMİ ==========

  /// İlan sil (Admin)
  Future<Result<void>> deleteAd(String adId, String reason) async {
    try {
      await _db.collection(AppConstants.collectionAds).doc(adId).update({
        'status': 'deleted_by_admin',
        'deletionReason': reason,
        'deletedAt': FieldValue.serverTimestamp(),
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('İlan silinemedi: ${e.toString()}');
    }
  }

  /// Bildirilen ilanları getir
  Stream<List<AdModel>> getReportedAds() {
    return _db
        .collection(AppConstants.collectionAds)
        .where('reportCount', isGreaterThan: 0)
        .orderBy('reportCount', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AdModel.fromFirestore(doc)).toList());
  }

  // ========== ŞİKAYET YÖNETİMİ ==========

  /// Bekleyen şikayetleri getir
  Stream<List<Map<String, dynamic>>> getPendingReports() {
    return _db
        .collection(AppConstants.collectionReports)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Şikayeti çöz
  Future<Result<void>> resolveReport(
    String reportId,
    String action, // 'approved', 'rejected'
    String? note,
  ) async {
    try {
      await _db.collection(AppConstants.collectionReports).doc(reportId).update({
        'status': 'resolved',
        'action': action,
        'adminNote': note,
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Şikayet çözülemedi: ${e.toString()}');
    }
  }

  // ========== TOKEN YÖNETİMİ ==========

  /// Token iade et
  Future<Result<void>> refundTokens(
    String userId,
    int amount,
    String reason,
  ) async {
    try {
      await _tokenRepo.addTokens(userId, amount, reason: 'Admin iadesi: $reason');

      return Result.success(null);
    } catch (e) {
      return Result.error('Token iade edilemedi: ${e.toString()}');
    }
  }

  /// Toplu token dağıt (promosyon)
  Future<Result<void>> distributeTokensToAll(
    int amount,
    String reason,
  ) async {
    try {
      final usersSnapshot = await _db.collection(AppConstants.collectionUsers).get();

      final batch = _db.batch();
      int count = 0;

      for (var doc in usersSnapshot.docs) {
        final userRef = _db.collection(AppConstants.collectionUsers).doc(doc.id);
        batch.update(userRef, {
          'tokenBalance': FieldValue.increment(amount),
        });

        count++;
        
        // Firestore batch limit: 500
        if (count >= 500) {
          await batch.commit();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }

      return Result.success(null);
    } catch (e) {
      return Result.error('Token dağıtılamadı: ${e.toString()}');
    }
  }

  // ========== AKTİVİTE LOGLARı ==========

  /// Son aktiviteleri getir
  Stream<List<Map<String, dynamic>>> getRecentActivities({int limit = 20}) {
    return _db
        .collection('admin_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  /// Admin aktivitesi kaydet
  Future<void> logAdminAction(
    String action,
    String targetType,
    String targetId,
    Map<String, dynamic>? details,
  ) async {
    try {
      await _db.collection('admin_logs').add({
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'details': details ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Log kaydedilemedi: $e');
    }
  }
}
