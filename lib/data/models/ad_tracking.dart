import 'package:cloud_firestore/cloud_firestore.dart';

/// Reklam Türü
enum AdType {
  banner,           // Banner reklam
  interstitial,     // Tam ekran reklam (açılış)
  rewarded,         // Ödüllü reklam
  native,           // Native reklam (feed içinde)
}

/// Reklam Görüntüleme Kaydı
class AdView {
  final String id;
  final String userId;
  final AdType adType;
  final String placement; // Nerede gösterildi (home, quest, shop_profile)
  final DateTime viewedAt;
  final bool wasRewarded; // Ödül verildi mi?
  final int rewardAmount; // Token/XP miktarı

  AdView({
    required this.id,
    required this.userId,
    required this.adType,
    required this.placement,
    required this.viewedAt,
    this.wasRewarded = false,
    this.rewardAmount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'adType': adType.name,
      'placement': placement,
      'viewedAt': Timestamp.fromDate(viewedAt),
      'wasRewarded': wasRewarded,
      'rewardAmount': rewardAmount,
    };
  }

  factory AdView.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdView(
      id: doc.id,
      userId: data['userId'] ?? '',
      adType: AdType.values.firstWhere(
        (e) => e.name == data['adType'],
        orElse: () => AdType.banner,
      ),
      placement: data['placement'] ?? '',
      viewedAt: (data['viewedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      wasRewarded: data['wasRewarded'] ?? false,
      rewardAmount: data['rewardAmount'] ?? 0,
    );
  }
}

/// Kullanıcının Günlük Reklam Limiti
class DailyAdLimit {
  final String userId;
  final DateTime date;
  final int viewedCount;
  final int maxLimit; // Level'e göre belirlenir
  final Map<AdType, int> viewsByType;

  DailyAdLimit({
    required this.userId,
    required this.date,
    required this.viewedCount,
    required this.maxLimit,
    required this.viewsByType,
  });

  // Limit doldu mu?
  bool get isLimitReached => viewedCount >= maxLimit;

  // Kalan reklam sayısı
  int get remaining => (maxLimit - viewedCount).clamp(0, maxLimit);

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'viewedCount': viewedCount,
      'maxLimit': maxLimit,
      'viewsByType': viewsByType.map((k, v) => MapEntry(k.name, v)),
    };
  }

  factory DailyAdLimit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final viewsByTypeData = data['viewsByType'] as Map<String, dynamic>? ?? {};
    
    return DailyAdLimit(
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewedCount: data['viewedCount'] ?? 0,
      maxLimit: data['maxLimit'] ?? 5,
      viewsByType: viewsByTypeData.map(
        (k, v) => MapEntry(
          AdType.values.firstWhere((e) => e.name == k, orElse: () => AdType.banner),
          v as int,
        ),
      ),
    );
  }

  // Yeni görüntüleme ekle
  DailyAdLimit addView(AdType type) {
    final newViewsByType = Map<AdType, int>.from(viewsByType);
    newViewsByType[type] = (newViewsByType[type] ?? 0) + 1;
    
    return DailyAdLimit(
      userId: userId,
      date: date,
      viewedCount: viewedCount + 1,
      maxLimit: maxLimit,
      viewsByType: newViewsByType,
    );
  }

  // Yeni gün için sıfırla
  static DailyAdLimit createNew(String userId, int maxLimit) {
    final now = DateTime.now();
    final dateOnly = DateTime(now.year, now.month, now.day);
    
    return DailyAdLimit(
      userId: userId,
      date: dateOnly,
      viewedCount: 0,
      maxLimit: maxLimit,
      viewsByType: {},
    );
  }
}

/// Reklam Yerleşimleri (Placement)
class AdPlacement {
  static const String home = 'home';
  static const String feed = 'feed';
  static const String shopProfile = 'shop_profile';
  static const String chat = 'chat';
  static const String quest = 'quest';
  static const String showcase = 'showcase';
  static const String search = 'search';
  static const String appOpen = 'app_open';
}

/// Reklam Stratejisi
class AdStrategy {
  // Banner reklamlar - Her X içerikte 1
  static const int bannerFrequencyInFeed = 5; // Her 5 içerikte 1
  static const int bannerFrequencyInChat = 8; // Her 8 sohbette 1

  // Açılış reklamı - Her X açılışta 1
  static const int interstitialFrequency = 3; // Her 3 açılışta 1

  // Ödüllü reklam - Seçimli
  static const int rewardedTokenAmount = 5; // 5 token
  static const int rewardedXPAmount = 2; // 2 XP

  // Level bazlı günlük limit
  static int getDailyLimit(int level) {
    switch (level) {
      case 1:
        return 5;
      case 2:
        return 4;
      case 3:
        return 3;
      case 4:
        return 2;
      case 5:
        return 1;
      default:
        return 0; // Level 6+: Reklamsız
    }
  }
}
