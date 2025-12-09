import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firestore_service.dart';

class ReferralService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Davet kodu oluştur (kullanıcı ID'sinin hash'i)
  static String generateReferralCode(String userId) {
    return userId.substring(0, 8).toUpperCase();
  }

  // Davet linki oluştur
  static String generateReferralLink(String referralCode) {
    return 'https://sehrimapp.com/invite/$referralCode';
  }

  // Davet kodunu paylaş
  static Future<void> shareReferralCode(String referralCode) async {
    final link = generateReferralLink(referralCode);
    await Share.share(
      'ŞehrimApp\'e katıl ve 50 token kazan! 🎁\n\nDavet kodum: $referralCode\nİndirmek için: $link',
      subject: 'ŞehrimApp Daveti',
    );
  }

  // Davet kodu ile kayıt (yeni kullanıcı için)
  static Future<bool> redeemReferralCode({
    required String newUserId,
    required String referralCode,
  }) async {
    try {
      // Davet eden kullanıcıyı bul
      final referrers = await _db
          .collection('users')
          .where('referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (referrers.docs.isEmpty) {
        return false; // Geçersiz kod
      }

      final referrerId = referrers.docs.first.id;

      // Kendi kendini davet etme kontrolü
      if (referrerId == newUserId) {
        return false;
      }

      // Daha önce kullanılmış mı kontrol et
      final existingReferral = await _db
          .collection('referrals')
          .where('referredUserId', isEqualTo: newUserId)
          .limit(1)
          .get();

      if (existingReferral.docs.isNotEmpty) {
        return false; // Zaten bir davet kodu kullanılmış
      }

      // Referral kaydı oluştur
      await _db.collection('referrals').add({
        'referrerId': referrerId,
        'referredUserId': newUserId,
        'referralCode': referralCode,
        'status': 'completed',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Her iki kullanıcıya da token ver
      await _db.collection('users').doc(referrerId).update({
        'tokenBalance': FieldValue.increment(50),
        'totalReferrals': FieldValue.increment(1),
      });

      await _db.collection('users').doc(newUserId).update({
        'tokenBalance': FieldValue.increment(50),
        'referredBy': referrerId,
      });

      return true;
    } catch (e) {
      print('Referral error: $e');
      return false;
    }
  }

  // Kullanıcının davet istatistikleri
  static Future<Map<String, dynamic>> getReferralStats(String userId) async {
    final referrals = await _db
        .collection('referrals')
        .where('referrerId', isEqualTo: userId)
        .get();

    final totalReferrals = referrals.docs.length;
    final totalEarned = totalReferrals * 50; // Her davet 50 token

    return {
      'totalReferrals': totalReferrals,
      'totalEarned': totalEarned,
      'referralCode': generateReferralCode(userId),
    };
  }

  // Davet edilen kullanıcılar listesi
  static Future<List<Map<String, dynamic>>> getReferredUsers(
      String userId) async {
    final referrals = await _db
        .collection('referrals')
        .where('referrerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    List<Map<String, dynamic>> users = [];

    for (var referral in referrals.docs) {
      final data = referral.data();
      final user = await FirestoreService.getUser(data['referredUserId']);
      
      if (user != null) {
        users.add({
          'name': user.name,
          'date': (data['createdAt'] as Timestamp?)?.toDate(),
        });
      }
    }

    return users;
  }
}
