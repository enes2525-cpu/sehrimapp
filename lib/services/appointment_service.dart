import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sehrimapp/data/models/appointment_model.dart';

class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();
  factory AppointmentService() => _instance;
  AppointmentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Randevu oluştur
  Future<void> createAppointment({
    required String adId,
    required String adTitle,
    required String sellerId,
    required DateTime dateTime,
    required String location,
    String notes = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Giriş yapmalısınız';

    await _firestore.collection('appointments').add({
      'adId': adId,
      'adTitle': adTitle,
      'buyerId': user.uid,
      'sellerId': sellerId,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'notes': notes,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Kullanıcının randevularını getir
  Stream<List<Appointment>> getUserAppointments() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('appointments')
        .where('buyerId', isEqualTo: user.uid)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .asyncMap((buyerSnapshot) async {
      // Satıcı olarak randevuları da getir
      final sellerSnapshot = await _firestore
          .collection('appointments')
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('dateTime', descending: false)
          .get();

      final allDocs = [...buyerSnapshot.docs, ...sellerSnapshot.docs];
      return allDocs.map((doc) => Appointment.fromFirestore(doc)).toList();
    });
  }

  // Randevu durumunu güncelle
  Future<void> updateAppointmentStatus(String appointmentId, String status) async {
    await _firestore.collection('appointments').doc(appointmentId).update({
      'status': status,
    });
  }

  // Randevu sil
  Future<void> deleteAppointment(String appointmentId) async {
    await _firestore.collection('appointments').doc(appointmentId).delete();
  }
}