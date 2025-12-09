import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AppointmentRequestScreen extends StatefulWidget {
  final String businessId;
  final String businessName;
  final Map<String, dynamic> businessData;

  const AppointmentRequestScreen({
    Key? key,
    required this.businessId,
    required this.businessName,
    required this.businessData,
  }) : super(key: key);

  @override
  State<AppointmentRequestScreen> createState() =>
      _AppointmentRequestScreenState();
}

class _AppointmentRequestScreenState extends State<AppointmentRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTime;
  bool _isLoading = false;
  Set<String> _bookedSlots = {};
  bool _isLoadingSlots = false;

  List<String> _availableTimes = [];

  @override
  void initState() {
    super.initState();
    _generateAvailableTimes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _generateAvailableTimes() {
    final openingTime = widget.businessData['openingTime'] ?? '09:00';
    final closingTime = widget.businessData['closingTime'] ?? '18:00';

    final openHour = int.parse(openingTime.split(':')[0]);
    final closeHour = int.parse(closingTime.split(':')[0]);

    _availableTimes = [];
    for (int hour = openHour; hour < closeHour; hour++) {
      _availableTimes.add('${hour.toString().padLeft(2, '0')}:00');
      _availableTimes.add('${hour.toString().padLeft(2, '0')}:30');
    }
  }

  bool _isDateAvailable(DateTime date) {
    // Geçmiş tarihler seçilemez
    if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }

    final dayNames = [
      '',
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];
    final dayName = dayNames[date.weekday];

    final workingDays = widget.businessData['workingDays'] as Map<String, dynamic>?;
    if (workingDays == null) return false;

    return workingDays[dayName] == true;
  }

  Future<void> _loadBookedSlots(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _bookedSlots.clear();
    });

    try {
      // Seçilen tarihteki tüm randevuları getir (basitleştirilmiş sorgu)
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('businessId', isEqualTo: widget.businessId)
          .where('appointmentDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final bookedTimes = <String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'];
        // Sadece bekleyen ve onaylanmış randevuları say
        if (status == 'pending' || status == 'confirmed') {
          bookedTimes.add(data['appointmentTime'] ?? '');
        }
      }

      setState(() {
        _bookedSlots = bookedTimes;
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSlots = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Randevular yüklenirken hata: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    // İlk uygun tarihi bul
    DateTime initialDate = DateTime.now().add(const Duration(days: 1));
    
    // Eğer başlangıç tarihi uygun değilse, ilk uygun günü bul
    int daysToCheck = 0;
    while (!_isDateAvailable(initialDate) && daysToCheck < 30) {
      daysToCheck++;
      initialDate = DateTime.now().add(Duration(days: daysToCheck));
    }
    
    // Hiç uygun gün yoksa, varsayılan olarak yarını kullan
    if (daysToCheck >= 30) {
      initialDate = DateTime.now().add(const Duration(days: 1));
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      selectableDayPredicate: _isDateAvailable,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
      await _loadBookedSlots(picked);
    }
  }

  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tarih seçin')),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen saat seçin')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Kullanıcı bilgilerini al
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Kullanıcı';

      // Randevu oluştur
      await FirebaseFirestore.instance.collection('appointments').add({
        'customerId': user.uid,
        'customerName': userName,
        'businessId': widget.businessId,
        'businessName': widget.businessName,
        'businessOwnerId': widget.businessData['ownerId'],
        'appointmentDate': Timestamp.fromDate(_selectedDate!),
        'appointmentTime': _selectedTime,
        'status': 'pending',
        'note': _noteController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Randevu talebiniz gönderildi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Randevu Al'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // İşletme Bilgisi
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.store, color: Colors.blue.shade700),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.businessName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.businessData['businessCategory'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tarih Seçimi
              const Text(
                'Tarih Seçin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.blue.shade700),
                      const SizedBox(width: 16),
                      Text(
                        _selectedDate == null
                            ? 'Tarih seçin'
                            : DateFormat('dd MMMM yyyy, EEEE', 'tr_TR')
                                .format(_selectedDate!),
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate == null
                              ? Colors.grey.shade600
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Saat Seçimi
              if (_selectedDate != null) ...[
                Row(
                  children: [
                    const Text(
                      'Saat Seçin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_isLoadingSlots)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildLegendItem(Colors.green.shade100, 'Boş'),
                    const SizedBox(width: 16),
                    _buildLegendItem(Colors.red.shade100, 'Dolu'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoadingSlots
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableTimes.map((time) {
                            final isBooked = _bookedSlots.contains(time);
                            final isSelected = _selectedTime == time;

                            return InkWell(
                              onTap: isBooked
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedTime = time;
                                      });
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isBooked
                                      ? Colors.red.shade100
                                      : isSelected
                                          ? Colors.blue.shade700
                                          : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isBooked
                                        ? Colors.red.shade300
                                        : isSelected
                                            ? Colors.blue.shade700
                                            : Colors.green.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isBooked)
                                      Icon(Icons.close,
                                          size: 16, color: Colors.red.shade700),
                                    if (isBooked) const SizedBox(width: 4),
                                    Text(
                                      time,
                                      style: TextStyle(
                                        color: isBooked
                                            ? Colors.red.shade700
                                            : isSelected
                                                ? Colors.white
                                                : Colors.green.shade900,
                                        fontWeight: isSelected || isBooked
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        decoration: isBooked
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 24),
              ],

              // Not
              const Text(
                'Not (Opsiyonel)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Randevu hakkında not ekleyin...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Gönder Butonu
              ElevatedButton(
                onPressed: _isLoading ? null : _submitAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Randevu Talebi Gönder',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}