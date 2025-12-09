import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/constants/app_constants.dart';
import '../models/business_model.dart';
import '../../services/auth_service.dart';
import 'token_repository.dart';
import 'user_repository.dart';

/// Shop (İşletme) işlemlerini yöneten Repository
/// Shop CRUD + Location + Stats
class ShopRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TokenRepository _tokenRepository;
  final UserRepository _userRepository;

  ShopRepository({
    TokenRepository? tokenRepository,
    UserRepository? userRepository,
  })  : _tokenRepository = tokenRepository ?? TokenRepository(),
        _userRepository = userRepository ?? UserRepository();

  // ========== SHOP İŞLEMLERİ ==========

  /// Dükkan oluştur
  Future<Result<String>> createShop(BusinessModel shop) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        return Result.error('Giriş yapmalısınız');
      }

      // Kullanıcı zaten dükkan sahibi mi?
      final existingShop = await _getUserShop(userId);
      if (existingShop.isSuccess) {
        return Result.error('Zaten bir dükkanınız var');
      }

      // Token kontrolü (opsiyonel - dükkan açma ücreti varsa)
      // final hasEnough = await _tokenRepository.hasEnoughTokens(userId, 50);
      // if (!hasEnough) return Result.error('Yetersiz token');

      // Dükkan oluştur
      final shopData = shop.toMap();
      shopData['ownerId'] = userId;
      shopData['createdAt'] = FieldValue.serverTimestamp();
      shopData['updatedAt'] = FieldValue.serverTimestamp();

      final shopDoc = await _db
          .collection(AppConstants.collectionShops)
          .add(shopData);

      // Kullanıcıyı işletme hesabına dönüştür
      await _userRepository.convertToBusinessAccount(userId);

      return Result.success(shopDoc.id);
    } catch (e) {
      return Result.error('Dükkan oluşturulurken hata: ${e.toString()}');
    }
  }

  /// Dükkan bilgilerini getir
  Future<Result<BusinessModel>> getShop(String shopId) async {
    try {
      final shopDoc = await _db
          .collection(AppConstants.collectionShops)
          .doc(shopId)
          .get();

      if (!shopDoc.exists) {
        return Result.error('Dükkan bulunamadı');
      }

      final shop = BusinessModel.fromFirestore(shopDoc);
      return Result.success(shop);
    } catch (e) {
      return Result.error('Dükkan yüklenirken hata: ${e.toString()}');
    }
  }

  /// Kullanıcının dükkanını getir
  Future<Result<BusinessModel>> _getUserShop(String userId) async {
    try {
      final shops = await _db
          .collection(AppConstants.collectionShops)
          .where('ownerId', isEqualTo: userId)
          .limit(1)
          .get();

      if (shops.docs.isEmpty) {
        return Result.error('Dükkan bulunamadı');
      }

      final shop = BusinessModel.fromFirestore(shops.docs.first);
      return Result.success(shop);
    } catch (e) {
      return Result.error('Dükkan yüklenirken hata: ${e.toString()}');
    }
  }

  /// Mevcut kullanıcının dükkanı
  Future<Result<BusinessModel>> getCurrentUserShop() async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      return Result.error('Giriş yapmalısınız');
    }
    return await _getUserShop(userId);
  }

  /// Dükkan güncelle
  Future<Result<void>> updateShop({
    required String shopId,
    String? name,
    String? description,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? coverImage,
    Map<String, double>? location,
    List<String>? openingHours,
    List<String>? categories,
  }) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        return Result.error('Giriş yapmalısınız');
      }

      // Dükkan sahibi kontrolü
      final shop = await getShop(shopId);
      if (!shop.isSuccess) {
        return Result.error(shop.error ?? 'Dükkan bulunamadı');
      }

      if (shop.data!.ownerId != userId) {
        return Result.error('Bu dükkanı düzenleme yetkiniz yok');
      }

      // Güncelleme verisi
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (phone != null) updateData['phone'] = phone;
      if (email != null) updateData['email'] = email;
      if (website != null) updateData['website'] = website;
      if (address != null) updateData['address'] = address;
      if (coverImage != null) updateData['coverImage'] = coverImage;
      if (location != null) updateData['location'] = location;
      if (openingHours != null) updateData['openingHours'] = openingHours;
      if (categories != null) updateData['categories'] = categories;

      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _db
          .collection(AppConstants.collectionShops)
          .doc(shopId)
          .update(updateData);

      return Result.success(null);
    } catch (e) {
      return Result.error('Dükkan güncellenirken hata: ${e.toString()}');
    }
  }

  /// Dükkan sil
  Future<Result<void>> deleteShop(String shopId) async {
    try {
      final userId = AuthService.currentUserId;
      if (userId == null) {
        return Result.error('Giriş yapmalısınız');
      }

      // Dükkan sahibi kontrolü
      final shop = await getShop(shopId);
      if (!shop.isSuccess) {
        return Result.error(shop.error ?? 'Dükkan bulunamadı');
      }

      if (shop.data!.ownerId != userId) {
        return Result.error('Bu dükkanı silme yetkiniz yok');
      }

      // TODO: İlişkili verileri de sil (ilanlar, randevular, vs.)

      await _db.collection(AppConstants.collectionShops).doc(shopId).delete();

      return Result.success(null);
    } catch (e) {
      return Result.error('Dükkan silinirken hata: ${e.toString()}');
    }
  }

  // ========== DÜKKAN LİSTELEME ==========

  /// Tüm dükkanları getir (Stream)
  Stream<List<BusinessModel>> getShops({
    String? category,
    String? city,
    int limit = 20,
  }) {
    Query query = _db.collection(AppConstants.collectionShops);

    if (category != null) {
      query = query.where('categories', arrayContains: category);
    }

    if (city != null) {
      query = query.where('city', isEqualTo: city);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BusinessModel.fromFirestore(doc))
            .toList());
  }

  /// Popüler dükkanlar (puanlama bazlı)
  Stream<List<BusinessModel>> getPopularShops({int limit = 10}) {
    return _db
        .collection(AppConstants.collectionShops)
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BusinessModel.fromFirestore(doc))
            .toList());
  }

  /// Yakındaki dükkanlar (konum bazlı)
  /// NOT: Firestore'da geo query sınırlı, GeoFlutterFire kullanılabilir
  Future<Result<List<BusinessModel>>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radiusInKm = 10,
  }) async {
    try {
      // Basit çözüm: Tüm dükkanları çek, mesafeyi hesapla
      // Production'da GeoFlutterFire veya Algolia kullanılmalı
      
      final shops = await _db
          .collection(AppConstants.collectionShops)
          .get();

      final nearbyShops = <BusinessModel>[];

      for (var doc in shops.docs) {
        final shop = BusinessModel.fromFirestore(doc);
        
        if (shop.location != null) {
          final distance = _calculateDistance(
            latitude,
            longitude,
            shop.location!['latitude']!,
            shop.location!['longitude']!,
          );

          if (distance <= radiusInKm) {
            nearbyShops.add(shop);
          }
        }
      }

      // Mesafeye göre sırala (yakından uzağa)
      nearbyShops.sort((a, b) {
        final distA = _calculateDistance(
          latitude,
          longitude,
          a.location!['latitude']!,
          a.location!['longitude']!,
        );
        final distB = _calculateDistance(
          latitude,
          longitude,
          b.location!['latitude']!,
          b.location!['longitude']!,
        );
        return distA.compareTo(distB);
      });

      return Result.success(nearbyShops);
    } catch (e) {
      return Result.error('Yakındaki dükkanlar yüklenirken hata: ${e.toString()}');
    }
  }

  /// İki konum arası mesafe hesapla (Haversine formülü)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.cos() * lat2.cos() * (dLon / 2).sin() * (dLon / 2).sin();

    final c = 2 * (a.sqrt()).asin();

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }

  // ========== DÜKKAN ARAMA ==========

  /// Dükkan ara (isim)
  Future<Result<List<BusinessModel>>> searchShops(String query) async {
    try {
      if (query.trim().isEmpty) {
        return Result.success([]);
      }

      final shops = await _db
          .collection(AppConstants.collectionShops)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();

      final results = shops.docs
          .map((doc) => BusinessModel.fromFirestore(doc))
          .toList();

      return Result.success(results);
    } catch (e) {
      return Result.error('Arama yapılırken hata: ${e.toString()}');
    }
  }

  // ========== İSTATİSTİKLER ==========

  /// Dükkan istatistiklerini getir
  Future<Result<Map<String, dynamic>>> getShopStats(String shopId) async {
    try {
      final shop = await getShop(shopId);
      if (!shop.isSuccess) {
        return Result.error(shop.error ?? 'Dükkan bulunamadı');
      }

      // Dükkanın ilanları
      final ads = await _db
          .collection(AppConstants.collectionAds)
          .where('businessId', isEqualTo: shopId)
          .where('status', isEqualTo: 'active')
          .get();

      // Dükkanın randevuları
      final appointments = await _db
          .collection(AppConstants.collectionAppointments)
          .where('businessId', isEqualTo: shopId)
          .get();

      // Dükkanın puanlamaları
      final ratings = await _db
          .collection(AppConstants.collectionRatings)
          .where('businessId', isEqualTo: shopId)
          .get();

      final stats = {
        'shopId': shopId,
        'name': shop.data!.name,
        'rating': shop.data!.rating,
        'totalAds': ads.docs.length,
        'totalAppointments': appointments.docs.length,
        'totalRatings': ratings.docs.length,
        'createdAt': shop.data!.createdAt,
      };

      return Result.success(stats);
    } catch (e) {
      return Result.error('İstatistikler yüklenirken hata: ${e.toString()}');
    }
  }

  // ========== DÜKKAN TAKİP ==========

  /// Dükkanı takip et
  Future<Result<void>> followShop(String shopId, String userId) async {
    try {
      // TODO: Follow collection'ı oluştur veya shops/followers subcollection
      await _db
          .collection(AppConstants.collectionShops)
          .doc(shopId)
          .collection('followers')
          .doc(userId)
          .set({
        'followedAt': FieldValue.serverTimestamp(),
      });

      // Follower sayısını artır
      await _db.collection(AppConstants.collectionShops).doc(shopId).update({
        'followerCount': FieldValue.increment(1),
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Takip edilirken hata: ${e.toString()}');
    }
  }

  /// Dükkan takipten çık
  Future<Result<void>> unfollowShop(String shopId, String userId) async {
    try {
      await _db
          .collection(AppConstants.collectionShops)
          .doc(shopId)
          .collection('followers')
          .doc(userId)
          .delete();

      // Follower sayısını azalt
      await _db.collection(AppConstants.collectionShops).doc(shopId).update({
        'followerCount': FieldValue.increment(-1),
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Takip çıkarken hata: ${e.toString()}');
    }
  }

  /// Dükkan takipte mi?
  Future<bool> isFollowingShop(String shopId, String userId) async {
    try {
      final doc = await _db
          .collection(AppConstants.collectionShops)
          .doc(shopId)
          .collection('followers')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }
}

// Math extensions
extension on double {
  double sin() => 0; // TODO: Import dart:math
  double cos() => 0;
  double asin() => 0;
  double sqrt() => 0;
}
