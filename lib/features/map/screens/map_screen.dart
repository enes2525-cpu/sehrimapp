import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../../../data/models/shop_model.dart';

/// Harita Screen - Yakındaki işletmeleri gösterir
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Konum izni al ve konumu getir
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });

      // Yakındaki işletmeleri yükle
      context.read<MapProvider>().loadNearbyShops(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusInKm: 5,
      );

      // Haritayı konuma odakla
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    } catch (e) {
      print('Konum alınamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakındaki İşletmeler'),
        actions: [
          // Yarıçap seçimi
          PopupMenuButton<int>(
            icon: const Icon(Icons.tune),
            onSelected: (radius) {
              if (_currentPosition != null) {
                context.read<MapProvider>().loadNearbyShops(
                  latitude: _currentPosition!.latitude,
                  longitude: _currentPosition!.longitude,
                  radiusInKm: radius,
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text('1 km çevresinde')),
              const PopupMenuItem(value: 3, child: Text('3 km çevresinde')),
              const PopupMenuItem(value: 5, child: Text('5 km çevresinde')),
              const PopupMenuItem(value: 10, child: Text('10 km çevresinde')),
            ],
          ),
        ],
      ),
      body: Consumer<MapProvider>(
        builder: (context, mapProvider, child) {
          if (mapProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final nearbyShops = mapProvider.nearbyShops;
          final markers = _buildMarkers(nearbyShops);

          return Stack(
            children: [
              // Google Maps
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition != null
                      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                      : const LatLng(41.0082, 28.9784), // İstanbul
                  zoom: 14,
                ),
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
              ),

              // İşletme listesi (Alt tarafta)
              DraggableScrollableSheet(
                initialChildSize: 0.3,
                minChildSize: 0.1,
                maxChildSize: 0.7,
                builder: (context, scrollController) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Drag handle
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        // Liste başlığı
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${nearbyShops.length} İşletme Bulundu',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (nearbyShops.isNotEmpty)
                                Text(
                                  '${mapProvider.currentRadius.toStringAsFixed(0)} km',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // İşletme listesi
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: nearbyShops.length,
                            itemBuilder: (context, index) {
                              final shop = nearbyShops[index];
                              return _ShopListItem(
                                shop: shop,
                                onTap: () {
                                  // Haritayı işletmeye odakla
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                      LatLng(
                                        shop.location?.latitude ?? 0,
                                        shop.location?.longitude ?? 0,
                                      ),
                                      16,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  // Marker'ları oluştur
  Set<Marker> _buildMarkers(List<ShopModel> shops) {
    final markers = <Marker>{};

    // Kendi konumun
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('my_location'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Konumum'),
        ),
      );
    }

    // İşletme marker'ları
    for (var shop in shops) {
      if (shop.location != null) {
        markers.add(
          Marker(
            markerId: MarkerId(shop.id),
            position: LatLng(
              shop.location!.latitude,
              shop.location!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: shop.name,
              snippet: shop.categories.isNotEmpty ? shop.categories.first : '',
            ),
            onTap: () {
              _showShopBottomSheet(shop);
            },
          ),
        );
      }
    }

    return markers;
  }

  // İşletme detay bottom sheet
  void _showShopBottomSheet(ShopModel shop) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shop.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (shop.description != null)
              Text(shop.description!),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text('${shop.rating?.toStringAsFixed(1) ?? 'N/A'}'),
                const SizedBox(width: 16),
                const Icon(Icons.people, size: 20),
                const SizedBox(width: 4),
                Text('${shop.followerCount ?? 0} takipçi'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // İşletme profiline git
                  // Navigator.push(context, ShopProfileScreen(shop));
                },
                child: const Text('Profili Görüntüle'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// İşletme liste item widget'ı
class _ShopListItem extends StatelessWidget {
  final ShopModel shop;
  final VoidCallback onTap;

  const _ShopListItem({
    required this.shop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: shop.coverImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  shop.coverImage!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store),
              ),
        title: Text(shop.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (shop.categories.isNotEmpty)
              Text(shop.categories.first),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${shop.rating?.toStringAsFixed(1) ?? 'N/A'}'),
                const SizedBox(width: 8),
                if (shop.distance != null)
                  Text('${shop.distance!.toStringAsFixed(1)} km'),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
