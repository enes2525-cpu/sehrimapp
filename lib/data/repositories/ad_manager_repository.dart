import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../models/ad_tracking.dart';
import 'level_repository.dart';
import 'token_repository.dart';

/// Reklam Yönetim Repository
class AdManagerRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LevelRepository _levelRepo = LevelRepository();
  final TokenRepository _tokenRepo = TokenRepository();

  // ========== REKLAM GÖSTERME KONTROLÜ ==========

  /// Kullanıcı reklam görebilir mi? (günlük limit kontrolü)
  Future<Result<bool>> canShowAd(String userId, AdType adType) async {
    try {
      // Kullanıcının level bilgisini al
      final levelResult = await _levelRepo.getUserLevel(userId);
      if (!levelResult.isSuccess) {
        return Result.success(true); // Hata durumunda izin ver
      }

      final userLevel = levelResult.data!;
      
      // Level 6+: Reklamsız
      if (userLevel.level >= 6) {
        return Result.success(false);
      }

      // Bugünkü limiti kontrol et
      final limitResult = await _getTodayAdLimit(userId, userLevel.dailyAdLimit);
      if (!limitResult.isSuccess) {
        return Result.success(true);
      }

      final limit = limitResult.data!;
      
      return Result.success(!limit.isLimitReached);
    } catch (e) {
      return Result.error('Kontrol edilemedi: ${e.toString()}');
    }
  }

  /// Bugünkü reklam limitini getir
  Future<Result<DailyAdLimit>> _getTodayAdLimit(String userId, int maxLimit) async {
    try {
      final today = DateTime.now();
      final dateOnly = DateTime(today.year, today.month, today.day);
      final docId = '${userId}_${dateOnly.millisecondsSinceEpoch ~/ 86400000}';

      final doc = await _db.collection('ad_limits').doc(docId).get();

      if (doc.exists) {
        return Result.success(DailyAdLimit.fromFirestore(doc));
      }

      // Yoksa yeni oluştur
      final limit = DailyAdLimit.createNew(userId, maxLimit);
      await _db.collection('ad_limits').doc(docId).set(limit.toMap());

      return Result.success(limit);
    } catch (e) {
      return Result.error('Limit alınamadı: ${e.toString()}');
    }
  }

  // ========== REKLAM GÖRÜNTÜLENDİ ==========

  /// Reklam görüntülendi - kayıt tut
  Future<Result<void>> recordAdView({
    required String userId,
    required AdType adType,
    required String placement,
    bool wasRewarded = false,
    int rewardAmount = 0,
  }) async {
    try {
      // Görüntüleme kaydı oluştur
      final adView = AdView(
        id: '',
        userId: userId,
        adType: adType,
        placement: placement,
        viewedAt: DateTime.now(),
        wasRewarded: wasRewarded,
        rewardAmount: rewardAmount,
      );

      await _db.collection('ad_views').add(adView.toMap());

      // Günlük limiti güncelle
      await _updateDailyLimit(userId, adType);

      return Result.success(null);
    } catch (e) {
      return Result.error('Kayıt tutulamadı: ${e.toString()}');
    }
  }

  /// Günlük limiti güncelle
  Future<void> _updateDailyLimit(String userId, AdType adType) async {
    try {
      final levelResult = await _levelRepo.getUserLevel(userId);
      if (!levelResult.isSuccess) return;

      final userLevel = levelResult.data!;
      final limitResult = await _getTodayAdLimit(userId, userLevel.dailyAdLimit);
      if (!limitResult.isSuccess) return;

      final limit = limitResult.data!;
      final updatedLimit = limit.addView(adType);

      final today = DateTime.now();
      final dateOnly = DateTime(today.year, today.month, today.day);
      final docId = '${userId}_${dateOnly.millisecondsSinceEpoch ~/ 86400000}';

      await _db.collection('ad_limits').doc(docId).update(updatedLimit.toMap());
    } catch (e) {
      print('Limit güncellenemedi: $e');
    }
  }

  // ========== ÖDÜLLÜ REKLAM ==========

  /// Ödüllü reklam izlendi - ödül ver
  Future<Result<void>> grantRewardedAdReward(String userId) async {
    try {
      // Token ver
      await _tokenRepo.addTokens(
        userId,
        AdStrategy.rewardedTokenAmount,
        reason: 'Ödüllü reklam izledi',
      );

      // XP ver
      await _levelRepo.addXP(
        userId,
        AdStrategy.rewardedXPAmount,
        reason: 'Ödüllü reklam izledi',
      );

      // Kaydı tut
      await recordAdView(
        userId: userId,
        adType: AdType.rewarded,
        placement: AdPlacement.quest,
        wasRewarded: true,
        rewardAmount: AdStrategy.rewardedTokenAmount,
      );

      return Result.success(null);
    } catch (e) {
      return Result.error('Ödül verilemedi: ${e.toString()}');
    }
  }

  // ========== AÇILIŞ REKLAMI KONTROLÜ ==========

  /// Açılış reklamı gösterilmeli mi? (Her 3 açılışta 1)
  Future<Result<bool>> shouldShowInterstitial(String userId) async {
    try {
      final userRef = _db.collection('user_preferences').doc(userId);
      final doc = await userRef.get();

      int appOpenCount = 0;
      if (doc.exists) {
        appOpenCount = doc.data()?['appOpenCount'] ?? 0;
      }

      appOpenCount++;
      await userRef.set({'appOpenCount': appOpenCount}, SetOptions(merge: true));

      // Her 3 açılışta 1
      return Result.success(appOpenCount % AdStrategy.interstitialFrequency == 0);
    } catch (e) {
      return Result.error('Kontrol edilemedi: ${e.toString()}');
    }
  }

  // ========== İSTATİSTİKLER ==========

  /// Kullanıcının reklam istatistikleri
  Future<Result<Map<String, dynamic>>> getUserAdStats(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final snapshot = await _db
          .collection('ad_views')
          .where('userId', isEqualTo: userId)
          .where('viewedAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final totalViews = snapshot.docs.length;
      final rewardedViews = snapshot.docs
          .where((doc) => doc.data()['wasRewarded'] == true)
          .length;
      
      int totalTokensEarned = 0;
      for (var doc in snapshot.docs) {
        totalTokensEarned += doc.data()['rewardAmount'] as int? ?? 0;
      }

      final viewsByType = <String, int>{};
      for (var doc in snapshot.docs) {
        final type = doc.data()['adType'] as String? ?? 'unknown';
        viewsByType[type] = (viewsByType[type] ?? 0) + 1;
      }

      return Result.success({
        'totalViews': totalViews,
        'rewardedViews': rewardedViews,
        'totalTokensEarned': totalTokensEarned,
        'viewsByType': viewsByType,
        'last30Days': true,
      });
    } catch (e) {
      return Result.error('İstatistikler alınamadı: ${e.toString()}');
    }
  }

  /// Toplam reklam görüntülenmeleri (uygulama geneli)
  Future<Result<Map<String, dynamic>>> getGlobalAdStats() async {
    try {
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      
      final snapshot = await _db
          .collection('ad_views')
          .where('viewedAt', isGreaterThan: Timestamp.fromDate(todayStart))
          .get();

      return Result.success({
        'todayViews': snapshot.docs.length,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      return Result.error('İstatistikler alınamadı: ${e.toString()}');
    }
  }
}
