import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? subcategory;
  final double price;
  final bool priceHidden;
  final double? originalPrice; 
  final int? discountPercentage;
  final bool isOnSale;
  final String city;
  final String? district;
  final String userId;
  final String? userName;
  final String? userPhone;
  final String? mainImage;
  final List<String> images;
  final int viewCount;
  final int favoriteCount;
  final String status; // active, sold, deleted
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? additionalInfo;

  AdModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.subcategory,
    required this.price,
    this.priceHidden = false,
    this.originalPrice,
    this.discountPercentage,
    this.isOnSale = false,
    required this.city,
    this.district,
    required this.userId,
    this.userName,
    this.userPhone,
    this.mainImage,
    List<String>? images,
    this.viewCount = 0,
    this.favoriteCount = 0,
    this.status = 'active',
    this.isFeatured = false,
    required this.createdAt,
    DateTime? updatedAt,
    this.additionalInfo,
  })  : images = images ?? [],
        updatedAt = updatedAt ?? createdAt;

  // Firestore'dan veri çekme
  factory AdModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'],
      price: (data['price'] ?? 0).toDouble(),
      priceHidden: data['priceHidden'] ?? false,
      originalPrice: data['originalPrice'] != null
          ? (data['originalPrice'] as num).toDouble()
          : null,
      discountPercentage: data['discountPercentage'],
      isOnSale: data['isOnSale'] ?? false,
      city: data['city'] ?? '',
      district: data['district'],
      userId: data['userId'] ?? '',
      userName: data['userName'],
      userPhone: data['userPhone'],
      mainImage: data['mainImage'],
      images: data['images'] != null ? List<String>.from(data['images']) : [],
      viewCount: data['viewCount'] ?? 0,
      favoriteCount: data['favoriteCount'] ?? 0,
      status: data['status'] ?? 'active',
      isFeatured: data['isFeatured'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      additionalInfo: data['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  // QueryDocumentSnapshot için (listeleme)
  factory AdModel.fromQuery(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'],
      price: (data['price'] ?? 0).toDouble(),
      priceHidden: data['priceHidden'] ?? false,
      originalPrice: data['originalPrice'] != null
          ? (data['originalPrice'] as num).toDouble()
          : null,
      discountPercentage: data['discountPercentage'],
      isOnSale: data['isOnSale'] ?? false,
      city: data['city'] ?? '',
      district: data['district'],
      userId: data['userId'] ?? '',
      userName: data['userName'],
      userPhone: data['userPhone'],
      mainImage: data['mainImage'],
      images: data['images'] != null ? List<String>.from(data['images']) : [],
      viewCount: data['viewCount'] ?? 0,
      favoriteCount: data['favoriteCount'] ?? 0,
      status: data['status'] ?? 'active',
      isFeatured: data['isFeatured'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      additionalInfo: data['additionalInfo'] as Map<String, dynamic>?,
    );
  }

  // Firestore'a kaydetme
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'price': price,
      'priceHidden': priceHidden,
      'originalPrice': originalPrice,
      'discountPercentage': discountPercentage,
      'isOnSale': isOnSale,
      'city': city,
      'district': district,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'mainImage': mainImage,
      'images': images,
      'viewCount': viewCount,
      'favoriteCount': favoriteCount,
      'status': status,
      'isFeatured': isFeatured,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'additionalInfo': additionalInfo,
    };
  }

  // Görüntülenme sayısını artırma
  AdModel incrementViewCount() {
    return AdModel(
      id: id,
      title: title,
      description: description,
      category: category,
      subcategory: subcategory,
      price: price,
      priceHidden: priceHidden,
      originalPrice: originalPrice,
      discountPercentage: discountPercentage,
      isOnSale: isOnSale,
      city: city,
      district: district,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      mainImage: mainImage,
      images: images,
      viewCount: viewCount + 1,
      favoriteCount: favoriteCount,
      status: status,
      isFeatured: isFeatured,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      additionalInfo: additionalInfo,
    );
  }

  bool get isActive => status == 'active';

  bool get hasImages => mainImage != null || images.isNotEmpty;

  String? get firstImage => mainImage ?? (images.isNotEmpty ? images.first : null);
}
