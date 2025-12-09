import 'package:intl/intl.dart';

/// DateTime için yardımcı extension'lar
extension DateTimeExtensions on DateTime {
  /// Türkçe formatlı tarih (15 Ara 2025)
  String get formatTurkish {
    return DateFormat('dd MMM yyyy', 'tr_TR').format(this);
  }

  /// Kısa tarih (15.12.2025)
  String get formatShort {
    return DateFormat('dd.MM.yyyy').format(this);
  }

  /// Uzun tarih (15 Aralık 2025, Pazartesi)
  String get formatLong {
    return DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(this);
  }

  /// Saat formatı (14:30)
  String get formatTime {
    return DateFormat('HH:mm').format(this);
  }

  /// Tarih ve saat (15.12.2025 14:30)
  String get formatDateTime {
    return DateFormat('dd.MM.yyyy HH:mm').format(this);
  }

  /// Görece zaman (5 dakika önce, 2 saat önce, dün)
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Az önce';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dakika önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks hafta önce';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ay önce';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years yıl önce';
    }
  }

  /// Kısa görece zaman (5d, 2s, 3h)
  String get timeAgoShort {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}d';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}s';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}g';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}h';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}a';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y';
    }
  }

  /// Bugün mü?
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Dün mü?
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Bu hafta mı?
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek) && isBefore(endOfWeek);
  }

  /// Bu ay mı?
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Bu yıl mı?
  bool get isThisYear {
    final now = DateTime.now();
    return year == now.year;
  }

  /// Geçmiş mi?
  bool get isPast {
    return isBefore(DateTime.now());
  }

  /// Gelecek mi?
  bool get isFuture {
    return isAfter(DateTime.now());
  }

  /// Günün başlangıcı (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Günün sonu (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }

  /// Haftanın başlangıcı (Pazartesi)
  DateTime get startOfWeek {
    return subtract(Duration(days: weekday - 1)).startOfDay;
  }

  /// Haftanın sonu (Pazar)
  DateTime get endOfWeek {
    return add(Duration(days: 7 - weekday)).endOfDay;
  }

  /// Ayın başlangıcı
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  /// Ayın sonu
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59);
  }

  /// Yılın başlangıcı
  DateTime get startOfYear {
    return DateTime(year, 1, 1);
  }

  /// Yılın sonu
  DateTime get endOfYear {
    return DateTime(year, 12, 31, 23, 59, 59);
  }

  /// İki tarih arasındaki gün sayısı
  int daysBetween(DateTime other) {
    final from = DateTime(year, month, day);
    final to = DateTime(other.year, other.month, other.day);
    return (to.difference(from).inHours / 24).round();
  }

  /// Yaş hesapla
  int get age {
    final now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return age;
  }
}

/// Nullable DateTime için extension'lar
extension NullableDateTimeExtensions on DateTime? {
  /// Null ise varsayılan değer döndür
  DateTime orNow() => this ?? DateTime.now();

  /// Null değilse formatla
  String? formatOrNull(String format) {
    return this != null ? DateFormat(format).format(this!) : null;
  }
}
