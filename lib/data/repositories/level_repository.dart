import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/constants/app_constants.dart';
import '../models/user_level.dart';

/// Level ve XP yönetimi için Repository
class LevelRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========== XP İŞLEMLERİ ==========

  /// Kullanıcıya XP ekle
  Future<Result<UserLevel>> addXP(
    String userId,
    int xpAmount, {
    String? reason,
  }) async {
    try {
      final userRef = _db.collection(AppConstants.collectionUsers).doc(userId);
      
      // Mevcut level bilgisini al
      final doc = await userRef.get();
      if (!doc.exists) {
        return Result.error('Kullanıcı bulunamadı');
      }

      final data = doc.data()!;
      final currentLevel = UserLevel.fromMap(data['level'] ?? {});
      
      // XP ekle ve level kontrolü yap
      final newLevel = currentLevel.addXP(xpAmount);
      
      // Firestore'u güncelle
      await userRef.update({
        'level': newLevel.toMap(),
        'lastXPGain': {
          'amount': xpAmount,
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
        },
      });

      // Level atladıysa bildirim gönder
      if (newLevel.level > currentLevel.level) {
        await _sendLevelUpNotification(userId, newLevel.level);
      }

      // XP logunu kaydet
      await _logXPActivity(userId, xpAmount, reason ?? 'Unknown');

      return Result.success(newLevel);
    } catch (e) {
      return Result.error('XP eklenirken hata: ${e.toString()}');
    }
  }

  /// Kullanıcının mevcut level bilgisini getir
  Future<Result<UserLevel>> getUserLevel(String userId) async {
    try {
      final doc = await _db
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return Result.error('Kullanıcı bulunamadı');
      }

      final data = doc.data()!;
      final level = UserLevel.fromMap(data['level'] ?? {});

      return Result.success(level);
    } catch (e) {
      return Result.error('Level bilgisi alınamadı: ${e.toString()}');
    }
  }

  /// Level stream
  Stream<UserLevel> watchUserLevel(String userId) {
    return _db
        .collection(AppConstants.collectionUsers)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return UserLevel(
          level: 1,
          currentXP: 0,
          requiredXP: UserLevel.getRequiredXP(1),
          levelTitle: UserLevel.getLevelTitle(1),
          unlockedFeatures: UserLevel.getUnlockedFeatures(1),
          dailyAdLimit: UserLevel.getDailyAdLimit(1),
          lastUpdated: DateTime.now(),
        );
      }

      final data = doc.data()!;
      return UserLevel.fromMap(data['level'] ?? {});
    });
  }

  // ========== AKTİVİTE TAKİBİ ==========

  /// İlan oluştur (+5 XP)
  Future<void> onAdCreated(String userId) async {
    await addXP(userId, XPActivity.createAd, reason: 'İlan oluşturdu');
  }

  /// Profil tamamla (+10 XP)
  Future<void> onProfileCompleted(String userId) async {
    await addXP(userId, XPActivity.completeProfile, reason: 'Profil tamamlandı');
  }

  /// İlk satış (+20 XP)
  Future<void> onFirstSale(String userId) async {
    await addXP(userId, XPActivity.firstSale, reason: 'İlk satış');
  }

  /// Reklam izle (+2 XP)
  Future<void> onAdWatched(String userId) async {
    await addXP(userId, XPActivity.watchAd, reason: 'Reklam izledi');
  }

  /// Günlük görev tamamla (+10 XP)
  Future<void> onDailyQuestCompleted(String userId) async {
    await addXP(userId, XPActivity.dailyQuest, reason: 'Günlük görev tamamlandı');
  }

  /// ŞA Kodu kullan (+5 XP)
  Future<void> onSACodeUsed(String userId) async {
    await addXP(userId, XPActivity.useSACode, reason: 'ŞA Kodu kullandı');
  }

  /// Puan al (+3 XP)
  Future<void> onRatingReceived(String userId) async {
    await addXP(userId, XPActivity.receiveRating, reason: 'Puan aldı');
  }

  /// 10 takipçiye ulaş (+20 XP)
  Future<void> on10Followers(String userId) async {
    await addXP(userId, XPActivity.get10Followers, reason: '10 takipçiye ulaştı');
  }

  // ========== ÖZEL METODLAR ==========

  /// Level atlama bildirimi gönder
  Future<void> _sendLevelUpNotification(String userId, int newLevel) async {
    try {
      await _db.collection(AppConstants.collectionNotifications).add({
        'userId': userId,
        'type': 'level_up',
        'title': '🎉 Level Atladın!',
        'message': 'Tebrikler! ${UserLevel.getLevelTitle(newLevel)} oldun!',
        'data': {
          'level': newLevel,
          'features': UserLevel.getUnlockedFeatures(newLevel),
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Bildirim gönderilirken hata: $e');
    }
  }

  /// XP aktivitesini logla
  Future<void> _logXPActivity(String userId, int amount, String reason) async {
    try {
      await _db.collection('xp_logs').add({
        'userId': userId,
        'amount': amount,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('XP logu kaydedilirken hata: $e');
    }
  }

  // ========== İSTATİSTİKLER ==========

  /// Toplam XP kazancı
  Future<Result<int>> getTotalXPEarned(String userId) async {
    try {
      final snapshot = await _db
          .collection('xp_logs')
          .where('userId', isEqualTo: userId)
          .get();

      final total = snapshot.docs.fold<int>(
        0,
        (sum, doc) => sum + (doc.data()['amount'] as int? ?? 0),
      );

      return Result.success(total);
    } catch (e) {
      return Result.error('XP istatistiği alınamadı: ${e.toString()}');
    }
  }

  /// XP kazanç geçmişi (son 30 gün)
  Future<Result<Map<String, int>>> getXPHistory(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final snapshot = await _db
          .collection('xp_logs')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('timestamp', descending: true)
          .get();

      final history = <String, int>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final reason = data['reason'] as String? ?? 'Unknown';
        final amount = data['amount'] as int? ?? 0;
        history[reason] = (history[reason] ?? 0) + amount;
      }

      return Result.success(history);
    } catch (e) {
      return Result.error('XP geçmişi alınamadı: ${e.toString()}');
    }
  }
}
