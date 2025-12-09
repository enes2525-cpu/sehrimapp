import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/constants/app_constants.dart';
import '../models/daily_quest.dart';
import 'level_repository.dart';
import 'token_repository.dart';

/// Günlük Görev Repository
class QuestRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LevelRepository _levelRepo = LevelRepository();
  final TokenRepository _tokenRepo = TokenRepository();

  // ========== GÖREV YÖNETİMİ ==========

  /// Kullanıcının bugünkü görevlerini getir (yoksa oluştur)
  Future<Result<DailyQuestSet>> getTodayQuests(String userId) async {
    try {
      final today = DateTime.now();
      final dateOnly = DateTime(today.year, today.month, today.day);
      
      final docId = '${userId}_${dateOnly.millisecondsSinceEpoch ~/ 86400000}';
      final doc = await _db
          .collection('daily_quests')
          .doc(docId)
          .get();

      if (doc.exists) {
        return Result.success(DailyQuestSet.fromFirestore(doc));
      }

      // Yoksa yeni görev seti oluştur
      final questSet = DailyQuestSet.createDefault(userId);
      await _db.collection('daily_quests').doc(docId).set(questSet.toMap());

      return Result.success(questSet);
    } catch (e) {
      return Result.error('Görevler yüklenemedi: ${e.toString()}');
    }
  }

  /// Görev stream
  Stream<DailyQuestSet> watchTodayQuests(String userId) {
    final today = DateTime.now();
    final dateOnly = DateTime(today.year, today.month, today.day);
    final docId = '${userId}_${dateOnly.millisecondsSinceEpoch ~/ 86400000}';

    return _db
        .collection('daily_quests')
        .doc(docId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return DailyQuestSet.createDefault(userId);
      }
      return DailyQuestSet.fromFirestore(doc);
    });
  }

  // ========== GÖREV İLERLEMESİ ==========

  /// Görev ilerlet
  Future<Result<DailyQuestSet>> updateQuestProgress(
    String userId,
    QuestType questType, {
    int amount = 1,
  }) async {
    try {
      final questResult = await getTodayQuests(userId);
      if (!questResult.isSuccess) {
        return Result.error(questResult.error!);
      }

      final questSet = questResult.data!;
      final today = DateTime.now();
      final dateOnly = DateTime(today.year, today.month, today.day);
      final docId = '${userId}_${dateOnly.millisecondsSinceEpoch ~/ 86400000}';

      // İlgili görevi bul
      final questIndex = questSet.quests.indexWhere((q) => q.type == questType);
      if (questIndex == -1) {
        return Result.error('Görev bulunamadı');
      }

      final quest = questSet.quests[questIndex];
      if (quest.isComplete) {
        return Result.success(questSet); // Zaten tamamlanmış
      }

      // İlerleme ekle
      final updatedQuest = quest.addProgress(amount);
      final updatedQuests = List<DailyQuest>.from(questSet.quests);
      updatedQuests[questIndex] = updatedQuest;

      // Görev tamamlandı mı kontrol et
      if (updatedQuest.isComplete && !quest.isComplete) {
        await _onQuestCompleted(userId, updatedQuest);
      }

      // Tüm görevler tamamlandı mı?
      final allCompleted = updatedQuests.every((q) => q.isComplete);

      final updatedQuestSet = DailyQuestSet(
        id: questSet.id,
        userId: userId,
        quests: updatedQuests,
        date: questSet.date,
        allCompleted: allCompleted,
        saCodeUnlocked: allCompleted ? true : questSet.saCodeUnlocked,
        createdAt: questSet.createdAt,
      );

      // Firestore'u güncelle
      await _db
          .collection('daily_quests')
          .doc(docId)
          .update(updatedQuestSet.toMap());

      // Tüm görevler tamamlandıysa ŞA Kodu aç
      if (allCompleted && !questSet.allCompleted) {
        await _unlockSACode(userId);
      }

      return Result.success(updatedQuestSet);
    } catch (e) {
      return Result.error('Görev güncellenemedi: ${e.toString()}');
    }
  }

  /// Dükkan ziyareti
  Future<void> onShopVisited(String userId) async {
    await updateQuestProgress(userId, QuestType.visitShops);
  }

  /// Paylaşım beğen
  Future<void> onPostLiked(String userId) async {
    await updateQuestProgress(userId, QuestType.likePost);
  }

  /// Reklam izle
  Future<void> onAdWatched(String userId) async {
    await updateQuestProgress(userId, QuestType.watchAd);
    await _levelRepo.onAdWatched(userId); // +2 XP
  }

  /// İlan oluştur
  Future<void> onAdCreated(String userId) async {
    await updateQuestProgress(userId, QuestType.createAd);
    await _levelRepo.onAdCreated(userId); // +5 XP
  }

  /// Mesaj gönder
  Future<void> onMessageSent(String userId) async {
    await updateQuestProgress(userId, QuestType.sendMessage);
  }

  /// Paylaşım yap
  Future<void> onPostShared(String userId) async {
    await updateQuestProgress(userId, QuestType.sharePost);
  }

  // ========== ÖZEL METODLAR ==========

  /// Görev tamamlandığında ödül ver
  Future<void> _onQuestCompleted(String userId, DailyQuest quest) async {
    try {
      // XP ödülü
      if (quest.xpReward > 0) {
        await _levelRepo.addXP(userId, quest.xpReward, reason: quest.title);
      }

      // Token ödülü
      if (quest.tokenReward > 0) {
        await _tokenRepo.addTokens(
          userId,
          quest.tokenReward,
          reason: quest.title,
        );
      }

      // Bildirim gönder
      await _db.collection(AppConstants.collectionNotifications).add({
        'userId': userId,
        'type': 'quest_completed',
        'title': '✅ Görev Tamamlandı!',
        'message': '${quest.title} tamamlandı! +${quest.xpReward} XP',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Görev ödülü verilirken hata: $e');
    }
  }

  /// ŞA Kodu aç (tüm görevler tamamlandığında)
  Future<void> _unlockSACode(String userId) async {
    try {
      // Bonus ödül ver
      await _levelRepo.addXP(userId, 15, reason: 'Tüm görevleri tamamladı');
      await _tokenRepo.addTokens(userId, 5, reason: 'Günlük görevler bonusu');

      // Bildirim gönder
      await _db.collection(AppConstants.collectionNotifications).add({
        'userId': userId,
        'type': 'sa_code_unlocked',
        'title': '🎉 ŞA Kodu Açıldı!',
        'message': 'Tüm görevleri tamamladın! %10 indirim kodlarına erişim kazandın!',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('ŞA Kodu açılırken hata: $e');
    }
  }

  // ========== İSTATİSTİKLER ==========

  /// Kullanıcının toplam tamamladığı görev sayısı
  Future<Result<int>> getTotalCompletedQuests(String userId) async {
    try {
      final snapshot = await _db
          .collection('daily_quests')
          .where('userId', isEqualTo: userId)
          .where('allCompleted', isEqualTo: true)
          .get();

      return Result.success(snapshot.docs.length);
    } catch (e) {
      return Result.error('İstatistik alınamadı: ${e.toString()}');
    }
  }

  /// Görev tamamlama oranı (son 7 gün)
  Future<Result<double>> getWeeklyCompletionRate(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final snapshot = await _db
          .collection('daily_quests')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThan: Timestamp.fromDate(sevenDaysAgo))
          .get();

      if (snapshot.docs.isEmpty) {
        return Result.success(0.0);
      }

      final completedCount = snapshot.docs
          .where((doc) => doc.data()['allCompleted'] == true)
          .length;

      final rate = (completedCount / snapshot.docs.length) * 100;
      return Result.success(rate);
    } catch (e) {
      return Result.error('Oran hesaplanamadı: ${e.toString()}');
    }
  }
}
