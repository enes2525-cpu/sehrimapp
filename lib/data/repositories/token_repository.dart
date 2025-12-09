import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/constants/app_constants.dart';
import '../../services/auth_service.dart';

/// Token Model (Log için)
class TokenLog {
  final String id;
  final String userId;
  final int amount;
  final String type; // 'add', 'deduct'
  final String reason;
  final DateTime createdAt;

  TokenLog({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.reason,
    required this.createdAt,
  });

  factory TokenLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TokenLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      amount: data['amount'] ?? 0,
      type: data['type'] ?? '',
      reason: data['reason'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'type': type,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// Token işlemlerini yöneten Repository
/// Token economy'nin beyni
class TokenRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========== TOKEN BAKIYE İŞLEMLERİ ==========

  /// Kullanıcının token bakiyesini getir
  Future<Result<int>> getBalance(String userId) async {
    try {
      final userDoc = await _db
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return Result.error('Kullanıcı bulunamadı');
      }

      final balance = (userDoc.data()?['tokenBalance'] ?? 0) as int;
      return Result.success(balance);
    } catch (e) {
      return Result.error('Bakiye yüklenirken hata: ${e.toString()}');
    }
  }

  /// Mevcut kullanıcının bakiyesi
  Future<Result<int>> getCurrentUserBalance() async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      return Result.error('Giriş yapmalısınız');
    }
    return await getBalance(userId);
  }

  /// Yeterli token var mı kontrol et
  Future<bool> hasEnoughTokens(String userId, int requiredAmount) async {
    try {
      final balanceResult = await getBalance(userId);
      if (!balanceResult.isSuccess) return false;

      return balanceResult.data! >= requiredAmount;
    } catch (e) {
      return false;
    }
  }

  /// Mevcut kullanıcı için token kontrolü
  Future<bool> currentUserHasEnoughTokens(int requiredAmount) async {
    final userId = AuthService.currentUserId;
    if (userId == null) return false;
    return await hasEnoughTokens(userId, requiredAmount);
  }

  // ========== TOKEN EKLEME ==========

  /// Token ekle (satın alma, hediye, vs.)
  Future<Result<int>> addTokens(
    String userId,
    int amount, {
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (amount <= 0) {
        return Result.error('Token miktarı pozitif olmalı');
      }

      // Transaction kullanarak atomic işlem
      final newBalance = await _db.runTransaction<int>((transaction) async {
        final userRef = _db.collection(AppConstants.collectionUsers).doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('Kullanıcı bulunamadı');
        }

        final currentBalance = (userDoc.data()?['tokenBalance'] ?? 0) as int;
        final newBalance = currentBalance + amount;

        // Bakiyeyi güncelle
        transaction.update(userRef, {
          'tokenBalance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return newBalance;
      });

      // Log kaydet
      await _createTokenLog(
        userId: userId,
        amount: amount,
        type: 'add',
        reason: reason,
        metadata: metadata,
      );

      return Result.success(newBalance);
    } catch (e) {
      return Result.error('Token eklenirken hata: ${e.toString()}');
    }
  }

  // ========== TOKEN DÜŞME ==========

  /// Token düş (harcama)
  Future<Result<int>> deductTokens(
    String userId,
    int amount, {
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (amount <= 0) {
        return Result.error('Token miktarı pozitif olmalı');
      }

      // Yeterli token var mı kontrol et
      final hasEnough = await hasEnoughTokens(userId, amount);
      if (!hasEnough) {
        return Result.error('Yetersiz token. $amount token gerekli.');
      }

      // Transaction kullanarak atomic işlem
      final newBalance = await _db.runTransaction<int>((transaction) async {
        final userRef = _db.collection(AppConstants.collectionUsers).doc(userId);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) {
          throw Exception('Kullanıcı bulunamadı');
        }

        final currentBalance = (userDoc.data()?['tokenBalance'] ?? 0) as int;
        
        // Double check
        if (currentBalance < amount) {
          throw Exception('Yetersiz token');
        }

        final newBalance = currentBalance - amount;

        // Bakiyeyi güncelle
        transaction.update(userRef, {
          'tokenBalance': newBalance,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return newBalance;
      });

      // Log kaydet
      await _createTokenLog(
        userId: userId,
        amount: amount,
        type: 'deduct',
        reason: reason,
        metadata: metadata,
      );

      return Result.success(newBalance);
    } catch (e) {
      if (e.toString().contains('Yetersiz token')) {
        return Result.error('Yetersiz token. $amount token gerekli.');
      }
      return Result.error('Token düşülürken hata: ${e.toString()}');
    }
  }

  // ========== ÖZEL İŞLEMLER ==========

  /// Hoşgeldin bonusu ver
  Future<Result<int>> giveWelcomeBonus(String userId) async {
    return await addTokens(
      userId,
      AppConstants.tokenWelcomeBonus,
      reason: 'Hoşgeldin bonusu',
      metadata: {'type': 'welcome'},
    );
  }

  /// Günlük bonus ver
  Future<Result<int>> giveDailyBonus(String userId) async {
    try {
      // Son bonus zamanını kontrol et
      final lastBonusResult = await _getLastBonusDate(userId);
      
      if (lastBonusResult.isSuccess) {
        final lastBonus = lastBonusResult.data!;
        final now = DateTime.now();
        
        // Aynı gün içinde bonus alınmış mı?
        if (lastBonus.year == now.year &&
            lastBonus.month == now.month &&
            lastBonus.day == now.day) {
          return Result.error('Bugün zaten günlük bonus aldınız');
        }
      }

      // Bonus ver
      final result = await addTokens(
        userId,
        AppConstants.tokenDailyBonus,
        reason: 'Günlük bonus',
        metadata: {'type': 'daily'},
      );

      if (result.isSuccess) {
        // Son bonus tarihini güncelle
        await _updateLastBonusDate(userId);
      }

      return result;
    } catch (e) {
      return Result.error('Günlük bonus verilirken hata: ${e.toString()}');
    }
  }

  /// Referral bonusu ver
  Future<Result<int>> giveReferralBonus(String userId) async {
    return await addTokens(
      userId,
      AppConstants.tokenReferralBonus,
      reason: 'Arkadaş davet bonusu',
      metadata: {'type': 'referral'},
    );
  }

  // ========== TOKEN LOG ==========

  /// Token geçmişini getir
  Future<Result<List<TokenLog>>> getTokenLogs(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _db
          .collection('token_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final logs = snapshot.docs
          .map((doc) => TokenLog.fromFirestore(doc))
          .toList();

      return Result.success(logs);
    } catch (e) {
      return Result.error('Token geçmişi yüklenirken hata: ${e.toString()}');
    }
  }

  /// Token log stream (real-time)
  Stream<List<TokenLog>> getTokenLogsStream(
    String userId, {
    int limit = 20,
  }) {
    return _db
        .collection('token_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TokenLog.fromFirestore(doc)).toList());
  }

  /// Token log oluştur (private)
  Future<void> _createTokenLog({
    required String userId,
    required int amount,
    required String type,
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    final log = TokenLog(
      id: '',
      userId: userId,
      amount: amount,
      type: type,
      reason: reason,
      createdAt: DateTime.now(),
    );

    final data = log.toMap();
    if (metadata != null) {
      data['metadata'] = metadata;
    }

    await _db.collection('token_logs').add(data);
  }

  // ========== İSTATİSTİKLER ==========

  /// Toplam harcanan token
  Future<Result<int>> getTotalSpent(String userId) async {
    try {
      final snapshot = await _db
          .collection('token_logs')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'deduct')
          .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] ?? 0) as int;
      }

      return Result.success(total);
    } catch (e) {
      return Result.error('İstatistik hesaplanırken hata: ${e.toString()}');
    }
  }

  /// Toplam kazanılan token
  Future<Result<int>> getTotalEarned(String userId) async {
    try {
      final snapshot = await _db
          .collection('token_logs')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'add')
          .get();

      int total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] ?? 0) as int;
      }

      return Result.success(total);
    } catch (e) {
      return Result.error('İstatistik hesaplanırken hata: ${e.toString()}');
    }
  }

  /// Token istatistikleri
  Future<Result<Map<String, dynamic>>> getTokenStats(String userId) async {
    try {
      final balance = await getBalance(userId);
      final totalSpent = await getTotalSpent(userId);
      final totalEarned = await getTotalEarned(userId);

      final stats = {
        'balance': balance.data ?? 0,
        'totalSpent': totalSpent.data ?? 0,
        'totalEarned': totalEarned.data ?? 0,
        'netGain': (totalEarned.data ?? 0) - (totalSpent.data ?? 0),
      };

      return Result.success(stats);
    } catch (e) {
      return Result.error('İstatistikler hesaplanırken hata: ${e.toString()}');
    }
  }

  // ========== HELPER METOTLAR ==========

  /// Son bonus tarihini getir
  Future<Result<DateTime>> _getLastBonusDate(String userId) async {
    try {
      final userDoc = await _db
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return Result.error('Kullanıcı bulunamadı');
      }

      final lastBonus = userDoc.data()?['lastDailyBonus'] as Timestamp?;
      if (lastBonus == null) {
        // Hiç bonus almamış
        return Result.error('Bonus alınmamış');
      }

      return Result.success(lastBonus.toDate());
    } catch (e) {
      return Result.error('Tarih kontrol edilirken hata: ${e.toString()}');
    }
  }

  /// Son bonus tarihini güncelle
  Future<void> _updateLastBonusDate(String userId) async {
    await _db.collection(AppConstants.collectionUsers).doc(userId).update({
      'lastDailyBonus': FieldValue.serverTimestamp(),
    });
  }

  // ========== VALIDATION ==========

  /// Token işlemi doğrula
  Future<Result<bool>> validateTransaction({
    required String userId,
    required int amount,
    required String type,
  }) async {
    try {
      if (amount <= 0) {
        return Result.error('Geçersiz token miktarı');
      }

      // Kullanıcı var mı?
      final userDoc = await _db
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return Result.error('Kullanıcı bulunamadı');
      }

      // Düşme işleminde yeterli bakiye var mı?
      if (type == 'deduct') {
        final hasEnough = await hasEnoughTokens(userId, amount);
        if (!hasEnough) {
          return Result.error('Yetersiz token');
        }
      }

      return Result.success(true);
    } catch (e) {
      return Result.error('Doğrulama hatası: ${e.toString()}');
    }
  }
}
