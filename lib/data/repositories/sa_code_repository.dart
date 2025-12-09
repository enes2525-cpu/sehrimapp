import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/constants/app_constants.dart';
import '../models/sa_code.dart';

/// ŞA Kodu (İndirim Kuponu) Repository
class SACodeRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========== DÜKKAN TARAFI ==========

  /// Dükkan ŞA Kodu oluştur (3 ürün için %10 indirim)
  Future<Result<SACode>> createSACode({
    required String shopId,
    required String shopName,
    required List<String> adIds,
    int discountPercentage = 10,
    int validHours = 24,
  }) async {
    try {
      // En az 3 ürün olmalı
      if (adIds.length < 3) {
        return Result.error('En az 3 ürün seçmelisiniz');
      }

      final now = DateTime.now();
      final code = SACode.generateCode(shopId);

      final saCode = SACode(
        id: '',
        shopId: shopId,
        shopName: shopName,
        code: code,
        discountPercentage: discountPercentage,
        applicableAdIds: adIds,
        validFrom: now,
        validUntil: now.add(Duration(hours: validHours)),
        createdAt: now,
      );

      // Firestore'a kaydet
      final docRef = await _db.collection('sa_codes').add(saCode.toMap());

      // Dükkan ödüllerini ver
      await _grantShopRewards(shopId);

      return Result.success(saCode.copyWith(id: docRef.id));
    } catch (e) {
      return Result.error('ŞA Kodu oluşturulamadı: ${e.toString()}');
    }
  }

  /// Dükkanın aktif ŞA kodlarını getir
  Stream<List<SACode>> getShopSACodes(String shopId) {
    return _db
        .collection('sa_codes')
        .where('shopId', isEqualTo: shopId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SACode.fromFirestore(doc)).toList());
  }

  /// Dükkan ödüllerini ver (vitrin slotları + özellikler)
  Future<void> _grantShopRewards(String shopId) async {
    try {
      final shopRef = _db.collection(AppConstants.collectionShops).doc(shopId);

      await shopRef.update({
        'saCodeRewards': {
          'showcaseSlots': FieldValue.increment(5), // +5 vitrin
          'priorityUntil': Timestamp.fromDate(
            DateTime.now().add(const Duration(hours: 24)),
          ),
          'featuredShop': true,
          'statisticsAccess': true,
          'suggestedShop': true,
          'lastRewardedAt': FieldValue.serverTimestamp(),
        },
      });

      // Bildirim gönder
      final shopDoc = await shopRef.get();
      final ownerId = shopDoc.data()?['userId'] as String?;
      
      if (ownerId != null) {
        await _db.collection(AppConstants.collectionNotifications).add({
          'userId': ownerId,
          'type': 'sa_code_reward',
          'title': '🎁 ŞA Kodu Ödülü!',
          'message': 'İndirim verdiğiniz için +5 vitrin slotu ve premium özellikler kazandınız!',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Dükkan ödülleri verilirken hata: $e');
    }
  }

  // ========== KULLANICI TARAFI ==========

  /// Aktif ŞA kodlarını getir (kullanıcı görevleri tamamladıysa)
  Future<Result<List<SACode>>> getActiveSACodes(String userId) async {
    try {
      // Kullanıcı bugünkü görevleri tamamladı mı kontrol et
      final hasAccess = await _checkSACodeAccess(userId);
      
      if (!hasAccess) {
        return Result.error('ŞA Kodlarına erişmek için günlük görevleri tamamlayın!');
      }

      final snapshot = await _db
          .collection('sa_codes')
          .where('isActive', isEqualTo: true)
          .where('validUntil', isGreaterThan: Timestamp.now())
          .orderBy('validUntil')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      final codes = snapshot.docs
          .map((doc) => SACode.fromFirestore(doc))
          .where((code) => code.isValid)
          .toList();

      return Result.success(codes);
    } catch (e) {
      return Result.error('ŞA Kodları yüklenemedi: ${e.toString()}');
    }
  }

  /// ŞA Kodu kullan
  Future<Result<double>> useSACode({
    required String userId,
    required String codeId,
    required String adId,
    required double originalPrice,
  }) async {
    try {
      // Kodu getir
      final codeDoc = await _db.collection('sa_codes').doc(codeId).get();
      
      if (!codeDoc.exists) {
        return Result.error('Kod bulunamadı');
      }

      final saCode = SACode.fromFirestore(codeDoc);

      // Geçerlilik kontrolleri
      if (!saCode.isValid) {
        return Result.error('Kod geçerli değil veya süresi dolmuş');
      }

      if (!saCode.applicableAdIds.contains(adId)) {
        return Result.error('Bu kod bu ürün için geçerli değil');
      }

      // İndirimli fiyatı hesapla
      final discountAmount = originalPrice * (saCode.discountPercentage / 100);
      final discountedPrice = originalPrice - discountAmount;

      // Kullanımı kaydet
      final usage = SACodeUsage(
        id: '',
        userId: userId,
        codeId: codeId,
        code: saCode.code,
        shopId: saCode.shopId,
        adId: adId,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        discountPercentage: saCode.discountPercentage,
        usedAt: DateTime.now(),
      );

      await _db.collection('sa_code_usages').add(usage.toMap());

      // Kod kullanım sayısını artır
      await _db.collection('sa_codes').doc(codeId).update({
        'usageCount': FieldValue.increment(1),
      });

      return Result.success(discountedPrice);
    } catch (e) {
      return Result.error('Kod kullanılamadı: ${e.toString()}');
    }
  }

  /// Kullanıcının ŞA Kodu erişimi var mı?
  Future<bool> _checkSACodeAccess(String userId) async {
    try {
      final today = DateTime.now();
      final dateOnly = DateTime(today.year, today.month, today.day);
      final docId = '${userId}_${dateOnly.millisecondsSinceEpoch ~/ 86400000}';

      final doc = await _db.collection('daily_quests').doc(docId).get();
      
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      return data['saCodeUnlocked'] == true;
    } catch (e) {
      return false;
    }
  }

  // ========== İSTATİSTİKLER ==========

  /// Dükkanın ŞA Kodu istatistikleri
  Future<Result<Map<String, dynamic>>> getShopSACodeStats(String shopId) async {
    try {
      // Toplam oluşturulan kod sayısı
      final codesSnapshot = await _db
          .collection('sa_codes')
          .where('shopId', isEqualTo: shopId)
          .get();

      // Toplam kullanım sayısı
      final usagesSnapshot = await _db
          .collection('sa_code_usages')
          .where('shopId', isEqualTo: shopId)
          .get();

      // Toplam tasarruf miktarı
      double totalSavings = 0;
      for (var doc in usagesSnapshot.docs) {
        final data = doc.data();
        totalSavings += (data['originalPrice'] - data['discountedPrice']);
      }

      return Result.success({
        'totalCodes': codesSnapshot.docs.length,
        'totalUsages': usagesSnapshot.docs.length,
        'totalSavings': totalSavings,
        'activeCodeCount': codesSnapshot.docs
            .where((doc) => doc.data()['isActive'] == true)
            .length,
      });
    } catch (e) {
      return Result.error('İstatistikler alınamadı: ${e.toString()}');
    }
  }
}

extension on SACode {
  SACode copyWith({String? id}) {
    return SACode(
      id: id ?? this.id,
      shopId: shopId,
      shopName: shopName,
      code: code,
      discountPercentage: discountPercentage,
      applicableAdIds: applicableAdIds,
      validFrom: validFrom,
      validUntil: validUntil,
      isActive: isActive,
      usageCount: usageCount,
      maxUsage: maxUsage,
      createdAt: createdAt,
    );
  }
}
