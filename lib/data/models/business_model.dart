import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? subcategory;
  final String city;
  final String? district;
  final String phone;
  final String address;
  final String ownerId;
  final String? photoUrl; // Profil fotoğrafı
  final List<String> images; // Galeri fotoğrafları
  final Map<String, String> workingHours; // Çalışma saatleri
  final int totalAds;
  final int totalViews;
  final double rating;
  final int reviewCount;
  final bool isActive;
  final List<String> badges; // Dükkan rozetleri
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.subcategory,
    required this.city,
    this.district,
    required this.phone,
    required this.address,
    required this.ownerId,
    this.photoUrl,
    List<String>? images,
    Map<String, String>? workingHours,
    this.totalAds = 0,
    this.totalViews = 0,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.isActive = true,
    List<String>? badges,
    required this.createdAt,
    DateTime? updatedAt,
  })  : images = images ?? [],
        workingHours = workingHours ?? {},
        badges = badges ?? [],
        updatedAt = updatedAt ?? createdAt;

  // Firestore'dan veri çekme
  factory BusinessModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusinessModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'],
      city: data['city'] ?? '',
      district: data['district'],
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      ownerId: data['ownerId'] ?? '',
      photoUrl: data['photoUrl'],
      images: data['images'] != null ? List<String>.from(data['images']) : [],
      workingHours: data['workingHours'] != null 
          ? Map<String, String>.from(data['workingHours']) 
          : {},
      totalAds: data['totalAds'] ?? 0,
      totalViews: data['totalViews'] ?? 0,
      rating: (data['rating'] ?? 5.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isActive: data['isActive'] ?? true,
      badges: data['badges'] != null ? List<String>.from(data['badges']) : [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firestore'a kaydetme
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'city': city,
      'district': district,
      'phone': phone,
      'address': address,
      'ownerId': ownerId,
      'photoUrl': photoUrl,
      'images': images,
      'workingHours': workingHours,
      'totalAds': totalAds,
      'totalViews': totalViews,
      'rating': rating,
      'reviewCount': reviewCount,
      'isActive': isActive,
      'badges': badges,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Görüntülenme sayısını artır
  BusinessModel incrementViews() {
    return BusinessModel(
      id: id,
      name: name,
      description: description,
      category: category,
      subcategory: subcategory,
      city: city,
      district: district,
      phone: phone,
      address: address,
      ownerId: ownerId,
      photoUrl: photoUrl,
      images: images,
      workingHours: workingHours,
      totalAds: totalAds,
      totalViews: totalViews + 1,
      rating: rating,
      reviewCount: reviewCount,
      isActive: isActive,
      badges: badges,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  // Şu an açık mı?
  bool get isOpenNow {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final hours = workingHours[dayName];
    
    if (hours == null || hours.isEmpty || hours == 'Kapalı') return false;
    
    try {
      final parts = hours.split('-');
      if (parts.length != 2) return false;
      
      final openTime = _parseTime(parts[0].trim());
      final closeTime = _parseTime(parts[1].trim());
      final currentTime = now.hour * 60 + now.minute;
      
      return currentTime >= openTime && currentTime <= closeTime;
    } catch (e) {
      return false;
    }
  }

  // Bugünün çalışma saatleri
  String get todayHours {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    return workingHours[dayName] ?? 'Belirtilmemiş';
  }

  // Gün adını al
  String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'Pazartesi';
      case DateTime.tuesday: return 'Salı';
      case DateTime.wednesday: return 'Çarşamba';
      case DateTime.thursday: return 'Perşembe';
      case DateTime.friday: return 'Cuma';
      case DateTime.saturday: return 'Cumartesi';
      case DateTime.sunday: return 'Pazar';
      default: return 'Pazartesi';
    }
  }

  // Saat parse et (09:00 -> 540 dakika)
  int _parseTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // Rozete sahip mi?
  bool hasBadge(String badge) => badges.contains(badge);

  // İlk fotoğrafı al
  String? get firstImage => photoUrl ?? (images.isNotEmpty ? images.first : null);
}
