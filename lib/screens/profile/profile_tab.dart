import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehrimapp/data/models/user_model.dart';

// Screens
import 'package:sehrimapp/screens/my_ads/my_ads_screen.dart';
import 'package:sehrimapp/screens/favorites/favorites_screen.dart';
import 'package:sehrimapp/screens/appointments/appointments_screen.dart';
import 'package:sehrimapp/screens/shop/shop_management_screen.dart';
import 'package:sehrimapp/screens/profile/edit_profile_screen.dart';
import 'package:sehrimapp/screens/auth/login_screen.dart';
import 'package:sehrimapp/screens/token/token_wallet_screen.dart';
import 'package:sehrimapp/screens/conversations/conversations_screen.dart';

// NEW — Daily Quests Screen
import 'package:sehrimapp/features/quests/screens/daily_quests_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  UserModel? _userModel;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _userModel = UserModel.fromFirestore(doc);
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_outline, size: 100, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Giriş yapmanız gerekiyor', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Giriş Yap'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: ListView(
        children: [
          // ----------- PREMIUM DAILY QUEST CARD (NEW) -----------
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DailyQuestsScreen()),
              );
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4FF), Color(0xFF0077FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_activity, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Günlük Görevler",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "XP + Token kazanmak için görevleri tamamla!",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ---------------- PROFILE HEADER ----------------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: _userModel?.photoUrl != null
                      ? (_userModel!.photoUrl!.startsWith('/')
                          ? Image.file(File(_userModel!.photoUrl!), fit: BoxFit.cover)
                          : Image.network(_userModel!.photoUrl!, fit: BoxFit.cover))
                      : const Icon(Icons.person, size: 50, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Text(
                  _userModel?.name ?? user.email ?? 'Kullanıcı',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(user.email ?? '', style: const TextStyle(color: Colors.white70)),
                if (_userModel?.city != null) ...[
                  const SizedBox(height: 4),
                  Text(_userModel!.city!, style: const TextStyle(color: Colors.white70)),
                ],
                if (_userModel?.isBusinessAccount ?? false) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("İşletme Hesabı",
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
              ],
            ),
          ),

          // ---------------- STATS ----------------
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(Icons.inventory, 'İlanlar', '${_userModel?.totalAds ?? 0}'),
                _buildStatItem(Icons.favorite, 'Favoriler', '0'),
                _buildStatItem(Icons.star, 'Puan', '5.0'),
              ],
            ),
          ),

          const Divider(),

          // ---------------- MENU ITEMS ----------------
          _tile(Icons.edit, "Profil Düzenle", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()));
          }),

          _tile(Icons.monetization_on, "Token Cüzdanı", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const TokenWalletScreen()));
          }),

          _tile(Icons.message, "Mesajlarım", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ConversationsScreen()));
          }),

          _tile(Icons.inventory_2, "İlanlarım", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const MyAdsScreen()));
          }),

          _tile(Icons.favorite, "Favorilerim", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()));
          }),

          _tile(Icons.calendar_today, "Randevularım", () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AppointmentsScreen()));
          }),

          if (_userModel?.isBusinessAccount ?? false)
            _tile(Icons.store, "Dükkanım", () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ShopManagementScreen()));
            }),

          const Divider(),

          _tile(Icons.settings, "Ayarlar", () {}),

          _tile(Icons.help, "Yardım", () {}),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Çıkış Yap", style: TextStyle(color: Colors.red)),
            onTap: () async {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  ListTile _tile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
