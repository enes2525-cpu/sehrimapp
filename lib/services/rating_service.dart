import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/rating_model.dart';

class RatingService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Puan ver
  static Future<void> addRating({
    required String userId,
    required String userName,
    required String targetId,
    required String targetType,
    required double rating,
    String? comment,
  }) async {
    // Daha önce puan vermiş mi kontrol et
    final existing = await _db
        .collection('ratings')
        .where('userId', isEqualTo: userId)
        .where('targetId', isEqualTo: targetId)
        .get();

    if (existing.docs.isNotEmpty) {
      // Güncelle
      await _db.collection('ratings').doc(existing.docs.first.id).update({
        'rating': rating,
        'comment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Yeni oluştur
      final ratingModel = RatingModel(
        id: '',
        userId: userId,
        userName: userName,
        targetId: targetId,
        targetType: targetType,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await _db.collection('ratings').add(ratingModel.toMap());
    }

    // Ortalama puanı güncelle
    await _updateAverageRating(targetId, targetType);
  }

  // Ortalama puanı hesapla ve güncelle
  static Future<void> _updateAverageRating(String targetId, String targetType) async {
    final ratings = await _db
        .collection('ratings')
        .where('targetId', isEqualTo: targetId)
        .get();

    if (ratings.docs.isEmpty) return;

    double totalRating = 0;
    for (var doc in ratings.docs) {
      totalRating += ((doc.data()['rating'] ?? 0.0) as num).toDouble();
    }

    final average = totalRating / ratings.docs.length;
    final collection = targetType == 'business' ? 'businesses' : 'users';

    await _db.collection(collection).doc(targetId).update({
      'rating': average,
      'reviewCount': ratings.docs.length,
    });
  }

  // Puanları getir
  static Stream<List<RatingModel>> getRatings(String targetId) {
    return _db
        .collection('ratings')
        .where('targetId', isEqualTo: targetId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => RatingModel.fromFirestore(doc)).toList());
  }

  // Kullanıcının verdiği puanı getir
  static Future<RatingModel?> getUserRating(String userId, String targetId) async {
    final snapshot = await _db
        .collection('ratings')
        .where('userId', isEqualTo: userId)
        .where('targetId', isEqualTo: targetId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return RatingModel.fromFirestore(snapshot.docs.first);
  }
}
