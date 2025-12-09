import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sehrimapp/data/models/user_model.dart';
import 'package:sehrimapp/services/firestore_service.dart';
import 'package:sehrimapp/services/auth_service.dart';

// 🔥 YENİ DOĞRU LOGIN EKRANI KONUMU
import 'package:sehrimapp/features/auth/screens/login_screen.dart';

// DİĞER EKRANLAR
import 'package:sehrimapp/screens/my_ads/my_ads_screen.dart';
import 'package:sehrimapp/screens/favorites/favorites_screen.dart';
import 'package:sehrimapp/screens/token/token_wallet_screen.dart';
import 'package:sehrimapp/screens/shop/shop_management_screen.dart';
import 'package:sehrimapp/screens/referral/referral_screen.dart';

// Günlük görevler
import 'package:sehrimapp/features/quests/screens/daily_quests_screen.dart';

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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final user = await FirestoreService.getUser(userId);
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Çıkmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        // 🔥 HATALI ÇIKIŞ EKRANI DÜZELTİLDİ → Artık doğru login ekranı açılır
        Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Kullanıcı bilgisi yüklenemedi'),
              const SizedBox(height: 24),
              ElevatedButton(
                child: const Text("Giriş Yap"),
                onPressed: () {
                  Navigator.pushNamed(context, "/login");
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ████████████ PROFIL HEADER ████████████
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: _buildAvatar(),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      _user!.name,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _user!.email,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ███████████ MENÜLER ███████████
              _buildMenuItem(
                icon: Icons.article,
                title: "İlanlarım",
                subtitle: "${_user!.totalAds} aktif ilan",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyAdsScreen()),
                ),
              ),

              _buildMenuItem(
                icon: Icons.favorite,
                title: "Favorilerim",
                subtitle: "Beğendiğin ilanlar",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
              ),

              _buildMenuItem(
                icon: Icons.monetization_on,
                title: "Token Cüzdanım",
                subtitle: "${_user!.tokenBalance} token",
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TokenWalletScreen()),
                ),
              ),

              _buildMenuItem(
                icon: Icons.local_activity,
                title: "Günlük Görevler",
                subtitle: "XP & Token kazan",
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyQuestsScreen()),
                  );
                },
              ),

              if (_user!.isBusinessAccount)
                _buildMenuItem(
                  icon: Icons.store,
                  title: "Dükkanım",
                  subtitle: "İşletme yönetimi",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ShopManagementScreen()),
                    );
                  },
                ),

              _buildMenuItem(
                icon: Icons.card_giftcard,
                title: "Arkadaşını Davet Et",
                subtitle: "50 token kazan!",
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReferralScreen()),
                  );
                },
              ),

              const Divider(),

              _buildMenuItem(
                icon: Icons.settings,
                title: "Ayarlar",
                subtitle: "Hesap ayarları",
                onTap: () {},
              ),

              _buildMenuItem(
                icon: Icons.help,
                title: "Yardım & Destek",
                subtitle: "SSS ve iletişim",
                onTap: () {},
              ),

              _buildMenuItem(
                icon: Icons.logout,
                title: "Çıkış Yap",
                subtitle: "Hesaptan çık",
                color: Colors.red,
                onTap: _signOut,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ████████████████████ AVATAR BUILDER ████████████████████
  Widget _buildAvatar() {
    final url = _user!.photoUrl;

    if (url == null || url.isEmpty) {
      return Text(
        _user!.name[0].toUpperCase(),
        style: TextStyle(
          fontSize: 40,
          color: Theme.of(context).primaryColor,
        ),
      );
    }

    if (url.startsWith("http")) {
      return ClipOval(
        child: Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
      );
    }

    return ClipOval(
      child: Image.file(
        File(url),
        width: 100,
        height: 100,
        fit: BoxFit.cover,
      ),
    );
  }

  // ████████████████████ MENU ITEM ████████████████████
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? Colors.blue).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? Colors.blue),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
