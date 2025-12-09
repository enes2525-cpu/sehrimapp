import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mevcut kullanıcı
  static User? get currentUser => _auth.currentUser;

  // Kullanıcı ID'si
  static String? get currentUserId => _auth.currentUser?.uid;

  // Giriş yapılmış mı?
  static bool get isLoggedIn => _auth.currentUser != null;

  // Kullanıcı durumunu dinle
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ========== KAYIT ==========
  
  static Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    String? city,
    String? phone,
  }) async {
    try {
      // Firebase Auth'da kullanıcı oluştur
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore'da kullanıcı profili oluştur
      final user = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        city: city,
        phone: phone,
        tokenBalance: 100, // Başlangıç token'ı
      );

      await FirestoreService.createUser(user);

      // Display name güncelle
      await credential.user!.updateDisplayName(name);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ========== GİRİŞ ==========
  
  static Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ========== ÇIKIŞ ==========
  
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // ========== ŞİFRE SIFIRLAMA ==========
  
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ========== ŞİFRE DEĞİŞTİRME ==========
  
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Kullanıcı bulunamadı';

      // Önce mevcut şifreyle yeniden giriş yap (güvenlik)
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Yeni şifreyi güncelle
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ========== KULLANICI BİLGİLERİNİ GÜNCELLE ==========
  
  static Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Kullanıcı bulunamadı';

    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    if (photoURL != null) {
      await user.updatePhotoURL(photoURL);
    }
  }

  // ========== HESAP SİLME ==========
  
  static Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Kullanıcı bulunamadı';

      // Önce şifreyle doğrula
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Firestore'dan kullanıcı verilerini sil
      // (İlanlar vs. silinmez, sadece userId ile ilişkisi kopar)
      
      // Firebase Auth'dan kullanıcıyı sil
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // ========== HATA YÖNETİMİ ==========
  
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda kullanılamıyor.';
      case 'requires-recent-login':
        return 'Bu işlem için tekrar giriş yapmanız gerekiyor.';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }
}
