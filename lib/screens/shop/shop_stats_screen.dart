import 'package:flutter/material.dart';
import 'package:sehrimapp/data/models/business_model.dart';

class ShopStatsScreen extends StatelessWidget {
  final BusinessModel business;

  const ShopStatsScreen({Key? key, required this.business}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistikler'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Genel İstatistikler
          const Text(
            'Genel İstatistikler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildStatCard(
            Icons.inventory,
            'Toplam İlan',
            '${business.totalAds}',
            Colors.blue,
          ),
          const SizedBox(height: 12),

          _buildStatCard(
            Icons.visibility,
            'Toplam Görüntülenme',
            '${business.totalViews}',
            Colors.green,
          ),
          const SizedBox(height: 12),

          _buildStatCard(
            Icons.star,
            'Ortalama Puan',
            business.rating.toStringAsFixed(1),
            Colors.orange,
          ),
          const SizedBox(height: 12),

          _buildStatCard(
            Icons.rate_review,
            'Değerlendirme Sayısı',
            '${business.reviewCount}',
            Colors.purple,
          ),
          const SizedBox(height: 24),

          // Performans
          const Text(
            'Performans',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('İlan Başına Görüntülenme'),
                      Text(
                        business.totalAds > 0
                            ? (business.totalViews / business.totalAds)
                                .toStringAsFixed(1)
                            : '0',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Aktif İlan Oranı'),
                      Text(
                        '%100',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bilgi Notları
          Card(
            color: Colors.blue.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'İpuçları',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Düzenli olarak yeni ilan ekleyin\n'
                    '• İlan başlıklarını çekici yapın\n'
                    '• Kaliteli fotoğraflar kullanın\n'
                    '• Müşteri mesajlarına hızlı cevap verin',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}