/// String için yardımcı extension'lar
extension StringExtensions on String {
  /// İlk harfi büyük yap
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Her kelimenin ilk harfini büyük yap
  String get titleCase {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Email validasyonu
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Telefon validasyonu (Türkiye)
  bool get isValidPhone {
    final phoneRegex = RegExp(r'^0?5\d{9}$');
    return phoneRegex.hasMatch(this);
  }

  /// URL validasyonu
  bool get isValidUrl {
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    return urlRegex.hasMatch(this);
  }

  /// Sayı mı kontrolü
  bool get isNumeric {
    return double.tryParse(this) != null;
  }

  /// Sadece harf mi kontrolü
  bool get isAlpha {
    return RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ]+$').hasMatch(this);
  }

  /// Alfanumerik mi kontrolü
  bool get isAlphanumeric {
    return RegExp(r'^[a-zA-Z0-9ğüşıöçĞÜŞİÖÇ]+$').hasMatch(this);
  }

  /// Boşlukları temizle
  String get removeSpaces {
    return replaceAll(' ', '');
  }

  /// Türkçe karakterleri İngilizce'ye çevir
  String get turkishToEnglish {
    return replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'G')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'U')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 'S')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'I')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'O')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'C');
  }

  /// Telefon numarasını formatla (5xxxxxxxxx -> 0 (5xx) xxx xx xx)
  String get formatPhone {
    if (length != 10 && length != 11) return this;
    
    String phone = this;
    if (!phone.startsWith('0')) {
      phone = '0$phone';
    }
    
    return '${phone.substring(0, 1)} (${phone.substring(1, 4)}) ${phone.substring(4, 7)} ${phone.substring(7, 9)} ${phone.substring(9)}';
  }

  /// Fiyatı formatla (1234567 -> 1.234.567 ₺)
  String get formatPrice {
    final price = double.tryParse(this);
    if (price == null) return this;
    
    final formatter = price.toStringAsFixed(0);
    final reversed = formatter.split('').reversed.toList();
    final chunks = <String>[];
    
    for (var i = 0; i < reversed.length; i += 3) {
      final end = i + 3;
      chunks.add(reversed.sublist(i, end > reversed.length ? reversed.length : end).reversed.join());
    }
    
    return '${chunks.reversed.join('.')} ₺';
  }

  /// Metni kısalt (maksimum karakter sayısı)
  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$suffix';
  }

  /// İlk n kelimeyi al
  String firstWords(int count) {
    final words = split(' ');
    if (words.length <= count) return this;
    return '${words.take(count).join(' ')}...';
  }

  /// Slug oluştur (URL için)
  String get slug {
    return turkishToEnglish
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Maskele (email için: test@example.com -> t**t@example.com)
  String maskEmail() {
    if (!isValidEmail) return this;
    
    final parts = split('@');
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 2) return this;
    
    final masked = '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}';
    return '$masked@$domain';
  }

  /// Maskele (telefon için: 05551234567 -> 0555***4567)
  String maskPhone() {
    if (!isValidPhone) return this;
    
    String phone = this;
    if (!phone.startsWith('0')) {
      phone = '0$phone';
    }
    
    return '${phone.substring(0, 4)}***${phone.substring(7)}';
  }
}

/// Nullable String için extension'lar
extension NullableStringExtensions on String? {
  /// Null veya boş mu?
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// Null veya boş değil mi?
  bool get isNotNullOrEmpty => !isNullOrEmpty;

  /// Null ise varsayılan değer döndür
  String orDefault(String defaultValue) => this ?? defaultValue;

  /// Null veya boş ise varsayılan değer döndür
  String orEmpty() => this ?? '';
}
