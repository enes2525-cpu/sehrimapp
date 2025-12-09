import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehrimapp/data/models/ad_model.dart';
import '../data/models/view_history_model.dart';

class AnalyticsService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========== GÖRÜNTÜLENME GEÇMİŞİ ==========

  // İlan görüntüleme kaydet
  static Future<void> recordAdView({
    required String userId,
    required String adId,
    required String adTitle,
    String? adImage,
    required double adPrice,
  }) async {
    // Önce aynı ilan görüntüleme var mı kontrol et
    final existing = await _db
        .collection('view_history')
        .where('userId', isEqualTo: userId)
        .where('adId', isEqualTo: adId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Var olan kaydı güncelle (tarih)
      await existing.docs.first.reference.update({
        'viewedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Yeni kayıt oluştur
      final viewHistory = ViewHistoryModel(
        id: '',
        userId: userId,
        adId: adId,
        adTitle: adTitle,
        adImage: adImage,
        adPrice: adPrice,
        viewedAt: DateTime.now(),
      );

      await _db.collection('view_history').add(viewHistory.toMap());
    }

    // İlanın viewCount'unu artır
    await _db.collection('ads').doc(adId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  // Kullanıcının son görüntüledikleri
  static Stream<List<ViewHistoryModel>> getViewHistory(String userId, {int limit = 20}) {
    return _db
        .collection('view_history')
        .where('userId', isEqualTo: userId)
        .orderBy('viewedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ViewHistoryModel.fromFirestore(doc))
            .toList());
  }

  // Görüntülenme geçmişini temizle
  static Future<void> clearViewHistory(String userId) async {
    final snapshot = await _db
        .collection('view_history')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Tek bir görüntülemeyi sil
  static Future<void> deleteViewHistory(String viewHistoryId) async {
    await _db.collection('view_history').doc(viewHistoryId).delete();
  }

// ========== PROFİL GÖRÜNTÜLEME ==========

static Future<void> recordProfileView({
  required String viewerId,
  required String profileOwnerId,
}) async {
  if (viewerId == profileOwnerId) return; // Kendi profiline bakan sayılmasın

  // Aynı gün aynı kişi tekrar görüntülediyse sayma (spam engel)
  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);

  final snapshot = await _db
      .collection('profile_views')
      .where('viewerId', isEqualTo: viewerId)
      .where('profileOwnerId', isEqualTo: profileOwnerId)
      .where('viewedAt', isGreaterThan: startOfDay)
      .limit(1)
      .get();

  if (snapshot.docs.isEmpty) {
    await _db.collection('profile_views').add({
      'viewerId': viewerId,
      'profileOwnerId': profileOwnerId,
      'viewedAt': FieldValue.serverTimestamp(),
    });

    // Kullanıcı modelindeki profil görüntülenme sayısını artır
    await _db.collection('users').doc(profileOwnerId).update({
      'profileViews': FieldValue.increment(1),
    });
  }
}


  // ========== POPÜLER İLANLAR ==========

  // En çok görüntülenen ilanlar
  static Stream<List<AdModel>> getPopularAds({int limit = 10}) {
    return _db
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .orderBy('viewCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AdModel.fromQuery(doc)).toList());
  }

  // Kategoriye göre popüler ilanlar
  static Stream<List<AdModel>> getPopularAdsByCategory(
    String category, {
    int limit = 10,
  }) {
    return _db
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .where('category', isEqualTo: category)
        .orderBy('viewCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AdModel.fromQuery(doc)).toList());
  }

  // Şehre göre popüler ilanlar
  static Stream<List<AdModel>> getPopularAdsByCity(
    String city, {
    int limit = 10,
  }) {
    return _db
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .where('city', isEqualTo: city)
        .orderBy('viewCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AdModel.fromQuery(doc)).toList());
  }

  // Son eklenen ilanlar
  static Stream<List<AdModel>> getRecentAds({int limit = 10}) {
    return _db
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AdModel.fromQuery(doc)).toList());
  }

  // ========== İSTATİSTİKLER ==========

  // Kategori istatistikleri
  static Future<Map<String, int>> getCategoryStats() async {
    final snapshot = await _db
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .get();

    Map<String, int> stats = {};

    for (var doc in snapshot.docs) {
      final category = doc.data()['category'] as String?;
      if (category != null) {
        stats[category] = (stats[category] ?? 0) + 1;
      }
    }

    return stats;
  }

  // Şehir istatistikleri
  static Future<Map<String, int>> getCityStats() async {
    final snapshot = await _db
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .get();

    Map<String, int> stats = {};

    for (var doc in snapshot.docs) {
      final city = doc.data()['city'] as String?;
      if (city != null) {
        stats[city] = (stats[city] ?? 0) + 1;
      }
    }

    return stats;
  }

  // Toplam istatistikler
  static Future<Map<String, dynamic>> getOverallStats() async {
    final adsSnapshot = await _db.collection('ads').get();
    final usersSnapshot = await _db.collection('users').get();
    final activeAdsSnapshot = await _db
        .collection('ads')
        .where('status', isEqualTo: 'active')
        .get();

    return {
      'totalAds': adsSnapshot.docs.length,
      'activeAds': activeAdsSnapshot.docs.length,
      'totalUsers': usersSnapshot.docs.length,
    };
  }

  // Kullanıcının görüntülenme istatistikleri
  static Future<Map<String, dynamic>> getUserAdStats(String userId) async {
    final userAds = await _db
        .collection('ads')
        .where('userId', isEqualTo: userId)
        .get();

    int totalViews = 0;
    int totalAds = userAds.docs.length;

    for (var doc in userAds.docs) {
      totalViews += (doc.data()['viewCount'] as int? ?? 0);
    }

    return {
      'totalAds': totalAds,
      'totalViews': totalViews,
      'averageViews': totalAds > 0 ? (totalViews / totalAds).round() : 0,
    };
  }
}
