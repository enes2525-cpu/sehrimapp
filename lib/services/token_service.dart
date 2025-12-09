import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcının token bakiyesini getir
  Future<int> getUserTokens() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return 0;

    return (doc.data()?['tokens'] ?? 0) as int;
  }

  // Token ekle
  Future<void> addTokens(int amount, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Giriş yapmalısınız';

    await _firestore.collection('users').doc(user.uid).set({
      'tokens': FieldValue.increment(amount),
    }, SetOptions(merge: true));

    // İşlem geçmişine kaydet
    await _firestore.collection('token_transactions').add({
      'userId': user.uid,
      'amount': amount,
      'type': 'earn',
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Token harca
  Future<bool> spendTokens(int amount, String reason) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Giriş yapmalısınız';

    final currentTokens = await getUserTokens();
    if (currentTokens < amount) {
      return false; // Yetersiz token
    }

    await _firestore.collection('users').doc(user.uid).set({
      'tokens': FieldValue.increment(-amount),
    }, SetOptions(merge: true));

    // İşlem geçmişine kaydet
    await _firestore.collection('token_transactions').add({
      'userId': user.uid,
      'amount': amount,
      'type': 'spend',
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return true;
  }

  // Günlük giriş bonusu
  Future<void> claimDailyBonus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Giriş yapmalısınız';

    final doc = await _firestore.collection('users').doc(user.uid).get();
    final lastClaim = (doc.data()?['lastDailyBonus'] as Timestamp?)?.toDate();

    if (lastClaim != null) {
      final now = DateTime.now();
      final difference = now.difference(lastClaim);
      if (difference.inHours < 24) {
        throw 'Günlük bonusu zaten aldınız';
      }
    }

    await addTokens(5, 'Günlük giriş bonusu');
    await _firestore.collection('users').doc(user.uid).set({
      'lastDailyBonus': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Reklam izleme bonusu
  Future<void> watchAd() async {
    // Burada reklam SDK'sı entegre edilecek
    // Şimdilik sadece token ver
    await addTokens(3, 'Reklam izleme');
  }
}