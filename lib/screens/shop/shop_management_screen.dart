import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehrimapp/data/models/business_model.dart';
import 'package:sehrimapp/screens/shop/create_shop_screen.dart';
import 'package:sehrimapp/screens/shop/shop_settings_screen.dart';
import 'package:sehrimapp/screens/shop/shop_ads_screen.dart';
import 'package:sehrimapp/screens/shop/shop_stats_screen.dart';

class ShopManagementScreen extends StatefulWidget {
  const ShopManagementScreen({Key? key}) : super(key: key);

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {
  BusinessModel? _business;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _business = BusinessModel.fromFirestore(doc);
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Dükkan yoksa oluşturma ekranı göster
    if (_business == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dükkanım'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store_outlined,
                size: 100,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Henüz dükkanınız yok',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dükkan oluşturarak işletmenizi tanıtın',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateShopScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadBusinessData();
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Dükkan Oluştur'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Dükkan varsa yönetim paneli göster
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dükkan Yönetimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShopSettingsScreen(business: _business!),
                ),
              );
              if (result == true) {
                _loadBusinessData();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dükkan Bilgileri
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(
                          Icons.store,
                          size: 40,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _business!.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _business!.category,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _business!.city,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_business!.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      _business!.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // İstatistikler
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.inventory,
                  'Aktif İlanlar',
                  '${_business!.totalAds}',
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  Icons.visibility,
                  'Görüntülenme',
                  '${_business!.totalViews}',
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  Icons.star,
                  'Puan',
                  _business!.rating.toStringAsFixed(1),
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  Icons.rate_review,
                  'Değerlendirme',
                  '${_business!.reviewCount}',
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Yönetim Menüsü
          const Text(
            'Yönetim',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // İlanlarım
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.blue),
              title: const Text('Dükkan İlanları'),
              subtitle: const Text('İlanları görüntüle ve yönet'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopAdsScreen(
                      businessId: _business!.id,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // İstatistikler
          Card(
            child: ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.green),
              title: const Text('İstatistikler'),
              subtitle: const Text('Detaylı istatistikleri görüntüle'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopStatsScreen(
                      business: _business!,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Mesajlar
          Card(
            child: ListTile(
              leading: const Icon(Icons.message, color: Colors.orange),
              title: const Text('Mesajlar'),
              subtitle: const Text('Müşteri mesajlarını görüntüle'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Mesajlar ekranına git
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mesajlar ekranı yakında')),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Ayarlar
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text('Dükkan Ayarları'),
              subtitle: const Text('Dükkan bilgilerini düzenle'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShopSettingsScreen(
                      business: _business!,
                    ),
                  ),
                );
                if (result == true) {
                  _loadBusinessData();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}