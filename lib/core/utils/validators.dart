/// Form validasyon fonksiyonları
class Validators {
  // Email validasyonu
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email adresi boş bırakılamaz';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir email adresi girin';
    }
    
    return null;
  }

  // Şifre validasyonu
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre boş bırakılamaz';
    }
    
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }
    
    return null;
  }

  // Telefon validasyonu
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası boş bırakılamaz';
    }
    
    // Türkiye telefon formatı: 5xxxxxxxxx veya 05xxxxxxxxx
    final phoneRegex = RegExp(r'^0?5\d{9}$');
    
    if (!phoneRegex.hasMatch(value)) {
      return 'Geçerli bir telefon numarası girin (5xxxxxxxxx)';
    }
    
    return null;
  }

  // İsim validasyonu
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'İsim boş bırakılamaz';
    }
    
    if (value.length < 2) {
      return 'İsim en az 2 karakter olmalı';
    }
    
    if (value.length > 50) {
      return 'İsim en fazla 50 karakter olabilir';
    }
    
    return null;
  }

  // Fiyat validasyonu
  static String? price(String? value) {
    if (value == null || value.isEmpty) {
      return 'Fiyat boş bırakılamaz';
    }
    
    final price = double.tryParse(value);
    
    if (price == null) {
      return 'Geçerli bir fiyat girin';
    }
    
    if (price < 0) {
      return 'Fiyat 0\'dan küçük olamaz';
    }
    
    return null;
  }

  // Genel metin validasyonu (boş kontrolü)
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Bu alan'} boş bırakılamaz';
    }
    return null;
  }

  // Minimum karakter validasyonu
  static String? minLength(String? value, int min, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Bu alan'} boş bırakılamaz';
    }
    
    if (value.length < min) {
      return '${fieldName ?? 'Bu alan'} en az $min karakter olmalı';
    }
    
    return null;
  }

  // Maksimum karakter validasyonu
  static String? maxLength(String? value, int max, {String? fieldName}) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length > max) {
      return '${fieldName ?? 'Bu alan'} en fazla $max karakter olabilir';
    }
    
    return null;
  }

  // URL validasyonu
  static String? url(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Geçerli bir URL girin';
    }
    
    return null;
  }

  // Sayı validasyonu
  static String? number(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bu alan boş bırakılamaz';
    }
    
    if (double.tryParse(value) == null) {
      return 'Geçerli bir sayı girin';
    }
    
    return null;
  }

  // Tam sayı validasyonu
  static String? integer(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bu alan boş bırakılamaz';
    }
    
    if (int.tryParse(value) == null) {
      return 'Geçerli bir tam sayı girin';
    }
    
    return null;
  }

  // Aralık validasyonu
  static String? range(String? value, double min, double max) {
    if (value == null || value.isEmpty) {
      return 'Bu alan boş bırakılamaz';
    }
    
    final number = double.tryParse(value);
    
    if (number == null) {
      return 'Geçerli bir sayı girin';
    }
    
    if (number < min || number > max) {
      return 'Değer $min ile $max arasında olmalı';
    }
    
    return null;
  }

  // Şifre eşleşme kontrolü
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı boş bırakılamaz';
    }
    
    if (value != password) {
      return 'Şifreler eşleşmiyor';
    }
    
    return null;
  }

  Validators._(); // Private constructor
}
