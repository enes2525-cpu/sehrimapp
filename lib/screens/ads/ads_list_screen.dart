import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sehrimapp/screens/ads/ad_detail_screen.dart';

class AdsListScreen extends StatefulWidget {
  final String categoryName;
  final Color categoryColor;

  const AdsListScreen({
    Key? key,
    required this.categoryName,
    required this.categoryColor,
  }) : super(key: key);

  @override
  State<AdsListScreen> createState() => _AdsListScreenState();
}

class _AdsListScreenState extends State<AdsListScreen> {
  String _selectedCity = 'Tümü';

  final List<String> _cities = [
    'Tümü',
    'Erzurum',
    'İstanbul',
    'Ankara',
    'İzmir',
    'Bursa',
    'Antalya',
    'Adana',
    'Gaziantep',
    'Konya',
    'Kayseri',
    'Trabzon',
    'Diyarbakır'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: widget.categoryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 🔹 Şehir filtresi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.grey.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCity,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: _cities.map((String city) {
                      return DropdownMenuItem<String>(
                        value: city,
                        child: Text(city),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCity = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // 🔹 İlan listesi
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getAdsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Bu kategoride henüz ilan yok',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final ad = snapshot.data!.docs[index];
                    return _buildAdCard(ad);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Firestore sorgusu
  Stream<QuerySnapshot> _getAdsStream() {
    Query query = FirebaseFirestore.instance
        .collection('ads')
        .where('category', isEqualTo: widget.categoryName)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true);

    if (_selectedCity != 'Tümü') {
      query = query.where('city', isEqualTo: _selectedCity);
    }

    return query.snapshots();
  }

  // 🔥 YENİ AD KARTI (Fotoğraflı + Overflow yok + Şık tasarım)
  Widget _buildAdCard(DocumentSnapshot ad) {
    final data = ad.data() as Map<String, dynamic>;
    final String? image = data['mainImage']; // kapak fotoğrafı
    final int views = data['viewCount'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdDetailScreen(adId: ad.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- FOTOĞRAF ----------
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: image == null || image.isEmpty
                    ? Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported,
                            size: 60, color: Colors.grey),
                      )
                    : (image.startsWith("http")
                        ? Image.network(image, fit: BoxFit.cover)
                        : Image.file(File(image), fit: BoxFit.cover)),
              ),
            ),

            // ---------- METİN BÖLÜMÜ ----------
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık + Fiyat
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['title'] ?? 'Başlıksız',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${data['price']} ₺",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.categoryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Açıklama
                  Text(
                    data['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade700),
                  ),

                  const SizedBox(height: 10),

                  // Alt bilgiler
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        data['city'] ?? '',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const Spacer(),
                      Icon(Icons.visibility,
                          size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        views.toString(),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
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
