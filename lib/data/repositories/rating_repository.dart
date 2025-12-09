import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';

/// Puanlama ve yorum sistemi Repository
class RatingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Puanlama oluştur
  Future<Result<String>> createRating({
    required String targetId, // User veya Business ID
    required String targetType, // 'user' veya 'business'
    required double rating,
    String? comment,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) return Result.error('Giriş yapmalısınız');

      if (rating < 1 || rating > 5) {
        return Result.error('Puan 1-5 arasında olmalı');
      }

      final ratingData = {
        'userId': userId,
        'targetId': targetId,
        'targetType': targetType,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final doc = await _db.collection(AppConstants.collectionRatings).add(ratingData);

      // Ortalama puanı güncelle
      await _updateAverageRating(targetId, targetType);

      return Result.success(doc.id);
    } catch (e) {
      return Result.error('Puanlama eklenemedi: ${e.toString()}');
    }
  }

  // Ortalama puanı güncelle (private)
  Future<void> _updateAverageRating(String targetId, String targetType) async {
    final ratings = await _db
        .collection(AppConstants.collectionRatings)
        .where('targetId', isEqualTo: targetId)
        .where('targetType', isEqualTo: targetType)
        .get();

    if (ratings.docs.isEmpty) return;

    double total = 0;
    for (var doc in ratings.docs) {
      total += (doc.data()['rating'] ?? 0.0) as double;
    }

    final average = total / ratings.docs.length;

    // Hedef collection'ı güncelle
    final collection = targetType == 'business'
        ? AppConstants.collectionShops
        : AppConstants.collectionUsers;

    await _db.collection(collection).doc(targetId).update({
      'rating': average,
      'totalRatings': ratings.docs.length,
    });
  }

  // Puanlamaları getir
  Stream<List<Map<String, dynamic>>> getRatings(String targetId) {
    return _db
        .collection(AppConstants.collectionRatings)
        .where('targetId', isEqualTo: targetId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }
}
