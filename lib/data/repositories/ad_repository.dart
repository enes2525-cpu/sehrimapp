import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/ad_model.dart';
import '../../data/repositories/user_repository.dart';

class AdRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserRepository _userRepository = UserRepository();

  Future<List<AdModel>> getUserAds(String userId) async {
    final snap = await _db
        .collection("ads")
        .where("userId", isEqualTo: userId)
        .where("status", isEqualTo: "active")
        .orderBy("createdAt", descending: true)
        .get();

    return snap.docs.map((d) => AdModel.fromQuery(d)).toList();
  }

  Future<AdModel?> getAd(String adId) async {
    final doc = await _db.collection("ads").doc(adId).get();
    if (!doc.exists) return null;
    return AdModel.fromFirestore(doc);
  }

  /// İlan görüntülenme artır — kullanıcı profiline de işler
  Future<void> increaseAdView(String adId) async {
    final ref = _db.collection("ads").doc(adId);
    final snap = await ref.get();
    if (!snap.exists) return;

    final userId = snap["userId"];

    // ilan için view artır
    await ref.update({
      "viewCount": FieldValue.increment(1),
      "updatedAt": FieldValue.serverTimestamp()
    });

    // kullanıcı toplam görüntülenmesini artır
    await _userRepository.increaseTotalAdViews(userId);
  }
}
