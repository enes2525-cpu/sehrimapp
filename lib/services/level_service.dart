import 'package:cloud_firestore/cloud_firestore.dart';

class LevelService {
  static final _db = FirebaseFirestore.instance;

  /// Kullanıcıya XP ekler, level atlatır, rank günceller.
  /// Ayrıca popülerlik skoruna katkı verebilir.
  static Future<void> addXp(String userId, int amount) async {
    final ref = _db.collection('users').doc(userId);

    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;

      int oldXp = data['xp'] ?? 0;
      int oldLevel = data['level'] ?? 1;
      int oldProfileCompletion = data['profileCompletion'] ?? 40;

      int newXp = oldXp + amount;

      // Yeni Level
      int newLevel = _calculateLevel(newXp);

      // Yeni Rank
      String newRank = _calculateRank(newLevel);

      // Profil Tamamlanma yüzdesine ufak katkı
      int newCompletion = oldProfileCompletion + 1;
      if (newCompletion > 100) newCompletion = 100;

      tx.update(ref, {
        'xp': newXp,
        'level': newLevel,
        'rank': newRank,
        'profileCompletion': newCompletion,
        'lastActive': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Popülerlik skorunu artırır (profil görüntülenme, ilan görüntülenme vb.)
  static Future<void> updatePopularity(String userId, {int add = 1}) async {
    await _db.collection('users').doc(userId).update({
      'popularityScore': FieldValue.increment(add),
    });
  }

  /// Level hesaplama:
  /// Level 1 → 0 XP
  /// Level 2 → 100 XP
  /// Level 3 → 250 XP
  /// Level 4 → 450 XP
  /// Level 5 → 700 XP
  static int _calculateLevel(int xp) {
    int level = 1;
    int required = 100;

    while (xp >= required && level < 100) {
      level++;
      required += (level * 50);
    }

    return level;
  }

  /// Bronz – Gümüş – Altın – Platin – Elmas
  static String _calculateRank(int level) {
    if (level >= 50) return "Elmas";
    if (level >= 35) return "Platin";
    if (level >= 20) return "Altın";
    if (level >= 10) return "Gümüş";
    return "Bronz";
  }

  /// Günlük görev reset kontrolü
  static Future<void> resetDailyTasksIfNeeded(String userId) async {
    final ref = _db.collection('users').doc(userId);
    final doc = await ref.get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final lastReset = (data['lastDailyReset'] as Timestamp?)?.toDate();
    final now = DateTime.now();

    if (lastReset == null ||
        lastReset.year != now.year ||
        lastReset.month != now.month ||
        lastReset.day != now.day) {
      await ref.update({
        'dailyTaskProgress': 0,
        'lastDailyReset': Timestamp.fromDate(now),
      });
    }
  }
}
