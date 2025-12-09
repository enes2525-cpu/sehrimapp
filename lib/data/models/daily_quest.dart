import 'package:cloud_firestore/cloud_firestore.dart';

/// Günlük Görev Tipi
enum QuestType {
  visitShops,      // Dükkan ziyaret et
  likePost,        // Paylaşım beğen
  watchAd,         // Reklam izle
  createAd,        // İlan oluştur
  sendMessage,     // Mesaj gönder
  sharePost,       // Paylaşım yap
  useSACode,       // ŞA Kodu kullan
  openShowcase,    // Vitrin aç
}

/// Tek bir görev
class DailyQuest {
  final String id;
  final QuestType type;
  final String title;
  final String description;
  final int targetCount; // Hedef sayı (örn: 2 dükkan)
  final int currentProgress; // Mevcut ilerleme
  final int xpReward;
  final int tokenReward;
  final bool isCompleted;
  final DateTime? completedAt;

  DailyQuest({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.targetCount,
    this.currentProgress = 0,
    required this.xpReward,
    this.tokenReward = 0,
    this.isCompleted = false,
    this.completedAt,
  });

  // İlerleme yüzdesi
  double get progressPercentage {
    return (currentProgress / targetCount * 100).clamp(0.0, 100.0);
  }

  // Tamamlandı mı?
  bool get isComplete => currentProgress >= targetCount || isCompleted;

  // İlerleme ekle
  DailyQuest addProgress(int amount) {
    final newProgress = currentProgress + amount;
    final completed = newProgress >= targetCount;
    
    return DailyQuest(
      id: id,
      type: type,
      title: title,
      description: description,
      targetCount: targetCount,
      currentProgress: newProgress,
      xpReward: xpReward,
      tokenReward: tokenReward,
      isCompleted: completed,
      completedAt: completed ? DateTime.now() : completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'description': description,
      'targetCount': targetCount,
      'currentProgress': currentProgress,
      'xpReward': xpReward,
      'tokenReward': tokenReward,
      'isCompleted': isCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory DailyQuest.fromMap(String id, Map<String, dynamic> data) {
    return DailyQuest(
      id: id,
      type: QuestType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => QuestType.visitShops,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      targetCount: data['targetCount'] ?? 1,
      currentProgress: data['currentProgress'] ?? 0,
      xpReward: data['xpReward'] ?? 10,
      tokenReward: data['tokenReward'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Günlük Görev Seti (Bir kullanıcının günlük görevleri)
class DailyQuestSet {
  final String id;
  final String userId;
  final List<DailyQuest> quests;
  final DateTime date; // Hangi güne ait
  final bool allCompleted;
  final bool saCodeUnlocked; // ŞA Kodu açıldı mı?
  final DateTime createdAt;

  DailyQuestSet({
    required this.id,
    required this.userId,
    required this.quests,
    required this.date,
    required this.allCompleted,
    this.saCodeUnlocked = false,
    required this.createdAt,
  });

  // Tamamlanan görev sayısı
  int get completedCount => quests.where((q) => q.isComplete).length;

  // Toplam görev sayısı
  int get totalCount => quests.length;

  // İlerleme yüzdesi
  double get overallProgress => (completedCount / totalCount * 100);

  // Toplam XP ödülü
  int get totalXPReward => quests
      .where((q) => q.isComplete)
      .fold(0, (sum, q) => sum + q.xpReward);

  // Toplam Token ödülü
  int get totalTokenReward => quests
      .where((q) => q.isComplete)
      .fold(0, (sum, q) => sum + q.tokenReward);

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'quests': quests.map((q) => q.toMap()).toList(),
      'date': Timestamp.fromDate(date),
      'allCompleted': allCompleted,
      'saCodeUnlocked': saCodeUnlocked,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory DailyQuestSet.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final questsData = data['quests'] as List<dynamic>? ?? [];
    
    return DailyQuestSet(
      id: doc.id,
      userId: data['userId'] ?? '',
      quests: questsData
          .asMap()
          .entries
          .map((e) => DailyQuest.fromMap(
                '${doc.id}_quest_${e.key}',
                e.value as Map<String, dynamic>,
              ))
          .toList(),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      allCompleted: data['allCompleted'] ?? false,
      saCodeUnlocked: data['saCodeUnlocked'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Varsayılan günlük görevler oluştur
  static DailyQuestSet createDefault(String userId) {
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    
    return DailyQuestSet(
      id: '',
      userId: userId,
      quests: [
        DailyQuest(
          id: 'quest_1',
          type: QuestType.visitShops,
          title: 'Dükkan Ziyareti',
          description: '2 farklı dükkan profilini ziyaret et',
          targetCount: 2,
          xpReward: 10,
        ),
        DailyQuest(
          id: 'quest_2',
          type: QuestType.likePost,
          title: 'Topluluk Etkileşimi',
          description: '1 topluluk paylaşımını beğen',
          targetCount: 1,
          xpReward: 5,
        ),
        DailyQuest(
          id: 'quest_3',
          type: QuestType.watchAd,
          title: 'Reklam İzle',
          description: '1 reklam izleyerek destek ol',
          targetCount: 1,
          xpReward: 5,
          tokenReward: 2,
        ),
      ],
      date: dateOnly,
      allCompleted: false,
      createdAt: now,
    );
  }
}
