import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String adId;
  final String adTitle;
  final String buyerId;
  final String sellerId;
  final DateTime dateTime;
  final String location;
  final String notes;
  final String status; // pending, confirmed, cancelled, completed
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.adId,
    required this.adTitle,
    required this.buyerId,
    required this.sellerId,
    required this.dateTime,
    required this.location,
    this.notes = '',
    this.status = 'pending',
    required this.createdAt,
  });

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      adId: data['adId'] ?? '',
      adTitle: data['adTitle'] ?? '',
      buyerId: data['buyerId'] ?? '',
      sellerId: data['sellerId'] ?? '',
      dateTime: (data['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] ?? '',
      notes: data['notes'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adId': adId,
      'adTitle': adTitle,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'notes': notes,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}