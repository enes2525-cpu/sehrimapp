import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';
import '../../../core/constants/app_constants.dart';

/// İlan Listesi Screen (Provider ile)
/// Örnek: Repository -> Provider -> UI akışı
class AdsListScreenExample extends StatefulWidget {
  const AdsListScreenExample({super.key});

  @override
  State<AdsListScreenExample> createState() => _AdsListScreenExampleState();
}

class _AdsListScreenExampleState extends State<AdsListScreenExample> {
  @override
  void initState() {
    super.initState();
    // Provider'dan ilanları yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdProvider>().loadAds();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlanlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Consumer<AdProvider>(
        builder: (context, adProvider, child) {
          // Loading durumu
          if (adProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Hata durumu
          if (adProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Hata: ${adProvider.error}'),
                  ElevatedButton(
                    onPressed: () => adProvider.loadAds(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          // İlan listesi
          final ads = adProvider.ads;

          if (ads.isEmpty) {
            return const Center(
              child: Text('Henüz ilan yok'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: ad.mainImage != null
                      ? Image.network(
                          ad.mainImage!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image),
                        ),
                  title: Text(ad.title),
                  subtitle: Text('${ad.price} ₺'),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                    onPressed: () async {
                      // Favoriye ekle/çıkar (Token kontrolü otomatik!)
                      final success = await adProvider.toggleFavorite(ad.id);
                      
                      if (!success && adProvider.error != null) {
                        // Token yetersizse hata göster
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(adProvider.error!)),
                        );
                      }
                    },
                  ),
                  onTap: () {
                    // İlan detayına git
                    // Navigator.push(...)
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Filtre Dialog
  void _showFilterDialog(BuildContext context) {
    final adProvider = context.read<AdProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrele'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Kategori seçimi
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Kategori'),
              value: adProvider.selectedCategory,
              items: AppConstants.categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) {
                adProvider.setCategory(value);
              },
            ),
            const SizedBox(height: 16),

            // Şehir seçimi
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Şehir'),
              value: adProvider.selectedCity,
              items: AppConstants.cities.map((city) {
                return DropdownMenuItem(value: city, child: Text(city));
              }).toList(),
              onChanged: (value) {
                adProvider.setCity(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              adProvider.clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );
  }
}
