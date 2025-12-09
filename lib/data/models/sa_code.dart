import 'package:cloud_firestore/cloud_firestore.dart';

/// ŞA Kodu (Şehrim App İndirim Kuponu)
class SACode {
  final String id;
  final String shopId;
  final String shopName;
  final String code; // Örnek: "SA-SHOP123-45678"
  final int discountPercentage; // 10%
  final List<String> applicableAdIds; // Hangi ürünlerde geçerli
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isActive;
  final int usageCount;
  final int maxUsage; // Maksimum kullanım sayısı
  final DateTime createdAt;

  SACode({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.code,
    this.discountPercentage = 10,
    required this.applicableAdIds,
    required this.validFrom,
    required this.validUntil,
    this.isActive = true,
    this.usageCount = 0,
    this.maxUsage = 100,
    required this.createdAt,
  });

  // Kod hala geçerli mi?
  bool get isValid {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(validFrom) && 
           now.isBefore(validUntil) &&
           usageCount < maxUsage;
  }

  // Kalan kullanım
  int get remainingUsage => maxUsage - usageCount;

  // Kod oluştur
  static String generateCode(String shopId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return 'SA-${shopId.substring(0, 6).toUpperCase()}-$timestamp';
  }

  // Firestore'dan çek
  factory SACode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SACode(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? '',
      code: data['code'] ?? '',
      discountPercentage: data['discountPercentage'] ?? 10,
      applicableAdIds: List<String>.from(data['applicableAdIds'] ?? []),
      validFrom: (data['validFrom'] as Timestamp?)?.toDate() ?? DateTime.now(),
      validUntil: (data['validUntil'] as Timestamp?)?.toDate() ?? 
                  DateTime.now().add(const Duration(days: 1)),
      isActive: data['isActive'] ?? true,
      usageCount: data['usageCount'] ?? 0,
      maxUsage: data['maxUsage'] ?? 100,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firestore'a kaydet
  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'shopName': shopName,
      'code': code,
      'discountPercentage': discountPercentage,
      'applicableAdIds': applicableAdIds,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': Timestamp.fromDate(validUntil),
      'isActive': isActive,
      'usageCount': usageCount,
      'maxUsage': maxUsage,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// ŞA Kodu Kullanımı (User tarafında)
class SACodeUsage {
  final String id;
  final String userId;
  final String codeId;
  final String code;
  final String shopId;
  final String adId;
  final double originalPrice;
  final double discountedPrice;
  final int discountPercentage;
  final DateTime usedAt;

  SACodeUsage({
    required this.id,
    required this.userId,
    required this.codeId,
    required this.code,
    required this.shopId,
    required this.adId,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercentage,
    required this.usedAt,
  });

  // Tasarruf miktarı
  double get savedAmount => originalPrice - discountedPrice;

  factory SACodeUsage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SACodeUsage(
      id: doc.id,
      userId: data['userId'] ?? '',
      codeId: data['codeId'] ?? '',
      code: data['code'] ?? '',
      shopId: data['shopId'] ?? '',
      adId: data['adId'] ?? '',
      originalPrice: (data['originalPrice'] ?? 0).toDouble(),
      discountedPrice: (data['discountedPrice'] ?? 0).toDouble(),
      discountPercentage: data['discountPercentage'] ?? 10,
      usedAt: (data['usedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'codeId': codeId,
      'code': code,
      'shopId': shopId,
      'adId': adId,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'discountPercentage': discountPercentage,
      'usedAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Dükkanın ŞA Kodu karşılığında aldığı avantajlar
class SACodeReward {
  final int showcaseSlots; // Ek vitrin slotu
  final int priorityHours; // Üst sırada kalma süresi
  final bool featuredShop; // "İndirimli Dükkanlar" rozetini
  final bool statisticsAccess; // İstatistiklere erişim
  final bool suggestedShop; // "Önerilen Dükkanlar" listesinde

  const SACodeReward({
    this.showcaseSlots = 5,
    this.priorityHours = 24,
    this.featuredShop = true,
    this.statisticsAccess = true,
    this.suggestedShop = true,
  });

  // Premium ödül (daha fazla indirim verirse)
  static const premium = SACodeReward(
    showcaseSlots: 10,
    priorityHours: 48,
    featuredShop: true,
    statisticsAccess: true,
    suggestedShop: true,
  );
}
