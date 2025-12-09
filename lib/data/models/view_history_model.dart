import 'package:cloud_firestore/cloud_firestore.dart';

class ViewHistoryModel {
  final String id;
  final String userId;
  final String adId;
  final String adTitle;
  final String? adImage;
  final double adPrice;
  final DateTime viewedAt;

  ViewHistoryModel({
    required this.id,
    required this.userId,
    required this.adId,
    required this.adTitle,
    this.adImage,
    required this.adPrice,
    required this.viewedAt,
  });

  factory ViewHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ViewHistoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      adId: data['adId'] ?? '',
      adTitle: data['adTitle'] ?? '',
      adImage: data['adImage'],
      adPrice: (data['adPrice'] ?? 0).toDouble(),
      viewedAt: (data['viewedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'adId': adId,
      'adTitle': adTitle,
      'adImage': adImage,
      'adPrice': adPrice,
      'viewedAt': Timestamp.fromDate(viewedAt),
    };
  }
}
