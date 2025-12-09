import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reporterId; // Rapor eden kullanıcı
  final String reportedId; // Raporlanan kullanıcı/ilan
  final String reportType; // 'user' veya 'ad'
  final String category; // spam, scam, inappropriate, etc.
  final String description;
  final String status; // pending, reviewed, resolved
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedId,
    required this.reportType,
    required this.category,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reportedId: data['reportedId'] ?? '',
      reportType: data['reportType'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedId': reportedId,
      'reportType': reportType,
      'category': category,
      'description': description,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
