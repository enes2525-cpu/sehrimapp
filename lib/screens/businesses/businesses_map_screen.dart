import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import 'business_detail_screen.dart';

class BusinessesMapScreen extends StatefulWidget {
  final String? cityFilter;
  final String? categoryFilter;

  const BusinessesMapScreen({
    Key? key,
    this.cityFilter,
    this.categoryFilter,
  }) : super(key: key);

  @override
  State<BusinessesMapScreen> createState() => _BusinessesMapScreenState();
}

class _BusinessesMapScreenState extends State<BusinessesMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isMapView = true;
  bool _isLoadingLocation = false;
  String? _selectedCity;
  String? _selectedCategory;
  double _maxDistance = 50.0; // KM cinsinden maksimum mesafe

  final Set<Marker> _markers = {};
  List<DocumentSnapshot> _allBusinesses = [];
  List<DocumentSnapshot> _filteredBusinesses = [];
  
  // Erzurum koordinatları (varsayılan)
  final LatLng _defaultLocation = const LatLng(39.9334, 41.2769);

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

  final List<String> _categories = [
    'Tümü',
    'Berber',
    'Kuaför',
    'Tamirci',
    'Tesisatçı',
    'Elektrikçi',
    'Boyacı',
    'Market',
    'Pet Shop',
    'Kafe',
    'Restaurant',
    'Oto Tamirci',
    'Temizlik',
    'Nakliyat',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.cityFilter ?? 'Tümü';
    _selectedCategory = widget.categoryFilter ?? 'Tümü';
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoadingLocation = true;
    });

    final status = await Permission.location.request();
    
    if (status.isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        debugPrint('Konum alınamadı: $e');
      }
    }

    setState(() {
      _isLoadingLocation = false;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          12,
        ),
      );
    }
  }

  void _moveToCurrentLocation() async {
    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          14,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konum alınamadı')),
      );
    }
  }

  // Mesafe hesaplama (Haversine formülü)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Pi/180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  void _filterBusinessesByDistance() {
    if (_currentPosition == null || _allBusinesses.isEmpty) {
      setState(() {
        _filteredBusinesses = _allBusinesses;
      });
      return;
    }

    final filtered = _allBusinesses.where((business) {
      final data = business.data() as Map<String, dynamic>;
      final lat = data['latitude'];
      final lon = data['longitude'];

      if (lat == null || lon == null) return false;

      final distance = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lon,
      );

      return distance <= _maxDistance;
    }).toList();

    setState(() {
      _filteredBusinesses = filtered;
    });
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Berber':
      case 'Kuaför':
        return Icons.content_cut;
      case 'Tamirci':
      case 'Oto Tamirci':
        return Icons.build;
      case 'Tesisatçı':
        return Icons.plumbing;
      case 'Elektrikçi':
        return Icons.electrical_services;
      case 'Market':
        return Icons.shopping_cart;
      case 'Kafe':
      case 'Restaurant':
        return Icons.restaurant;
      case 'Pet Shop':
        return Icons.pets;
      default:
        return Icons.store;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dükkanlar'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
              });
            },
            tooltip: _isMapView ? 'Liste Görünümü' : 'Harita Görünümü',
          ),
          if (_isMapView && _currentPosition != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: _moveToCurrentLocation,
              tooltip: 'Konumuma Git',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtreler
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCity,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.location_city, size: 20),
                          items: _cities.map((String city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCity = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.category, size: 20),
                          items: _categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category, style: const TextStyle(fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                
                // KM Filtresi - YENİ!
                if (_currentPosition != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.near_me, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Maksimum Mesafe: ${_maxDistance.toInt()} KM',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_filteredBusinesses.length} dükkan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _maxDistance,
                          min: 1,
                          max: 50,
                          divisions: 49,
                          label: '${_maxDistance.toInt()} KM',
                          activeColor: Colors.blue.shade700,
                          onChanged: (value) {
                            setState(() {
                              _maxDistance = value;
                            });
                            _filterBusinessesByDistance();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Harita veya Liste
          Expanded(
            child: _isMapView ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getBusinessesQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final newBusinesses = snapshot.data!.docs;
          
          // Sadece veri değiştiyse güncelle
          if (_allBusinesses.length != newBusinesses.length ||
              !_areBusinessListsEqual(_allBusinesses, newBusinesses)) {
            Future.microtask(() {
              _allBusinesses = newBusinesses;
              _filterBusinessesByDistance();
              _updateMarkers(_filteredBusinesses);
            });
          }
        }

        return Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : _defaultLocation,
                zoom: 12,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomControlsEnabled: false,
              compassEnabled: true,
              rotateGesturesEnabled: true,
              scrollGesturesEnabled: true,
              tiltGesturesEnabled: true,
              zoomGesturesEnabled: true,
            ),
            if (_isLoadingLocation)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }

  bool _areBusinessListsEqual(List<DocumentSnapshot> list1, List<DocumentSnapshot> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  Widget _buildListView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getBusinessesQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          final newBusinesses = snapshot.data!.docs;
          
          // Sadece veri değiştiyse güncelle
          if (_allBusinesses.length != newBusinesses.length ||
              !_areBusinessListsEqual(_allBusinesses, newBusinesses)) {
            Future.microtask(() {
              _allBusinesses = newBusinesses;
              _filterBusinessesByDistance();
            });
          }
        }

        if (_filteredBusinesses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'Dükkan bulunamadı',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                if (_currentPosition != null && _maxDistance < 50) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _maxDistance = 50;
                      });
                      _filterBusinessesByDistance();
                    },
                    child: const Text('Mesafe filtresini genişlet'),
                  ),
                ],
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _filteredBusinesses.length,
          itemBuilder: (context, index) {
            final business = _filteredBusinesses[index];
            final data = business.data() as Map<String, dynamic>;
            
            double? distance;
            if (_currentPosition != null && 
                data['latitude'] != null && 
                data['longitude'] != null) {
              distance = _calculateDistance(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                data['latitude'],
                data['longitude'],
              );
            }
            
            return _buildBusinessCard(business.id, data, distance);
          },
        );
      },
    );
  }

  Widget _buildBusinessCard(String businessId, Map<String, dynamic> data, double? distance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusinessDetailScreen(businessId: businessId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(data['businessCategory'] ?? ''),
                  color: Colors.blue.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['businessName'] ?? 'Dükkan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            data['businessCategory'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                        if (distance != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.near_me, size: 12, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  '${distance.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data['businessCity'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Query _getBusinessesQuery() {
    Query query = FirebaseFirestore.instance
        .collection('businesses')
        .where('isActive', isEqualTo: true);

    if (_selectedCity != null && _selectedCity != 'Tümü') {
      query = query.where('businessCity', isEqualTo: _selectedCity);
    }

    if (_selectedCategory != null && _selectedCategory != 'Tümü') {
      query = query.where('businessCategory', isEqualTo: _selectedCategory);
    }

    // Performans için limit
    query = query.limit(100);

    return query;
  }

  void _updateMarkers(List<DocumentSnapshot> businesses) {
    final newMarkers = <Marker>{};

    for (var business in businesses) {
      final data = business.data() as Map<String, dynamic>;
      final lat = data['latitude'];
      final lon = data['longitude'];
      
      if (lat != null && lon != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId(business.id),
            position: LatLng(lat, lon),
            infoWindow: InfoWindow(
              title: data['businessName'] ?? 'Dükkan',
              snippet: data['businessCategory'] ?? '',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BusinessDetailScreen(businessId: business.id),
                  ),
                );
              },
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    }

    if (newMarkers.length != _markers.length) {
      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}