import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehrimapp/data/models/ad_model.dart';
import '../data/models/user_model.dart';
import '../data/models/business_model.dart';
import '../data/repositories/user_repository.dart';
import 'level_service.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================================
  // USER – KULLANICI İŞLEMLERİ
  // ============================================================

  static Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap());
  }

  static Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  static Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).update(data);
  }

  static Future<void> updateUserTokens(String userId, int amount) async {
    await _db.collection('users').doc(userId).update({
      'tokenBalance': FieldValue.increment(amount),
    });
  }

  static Future<void> addBadgeToUser(String userId, String badge) async {
    await _db.collection('users').doc(userId).update({
      'badges': FieldValue.arrayUnion([badge]),
    });
  }

  // ============================================================
  // PROFIL – GÖRÜNTÜLENME / XP / POPÜLERLİK
  // ============================================================

  static Future<void> increaseProfileViews(String userId) async {
    await _db.collection('users').doc(userId).update({
      'profileViews': FieldValue.increment(1),
    });

    // XP
    await LevelService.addXp(userId, 3);

    // POPÜLERLİK
    await LevelService.updatePopularity(userId);

    // USER REPO EK İSTATİSTİK
    await UserRepository().increaseProfileView(userId);
  }

  static Future<void> increaseUserTotalAdViews(String userId) async {
    await UserRepository().increaseTotalAdViews(userId);
  }

  // ============================================================
  // AD – İLAN İŞLEMLERİ
  // ============================================================

  static Future<String> createAd(AdModel ad) async {
    final ref = await _db.collection('ads').add(ad.toMap());

    await _db.collection('users').doc(ad.userId).update({
      'totalAds': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  static Future<AdModel?> getAd(String adId) async {
    final doc = await _db.collection('ads').doc(adId).get();
    if (!doc.exists) return null;
    return AdModel.fromFirestore(doc);
  }

  static Future<void> updateAd(String adId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('ads').doc(adId).update(data);
  }

  static Future<void> deleteAd(String adId, String userId) async {
    await _db.collection('ads').doc(adId).update({
      'status': 'deleted',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(userId).update({
      'totalAds': FieldValue.increment(-1),
    });
  }

  // ============================================================
  // İLAN GÖRÜNTÜLEME (XP + POPÜLERLİK + sayaç) — FINAL
  // ============================================================

  static Future<void> incrementAdViews(String adId, String ownerId) async {
    // ilan sayacı
    await _db.collection('ads').doc(adId).update({
      'viewCount': FieldValue.increment(1),
    });

    // Kullanıcı toplam ilan görünümü
    await UserRepository().increaseTotalAdViews(ownerId);

    // XP ver
    await LevelService.addXp(ownerId, 2);

    // Popülerlik ver
    await LevelService.updatePopularity(ownerId);
  }

  // ============================================================
  // LİSTELEMELER
  // ============================================================

  static Stream<List<AdModel>> getActiveAds({int limit = 20}) {
    return _db
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => AdModel.fromQuery(d)).toList());
  }

  static Stream<List<AdModel>> getAdsByCategory(String category, {int limit = 20}) {
    return _db
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => AdModel.fromQuery(d)).toList());
  }

  static Stream<List<AdModel>> getAdsByCity(String city, {int limit = 20}) {
    return _db
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .where('city', isEqualTo: city)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => AdModel.fromQuery(d)).toList());
  }

  static Stream<List<AdModel>> getUserAds(String userId) {
    return _db
        .collection('ads')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => AdModel.fromQuery(d)).toList());
  }

  static Future<List<AdModel>> searchAds(String query, {String? city}) async {
    Query q = _db.collection('ads').where('status', isEqualTo: 'active');

    if (city != null && city.isNotEmpty) q = q.where('city', isEqualTo: city);

    final snap = await q.get();
    final qLower = query.toLowerCase();

    return snap.docs
        .map((d) => AdModel.fromQuery(d))
        .where((ad) =>
            ad.title.toLowerCase().contains(qLower) ||
            ad.description.toLowerCase().contains(qLower))
        .toList();
  }

  // ============================================================
  // BUSINESS (DÜKKAN)
  // ============================================================

  static Future<String> createBusiness(BusinessModel business) async {
    final ref = await _db.collection('businesses').add(business.toMap());

    await _db.collection('users').doc(business.ownerId).update({
      'isBusinessAccount': true,
    });

    return ref.id;
  }

  static Future<BusinessModel?> getBusiness(String businessId) async {
    final doc = await _db.collection('businesses').doc(businessId).get();
    if (!doc.exists) return null;
    return BusinessModel.fromFirestore(doc);
  }

  static Future<BusinessModel?> getBusinessByOwner(String ownerId) async {
    final snap = await _db
        .collection('businesses')
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return BusinessModel.fromFirestore(snap.docs.first);
  }

  static Future<void> updateBusiness(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('businesses').doc(id).update(data);
  }

  static Future<void> incrementBusinessViews(String id) async {
    await _db.collection('businesses').doc(id).update({
      'totalViews': FieldValue.increment(1),
    });
  }

  // ============================================================
  // FAVORİLER
  // ============================================================

  static Future<void> addToFavorites(String userId, String adId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(adId)
        .set({
      'adId': adId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeFromFavorites(String userId, String adId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(adId)
        .delete();
  }

  static Stream<List<AdModel>> getFavoriteAds(String userId) async* {
    final stream = _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
        .snapshots();

    await for (var snap in stream) {
      final ids = snap.docs.map((d) => d.id).toList();
      if (ids.isEmpty) {
        yield [];
        continue;
      }

      final ads = <AdModel>[];
      for (var id in ids) {
        final ad = await getAd(id);
        if (ad != null && ad.isActive) ads.add(ad);
      }

      yield ads;
    }
  }

  static Future<bool> isAdFavorite(String userId, String adId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(adId)
        .get();

    return doc.exists;
  }
}
