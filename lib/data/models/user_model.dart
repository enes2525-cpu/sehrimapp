import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? photoUrl;
  final String? city;
  final String? district;

  final bool isBusinessAccount;

  final int tokenBalance;
  final int totalAds;
  final int totalSales;

  final double rating;
  final int reviewCount;

  final int followerCount;
  final int followingCount;
  final int totalRatings;

  final List<String> badges;

  final DateTime createdAt;
  final DateTime lastActive;

  // ---------- İstatistik alanları ----------
  final int profileViews;
  final int totalAdViews;
  final int profileCompletion;
  final int popularityScore;

  // ---------- Level & XP & Görev sistemi ----------
  final int xp;
  final int level;
  final int dailyTaskProgress;
  final DateTime? lastDailyReset;
  final String rank;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.photoUrl,
    this.city,
    this.district,
    this.isBusinessAccount = false,
    this.tokenBalance = 100,
    this.totalAds = 0,
    this.totalSales = 0,
    this.rating = 5.0,
    this.reviewCount = 0,
    this.followerCount = 0,
    this.followingCount = 0,
    this.totalRatings = 0,
    List<String>? badges,
    DateTime? createdAt,
    DateTime? lastActive,

    // İstatistik
    this.profileViews = 0,
    this.totalAdViews = 0,
    this.profileCompletion = 40,
    this.popularityScore = 0,

    // Level & XP
    this.xp = 0,
    this.level = 1,
    this.dailyTaskProgress = 0,
    this.lastDailyReset,
    this.rank = "Bronz",
  })  : badges = badges ?? [],
        createdAt = createdAt ?? DateTime.now(),
        lastActive = lastActive ?? DateTime.now();

  // ---------- Firestore'dan veri okuma ----------
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      photoUrl: data['photoUrl'],
      city: data['city'],
      district: data['district'],
      isBusinessAccount: data['isBusinessAccount'] ?? false,
      tokenBalance: data['tokenBalance'] ?? 100,
      totalAds: data['totalAds'] ?? 0,
      totalSales: data['totalSales'] ?? 0,
      rating: (data['rating'] ?? 5.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      followerCount: data['followerCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      totalRatings: data['totalRatings'] ?? 0,
      badges: data['badges'] != null ? List<String>.from(data['badges']) : [],

      profileViews: data['profileViews'] ?? 0,
      totalAdViews: data['totalAdViews'] ?? 0,
      profileCompletion: data['profileCompletion'] ?? 40,
      popularityScore: data['popularityScore'] ?? 0,

      xp: data['xp'] ?? 0,
      level: data['level'] ?? 1,
      dailyTaskProgress: data['dailyTaskProgress'] ?? 0,
      lastDailyReset: (data['lastDailyReset'] as Timestamp?)?.toDate(),
      rank: data['rank'] ?? "Bronz",

      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ---------- Firestore'a yazma ----------
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'city': city,
      'district': district,
      'isBusinessAccount': isBusinessAccount,
      'tokenBalance': tokenBalance,
      'totalAds': totalAds,
      'totalSales': totalSales,
      'rating': rating,
      'reviewCount': reviewCount,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'totalRatings': totalRatings,
      'badges': badges,

      'profileViews': profileViews,
      'totalAdViews': totalAdViews,
      'profileCompletion': profileCompletion,
      'popularityScore': popularityScore,

      'xp': xp,
      'level': level,
      'dailyTaskProgress': dailyTaskProgress,
      'lastDailyReset':
          lastDailyReset != null ? Timestamp.fromDate(lastDailyReset!) : null,
      'rank': rank,

      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': FieldValue.serverTimestamp(),
    };
  }

  // ---------- CopyWith ----------
  UserModel copyWith({
    String? name,
    String? phone,
    String? photoUrl,
    String? city,
    String? district,
    int? tokenBalance,
    int? profileViews,
    int? totalAdViews,
    int? profileCompletion,
    int? popularityScore,
    int? xp,
    int? level,
    int? dailyTaskProgress,
    DateTime? lastDailyReset,
    String? rank,
    List<String>? badges,
    int? followerCount,
    int? followingCount,
    DateTime? lastActive,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      city: city ?? this.city,
      district: district ?? this.district,
      isBusinessAccount: isBusinessAccount,
      tokenBalance: tokenBalance ?? this.tokenBalance,
      totalAds: totalAds,
      totalSales: totalSales,
      rating: rating,
      reviewCount: reviewCount,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      totalRatings: totalRatings,
      badges: badges ?? this.badges,

      profileViews: profileViews ?? this.profileViews,
      totalAdViews: totalAdViews ?? this.totalAdViews,
      profileCompletion: profileCompletion ?? this.profileCompletion,
      popularityScore: popularityScore ?? this.popularityScore,

      xp: xp ?? this.xp,
      level: level ?? this.level,
      dailyTaskProgress: dailyTaskProgress ?? this.dailyTaskProgress,
      lastDailyReset: lastDailyReset ?? this.lastDailyReset,
      rank: rank ?? this.rank,

      createdAt: createdAt,
      lastActive: lastActive ?? DateTime.now(),
    );
  }
}
