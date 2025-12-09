import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Kullanıcı getir
  Future<UserRepositoryResult> getUser(String userId) async {
    try {
      final doc = await _db.collection("users").doc(userId).get();
      if (!doc.exists) {
        return UserRepositoryResult.error("Kullanıcı bulunamadı");
      }
      return UserRepositoryResult.success(doc.data()!..["id"] = userId);
    } catch (e) {
      return UserRepositoryResult.error(e.toString());
    }
  }

  /// Profil görüntülenmesini artır
  Future<void> increaseProfileView(String userId) async {
    await _db.collection("users").doc(userId).update({
      "profileViews": FieldValue.increment(1),
      "lastActive": FieldValue.serverTimestamp()
    });
  }

  /// Kullanıcının ilan görüntülenme toplamını artır
  Future<void> increaseTotalAdViews(String userId) async {
    await _db.collection("users").doc(userId).update({
      "totalAdViews": FieldValue.increment(1),
      "lastActive": FieldValue.serverTimestamp()
    });
  }

  /// Günlük görev sıfırlama kontrolü
  Future<void> resetDailyTasksIfNeeded(String userId) async {
    final ref = _db.collection("users").doc(userId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final lastReset = (data["lastDailyReset"] as Timestamp?)?.toDate();
    final now = DateTime.now();

    if (lastReset == null ||
        now.day != lastReset.day ||
        now.month != lastReset.month ||
        now.year != lastReset.year) {
      await ref.update({
        "dailyTaskProgress": 0,
        "lastDailyReset": now,
      });
    }
  }
}

/// Result wrapper
class UserRepositoryResult {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? error;

  UserRepositoryResult.success(this.data)
      : isSuccess = true,
        error = null;

  UserRepositoryResult.error(this.error)
      : isSuccess = false,
        data = null;
}
