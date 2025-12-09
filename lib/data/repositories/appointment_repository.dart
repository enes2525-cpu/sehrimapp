import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';
import 'notification_repository.dart';
import 'token_repository.dart';
import 'user_repository.dart';

/// Appointment Model (Basitleştirilmiş)
class AppointmentModel {
  final String id;
  final String businessId;
  final String customerId;
  final String customerName;
  final DateTime appointmentDate;
  final String timeSlot; // "09:00-10:00"
  final String service;
  final double price;
  final String status; // pending, confirmed, cancelled, completed
  final String? notes;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.appointmentDate,
    required this.timeSlot,
    required this.service,
    required this.price,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppointmentModel(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      appointmentDate: (data['appointmentDate'] as Timestamp).toDate(),
      timeSlot: data['timeSlot'] ?? '',
      service: data['service'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      status: data['status'] ?? 'pending',
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'customerId': customerId,
      'customerName': customerName,
      'appointmentDate': Timestamp.fromDate(appointmentDate),
      'timeSlot': timeSlot,
      'service': service,
      'price': price,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Randevu sistemi Repository
/// Berber, Kuaför, Tamirci için kritik özellik!
class AppointmentRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationRepository _notificationRepo = NotificationRepository();
  final TokenRepository _tokenRepo = TokenRepository();
  final UserRepository _userRepo = UserRepository();

  // ========== RANDEVU OLUŞTURMA ==========

  /// Randevu talebi oluştur
  Future<Result<String>> createAppointment({
    required String businessId,
    required DateTime appointmentDate,
    required String timeSlot,
    required String service,
    required double price,
    String? notes,
    bool usePriorityToken = false, // Öncelikli randevu
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        return Result.error('Giriş yapmalısınız');
      }

      // Kullanıcı bilgisi
      final userResult = await _userRepo.getUser(userId);
      if (!userResult.isSuccess) {
        return Result.error('Kullanıcı bilgisi alınamadı');
      }

      // Öncelikli randevu için token kontrolü
      if (usePriorityToken) {
        final hasEnough = await _tokenRepo.hasEnoughTokens(userId, 10);
        if (!hasEnough) {
          return Result.error('Öncelikli randevu için 10 token gerekli');
        }
      }

      // Zaman dilimi müsait mi kontrol et
      final isAvailable = await _isTimeSlotAvailable(
        businessId,
        appointmentDate,
        timeSlot,
      );

      if (!isAvailable) {
        return Result.error('Bu zaman dilimi dolu. Lütfen başka bir saat seçin.');
      }

      // Randevu oluştur
      final appointmentData = AppointmentModel(
        id: '',
        businessId: businessId,
        customerId: userId,
        customerName: userResult.data!.name,
        appointmentDate: appointmentDate,
        timeSlot: timeSlot,
        service: service,
        price: price,
        status: usePriorityToken ? 'confirmed' : 'pending',
        notes: notes,
        createdAt: DateTime.now(),
      );

      final doc = await _db
          .collection(AppConstants.collectionAppointments)
          .add(appointmentData.toMap());

      // Öncelikli randevu için token düş
      if (usePriorityToken) {
        await _tokenRepo.deductTokens(
          userId,
          10,
          reason: 'Öncelikli randevu',
          metadata: {'appointmentId': doc.id},
        );
      }

      // İşletmeye bildirim gönder
      await _notificationRepo.notifyAppointment(
        recipientId: businessId,
        title: 'Yeni Randevu Talebi',
        body: '${userResult.data!.name} randevu talebi gönderdi',
        appointmentId: doc.id,
      );

      return Result.success(doc.id);
    } catch (e) {
      return Result.error('Randevu oluşturulurken hata: ${e.toString()}');
    }
  }

  /// Zaman dilimi müsait mi kontrol et (private)
  Future<bool> _isTimeSlotAvailable(
    String businessId,
    DateTime date,
    String timeSlot,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final appointments = await _db
          .collection(AppConstants.collectionAppointments)
          .where('businessId', isEqualTo: businessId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('timeSlot', isEqualTo: timeSlot)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      return appointments.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  // ========== RANDEVU YÖNETİMİ ==========

  /// Randevu durumunu güncelle (İşletme sahibi)
  Future<Result<void>> updateAppointmentStatus(
    String appointmentId,
    String status,
  ) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        return Result.error('Giriş yapmalısınız');
      }

      // Randevu kontrolü
      final appointmentDoc = await _db
          .collection(AppConstants.collectionAppointments)
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        return Result.error('Randevu bulunamadı');
      }

      final appointment = AppointmentModel.fromFirestore(appointmentDoc);

      // İşletme sahibi kontrolü
      if (appointment.businessId != userId) {
        return Result.error('Bu işlem için yetkiniz yok');
      }

      // Durum güncelle
      await _db
          .collection(AppConstants.collectionAppointments)
          .doc(appointmentId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Müşteriye bildirim gönder
      String notificationBody = '';
      if (status == 'confirmed') {
        notificationBody = 'Randevunuz onaylandı!';
      } else if (status == 'cancelled') {
        notificationBody = 'Randevunuz iptal edildi';
      } else if (status == 'completed') {
        notificationBody = 'Randevunuz tamamlandı. Teşekkürler!';
      }

      await _notificationRepo.notifyAppointment(
        recipientId: appointment.customerId,
        title: 'Randevu Durumu',
        body: notificationBody,
        appointmentId: appointmentId,
      );

      return Result.success(null);
    } catch (e) {
      return Result.error('Durum güncellenirken hata: ${e.toString()}');
    }
  }

  /// Randevuyu iptal et (Müşteri)
  Future<Result<void>> cancelAppointment(String appointmentId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        return Result.error('Giriş yapmalısınız');
      }

      // Randevu kontrolü
      final appointmentDoc = await _db
          .collection(AppConstants.collectionAppointments)
          .doc(appointmentId)
          .get();

      if (!appointmentDoc.exists) {
        return Result.error('Randevu bulunamadı');
      }

      final appointment = AppointmentModel.fromFirestore(appointmentDoc);

      // Müşteri kontrolü
      if (appointment.customerId != userId) {
        return Result.error('Bu işlem için yetkiniz yok');
      }

      // 24 saatten az kaldıysa iptal edilemez
      final now = DateTime.now();
      final timeDifference = appointment.appointmentDate.difference(now);

      if (timeDifference.inHours < 24) {
        return Result.error('Randevuya 24 saatten az kaldı. İptal edilemez.');
      }

      // İptal et
      await _db
          .collection(AppConstants.collectionAppointments)
          .doc(appointmentId)
          .update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // İşletmeye bildirim gönder
      await _notificationRepo.notifyAppointment(
        recipientId: appointment.businessId,
        title: 'Randevu İptali',
        body: '${appointment.customerName} randevuyu iptal etti',
        appointmentId: appointmentId,
      );

      return Result.success(null);
    } catch (e) {
      return Result.error('İptal edilirken hata: ${e.toString()}');
    }
  }

  // ========== RANDEVU LİSTELEME ==========

  /// Müşteri randevuları (Stream)
  Stream<List<AppointmentModel>> getCustomerAppointments(String customerId) {
    return _db
        .collection(AppConstants.collectionAppointments)
        .where('customerId', isEqualTo: customerId)
        .orderBy('appointmentDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList());
  }

  /// İşletme randevuları (Stream)
  Stream<List<AppointmentModel>> getBusinessAppointments(
    String businessId, {
    DateTime? date,
    String? status,
  }) {
    Query query = _db
        .collection(AppConstants.collectionAppointments)
        .where('businessId', isEqualTo: businessId);

    if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      query = query
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }

    return query
        .orderBy('appointmentDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppointmentModel.fromFirestore(doc))
            .toList());
  }

  /// Bekleyen randevular (İşletme için)
  Stream<List<AppointmentModel>> getPendingAppointments(String businessId) {
    return getBusinessAppointments(businessId, status: 'pending');
  }

  // ========== MUSAIT SAATLER ==========

  /// Belirli bir gün için müsait saatleri getir
  Future<Result<List<String>>> getAvailableTimeSlots(
    String businessId,
    DateTime date,
  ) async {
    try {
      // Çalışma saatleri (varsayılan: 09:00 - 18:00)
      final workingHours = [
        '09:00-10:00',
        '10:00-11:00',
        '11:00-12:00',
        '13:00-14:00',
        '14:00-15:00',
        '15:00-16:00',
        '16:00-17:00',
        '17:00-18:00',
      ];

      // O gün için rezerve edilmiş saatleri al
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final bookedAppointments = await _db
          .collection(AppConstants.collectionAppointments)
          .where('businessId', isEqualTo: businessId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      final bookedSlots = bookedAppointments.docs
          .map((doc) => doc.data()['timeSlot'] as String)
          .toSet();

      // Müsait saatleri filtrele
      final availableSlots = workingHours
          .where((slot) => !bookedSlots.contains(slot))
          .toList();

      return Result.success(availableSlots);
    } catch (e) {
      return Result.error('Saatler yüklenirken hata: ${e.toString()}');
    }
  }

  // ========== İSTATİSTİKLER ==========

  /// Randevu istatistikleri (İşletme için)
  Future<Result<Map<String, dynamic>>> getAppointmentStats(
    String businessId,
  ) async {
    try {
      final appointments = await _db
          .collection(AppConstants.collectionAppointments)
          .where('businessId', isEqualTo: businessId)
          .get();

      int pending = 0;
      int confirmed = 0;
      int completed = 0;
      int cancelled = 0;
      double totalRevenue = 0;

      for (var doc in appointments.docs) {
        final data = doc.data();
        final status = data['status'] as String;
        final price = (data['price'] ?? 0).toDouble();

        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'confirmed':
            confirmed++;
            break;
          case 'completed':
            completed++;
            totalRevenue += price;
            break;
          case 'cancelled':
            cancelled++;
            break;
        }
      }

      final stats = {
        'totalAppointments': appointments.docs.length,
        'pending': pending,
        'confirmed': confirmed,
        'completed': completed,
        'cancelled': cancelled,
        'totalRevenue': totalRevenue,
        'averageRevenue': completed > 0 ? totalRevenue / completed : 0,
      };

      return Result.success(stats);
    } catch (e) {
      return Result.error('İstatistikler hesaplanırken hata: ${e.toString()}');
    }
  }

  // ========== HATIRLATICI ==========

  /// Randevu hatırlatıcısı gönder (24 saat öncesi)
  Future<void> sendAppointmentReminders() async {
    try {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final startOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      final endOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);

      final appointments = await _db
          .collection(AppConstants.collectionAppointments)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfTomorrow))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfTomorrow))
          .where('status', isEqualTo: 'confirmed')
          .get();

      for (var doc in appointments.docs) {
        final appointment = AppointmentModel.fromFirestore(doc);

        await _notificationRepo.notifyAppointment(
          recipientId: appointment.customerId,
          title: 'Randevu Hatırlatması',
          body: 'Yarın ${appointment.timeSlot} randevunuz var. ${appointment.service}',
          appointmentId: appointment.id,
        );
      }
    } catch (e) {
      print('Hatırlatıcı gönderilirken hata: $e');
    }
  }
}
