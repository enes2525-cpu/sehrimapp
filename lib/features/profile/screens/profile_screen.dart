import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sehrimapp/data/models/user_model.dart';
import 'package:sehrimapp/services/firestore_service.dart';
import 'package:sehrimapp/services/auth_service.dart';
import 'package:sehrimapp/services/level_service.dart';
import 'package:sehrimapp/data/repositories/user_repository.dart';

// Ekranlar
import 'package:sehrimapp/features/auth/screens/login_screen.dart';
import 'package:sehrimapp/screens/my_ads/my_ads_screen.dart';
import 'package:sehrimapp/screens/favorites/favorites_screen.dart';
import 'package:sehrimapp/screens/token/token_wallet_screen.dart';
import 'package:sehrimapp/screens/shop/shop_management_screen.dart';
import 'package:sehrimapp/screens/referral/referral_screen.dart';

import 'package:sehrimapp/features/profile/screens/view_history_screen.dart';
import 'package:sehrimapp/features/profile/screens/ratings_list_screen.dart';
import 'package:sehrimapp/features/profile/screens/blocked_users_screen.dart';
import 'package:sehrimapp/features/profile/screens/report_screen.dart';

import 'package:sehrimapp/widgets/badge_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    // Günlük görev reset kontrolü
    await UserRepository().resetDailyTasksIfNeeded(userId);

    final user = await FirestoreService.getUser(userId);

    if (mounted) {
      setState(() {
        _user = user;
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Çıkış Yap"),
        content: const Text("Hesaptan çıkmak istiyor musunuz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text("İptal")),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text("Çıkış", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: const Text("Giriş Yap"),
          ),
        ),
      );
    }

    final user = _user!;

    final completion = user.profileCompletion.clamp(0, 100);
    final completionValue = completion / 100.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(user, completion, completionValue),
              const SizedBox(height: 16),

              _buildStatsCard(user),
              const SizedBox(height: 12),

              _buildDailyQuestCard(user),
              const SizedBox(height: 16),

              _buildMenuItems(user),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER (Avatar – XP – Level – Rank – Progress bar)
  // ---------------------------------------------------------------------------
  Widget _buildHeader(UserModel user, int completion, double completionValue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : "U",
                    style: const TextStyle(fontSize: 40),
                  )
                : null,
          ),
          const SizedBox(height: 12),

          Text(user.name,
              style: const TextStyle(fontSize: 22, color: Colors.white)),
          Text(user.email,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),

          const SizedBox(height: 12),

          // RANK
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Rank: ${user.rank} • Level ${user.level}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // XP BAR
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: (user.xp % 100) / 100,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor:
                  AlwaysStoppedAnimation(Colors.lightGreenAccent.shade100),
            ),
          ),

          const SizedBox(height: 8),
          Text("${user.xp} XP",
              style: const TextStyle(color: Colors.white70, fontSize: 12)),

          const SizedBox(height: 20),

          // Profil Tamamlanma
          Text("Profil Tamamlanma: %$completion",
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: completionValue,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(Colors.yellowAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // İSTATİSTIK KARTI
  // ---------------------------------------------------------------------------
  Widget _buildStatsCard(UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat("Takipçi", user.followerCount.toString()),
              _buildStat("Takip", user.followingCount.toString()),
              _buildStat("Profil Gör.", user.profileViews.toString()),
              _buildStat("İlan Gör.", user.totalAdViews.toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // GÜNLÜK GÖREV CARD
  // ---------------------------------------------------------------------------
  Widget _buildDailyQuestCard(UserModel user) {
    int progress = user.dailyTaskProgress;
    int max = 20;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        color: Colors.blue.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: const Text("Günlük Görevler",
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("İlerleme: $progress / $max"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Görev ekranı yakında eklenecek."),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MENÜ
  // ---------------------------------------------------------------------------
  Widget _buildMenuItems(UserModel user) {
    return Column(
      children: [
        _item(Icons.article, "İlanlarım", "Aktif ilanlar",
            () => _go(MyAdsScreen())),
        _item(Icons.favorite, "Favorilerim", "Beğendiğin ilanlar",
            () => _go(FavoritesScreen())),
        _item(Icons.account_balance_wallet, "Token Cüzdanım",
            "${user.tokenBalance} token", () => _go(TokenWalletScreen())),
        if (user.isBusinessAccount)
          _item(Icons.store, "Dükkanım", "İşletme yönetimi",
              () => _go(ShopManagementScreen())),
        _item(Icons.card_giftcard, "Arkadaşını Davet Et", "+50 token",
            () => _go(ReferralScreen())),

        const Divider(height: 30),

        _item(Icons.history, "Görüntüleme Geçmişim", "",
            () => _go(ViewHistoryScreen())),
        _item(Icons.star_rate_outlined, "Puanlarım", "",
            () => _go(RatingsListScreen())),
        _item(Icons.block, "Engellenen Kullanıcılar", "",
            () => _go(BlockedUsersScreen())),
        _item(Icons.report, "Şikayet / İhlal", "",
            () => _go(ReportScreen())),

        const Divider(height: 30),

        _item(Icons.settings, "Ayarlar", "", () {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Ayarlar yakında.")));
        }),
        _item(Icons.help, "Yardım & Destek", "", () {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Destek ekranı yakında.")));
        }),
        _item(Icons.logout, "Çıkış Yap", "", _signOut, color: Colors.red),
      ],
    );
  }

  Widget _item(IconData icon, String title, String subtitle, VoidCallback onTap,
      {Color? color}) {
    final c = color ?? Colors.blueGrey;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: c.withOpacity(.1),
        child: Icon(icon, color: c),
      ),
      title: Text(title,
          style: TextStyle(color: c, fontWeight: FontWeight.bold)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _go(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
