import 'package:flutter/foundation.dart';
import '../../../data/repositories/appointment_repository.dart';

class AppointmentProvider with ChangeNotifier {
  final AppointmentRepository _appointmentRepo = AppointmentRepository();

  List<AppointmentModel> _appointments = [];
  List<String> _availableSlots = [];
  bool _isLoading = false;
  String? _error;

  List<AppointmentModel> get appointments => _appointments;
  List<String> get availableSlots => _availableSlots;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Randevu oluştur
  Future<bool> createAppointment({
    required String businessId,
    required DateTime date,
    required String timeSlot,
    required String service,
    required double price,
    String? notes,
    bool usePriority = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _appointmentRepo.createAppointment(
      businessId: businessId,
      appointmentDate: date,
      timeSlot: timeSlot,
      service: service,
      price: price,
      notes: notes,
      usePriorityToken: usePriority,
    );

    _isLoading = false;

    if (result.isSuccess) {
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  // Müsait saatleri yükle
  Future<void> loadAvailableSlots(String businessId, DateTime date) async {
    _isLoading = true;
    notifyListeners();

    final result = await _appointmentRepo.getAvailableTimeSlots(businessId, date);

    if (result.isSuccess) {
      _availableSlots = result.data!;
      _error = null;
    } else {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Randevuları yükle
  void loadAppointments(String userId) {
    _appointmentRepo.getCustomerAppointments(userId).listen((appointments) {
      _appointments = appointments;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Randevu iptal et
  Future<bool> cancelAppointment(String appointmentId) async {
    final result = await _appointmentRepo.cancelAppointment(appointmentId);

    if (result.isSuccess) {
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }
}
