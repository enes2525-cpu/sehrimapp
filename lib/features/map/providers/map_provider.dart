import 'package:flutter/foundation.dart';
import '../../../data/models/shop_model.dart';
import '../../../data/repositories/shop_repository.dart';

class MapProvider with ChangeNotifier {
  final ShopRepository _shopRepo = ShopRepository();

  List<ShopModel> _nearbyShops = [];
  bool _isLoading = false;
  String? _error;
  double _currentRadius = 5.0;

  List<ShopModel> get nearbyShops => _nearbyShops;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get currentRadius => _currentRadius;

  Future<void> loadNearbyShops({
    required double latitude,
    required double longitude,
    required double radiusInKm,
  }) async {
    _isLoading = true;
    _currentRadius = radiusInKm;
    notifyListeners();

    final result = await _shopRepo.getNearbyShops(latitude, longitude, radiusInKm);

    if (result.isSuccess) {
      _nearbyShops = result.data!;
      _error = null;
    } else {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
  }
}
