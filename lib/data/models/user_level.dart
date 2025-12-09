import 'package:cloud_firestore/cloud_firestore.dart';

/// Level Sistemi Modeli
class UserLevel {
  final int level;
  final int currentXP;
  final int requiredXP;
  final String levelTitle;
  final List<String> unlockedFeatures;
  final int dailyAdLimit;
  final DateTime lastUpdated;

  UserLevel({
    required this.level,
    required this.currentXP,
    required this.requiredXP,
    required this.levelTitle,
    required this.unlockedFeatures,
    required this.dailyAdLimit,
    required this.lastUpdated,
  });

  // Level'e göre başlık
  static String getLevelTitle(int level) {
    switch (level) {
      case 1:
        return 'Yeni Kullanıcı';
      case 2:
        return 'Aktif Kullanıcı';
      case 3:
        return 'Düzenli Kullanıcı';
      case 4:
        return 'VIP Kullanıcı';
      case 5:
        return 'Elit Kullanıcı';
      default:
        return 'Efsane Kullanıcı';
    }
  }

  // Level'e göre gerekli XP
  static int getRequiredXP(int level) {
    switch (level) {
      case 1:
        return 100;
      case 2:
        return 300;
      case 3:
        return 600;
      case 4:
        return 1000;
      case 5:
        return 1500;
      default:
        return level * 500;
    }
  }

  // Level'e göre günlük reklam limiti
  static int getDailyAdLimit(int level) {
    switch (level) {
      case 1:
        return 5; // Yeni kullanıcı: max 5 reklam
      case 2:
        return 4;
      case 3:
        return 3;
      case 4:
        return 2;
      case 5:
        return 1;
      default:
        return 0; // Level 6+: Reklamsız!
    }
  }

  // Level'e göre açılan özellikler
  static List<String> getUnlockedFeatures(int level) {
    final features = <String>[];
    
    if (level >= 1) features.addAll(['basic_features', 'create_ads']);
    if (level >= 2) features.addAll(['showcase', 'community']);
    if (level >= 3) features.addAll(['statistics', 'highlight']);
    if (level >= 4) features.addAll(['premium_showcase', 'priority_support']);
    if (level >= 5) features.addAll(['custom_badge', 'unlimited_showcase']);
    if (level >= 6) features.addAll(['ad_free', 'exclusive_features']);
    
    return features;
  }

  // Progress yüzdesi
  double get progressPercentage {
    return (currentXP / requiredXP * 100).clamp(0.0, 100.0);
  }

  // Firestore'dan çek
  factory UserLevel.fromMap(Map<String, dynamic> data) {
    final level = data['level'] ?? 1;
    return UserLevel(
      level: level,
      currentXP: data['currentXP'] ?? 0,
      requiredXP: getRequiredXP(level),
      levelTitle: getLevelTitle(level),
      unlockedFeatures: List<String>.from(data['unlockedFeatures'] ?? []),
      dailyAdLimit: getDailyAdLimit(level),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firestore'a kaydet
  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'currentXP': currentXP,
      'requiredXP': requiredXP,
      'levelTitle': levelTitle,
      'unlockedFeatures': unlockedFeatures,
      'dailyAdLimit': dailyAdLimit,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Level atla
  UserLevel levelUp() {
    final newLevel = level + 1;
    final remainingXP = currentXP - requiredXP;
    
    return UserLevel(
      level: newLevel,
      currentXP: remainingXP > 0 ? remainingXP : 0,
      requiredXP: getRequiredXP(newLevel),
      levelTitle: getLevelTitle(newLevel),
      unlockedFeatures: getUnlockedFeatures(newLevel),
      dailyAdLimit: getDailyAdLimit(newLevel),
      lastUpdated: DateTime.now(),
    );
  }

  // XP ekle
  UserLevel addXP(int xp) {
    final newXP = currentXP + xp;
    
    // Level atlamayı kontrol et
    if (newXP >= requiredXP) {
      return levelUp().addXP(0); // Recursive level up
    }
    
    return UserLevel(
      level: level,
      currentXP: newXP,
      requiredXP: requiredXP,
      levelTitle: levelTitle,
      unlockedFeatures: unlockedFeatures,
      dailyAdLimit: dailyAdLimit,
      lastUpdated: DateTime.now(),
    );
  }
}

/// XP Kazanma Aktiviteleri
class XPActivity {
  static const int createAd = 5;
  static const int completeProfile = 10;
  static const int firstSale = 20;
  static const int watchAd = 2;
  static const int dailyQuest = 10;
  static const int useSACode = 5;
  static const int receiveRating = 3;
  static const int get10Followers = 20;
  static const int openShowcase = 3;
  static const int sendMessage = 1;
  static const int sharePost = 5;
  static const int likePost = 1;
  static const int commentPost = 2;
  static const int profileView100 = 15;
  static const int firstAppointment = 10;
}
