import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/report_model.dart';

class ReportService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Rapor gönder
  static Future<void> submitReport({
    required String reporterId,
    required String reportedId,
    required String reportType, // 'user' veya 'ad'
    required String category,
    required String description,
  }) async {
    final report = ReportModel(
      id: '',
      reporterId: reporterId,
      reportedId: reportedId,
      reportType: reportType,
      category: category,
      description: description,
      createdAt: DateTime.now(),
    );

    await _db.collection('reports').add(report.toMap());
  }

  // Kullanıcının raporlarını getir
  static Future<List<ReportModel>> getUserReports(String userId) async {
    final snapshot = await _db
        .collection('reports')
        .where('reporterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => ReportModel.fromFirestore(doc)).toList();
  }

  // Bir kullanıcı/ilan için rapor sayısı
  static Future<int> getReportCount(String reportedId) async {
    final snapshot = await _db
        .collection('reports')
        .where('reportedId', isEqualTo: reportedId)
        .get();

    return snapshot.docs.length;
  }
}
