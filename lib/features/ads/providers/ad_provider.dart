import 'package:flutter/foundation.dart';
import '../../../data/models/ad_model.dart';
import '../../../data/repositories/ad_repository.dart';
import '../../../core/utils/result.dart';
import '../../../core/models/ad_filter.dart';

/// Ad Provider (İlan Listesi + Arama + Gelişmiş Filtreleme)
class AdProvider with ChangeNotifier {
  final AdRepository _adRepository = AdRepository();

  List<AdModel> _ads = [];
  List<AdModel> _searchResults = [];
  List<AdModel> _filteredAds = [];
  bool _isLoading = false;
  String? _error;
  
  // Gelişmiş filtre
  AdFilter _filter = AdFilter();
  List<AdFilter> _savedFilters = [];

  // Getters
  List<AdModel> get ads => _filteredAds.isEmpty ? _ads : _filteredAds;
  List<AdModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AdFilter get filter => _filter;
  List<AdFilter> get savedFilters => _savedFilters;
  int get activeFilterCount => _filter.activeFilterCount;

  // Load ads with filter
  void loadAds() {
    _adRepository
        .getAds(
          category: _filter.category,
          city: _filter.city,
          minPrice: _filter.minPrice,
          maxPrice: _filter.maxPrice,
        )
        .listen((ads) {
      _ads = ads;
      _applyFiltersAndSort();
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  // Apply filters and sorting
  void _applyFiltersAndSort() {
    List<AdModel> result = List.from(_ads);

    // Alt kategori filtresi
    if (_filter.subCategory != null) {
      result = result.where((ad) => 
        ad.additionalInfo?['subCategory'] == _filter.subCategory
      ).toList();
    }

    // Durum filtresi
    if (_filter.condition != null) {
      result = result.where((ad) => 
        ad.additionalInfo?['condition'] == _filter.condition
      ).toList();
    }

    // İlan tipi filtresi
    if (_filter.adType != null) {
      result = result.where((ad) => 
        ad.additionalInfo?['adType'] == _filter.adType
      ).toList();
    }

    // Öne çıkan filtresi
    if (_filter.isFeatured != null) {
      result = result.where((ad) => ad.isFeatured == _filter.isFeatured).toList();
    }

    // Sıralama
    switch (_filter.sortBy) {
      case SortOption.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.priceLowToHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortOption.priceHighToLow:
        result.sort((a, b) => b.price.compareTo(a.price));
        break;
      case SortOption.mostViewed:
        result.sort((a, b) => (b.viewCount ?? 0).compareTo(a.viewCount ?? 0));
        break;
      case SortOption.mostFavorited:
        result.sort((a, b) => (b.favoriteCount ?? 0).compareTo(a.favoriteCount ?? 0));
        break;
    }

    _filteredAds = result;
  }

  // Filtre uygula
  void applyFilter(AdFilter filter) {
    _filter = filter;
    loadAds();
  }

  // Hızlı filtre
  void setCategory(String? category) {
    _filter = _filter.copyWith(category: category);
    loadAds();
  }

  void setCity(String? city) {
    _filter = _filter.copyWith(city: city);
    loadAds();
  }

  void setPriceRange(double? min, double? max) {
    _filter = AdFilter(
      category: _filter.category,
      city: _filter.city,
      minPrice: min,
      maxPrice: max,
      sortBy: _filter.sortBy,
    );
    loadAds();
  }

  void setSortOption(SortOption sortOption) {
    _filter = _filter.copyWith(sortBy: sortOption);
    _applyFiltersAndSort();
    notifyListeners();
  }

  // Filtreleri temizle
  void clearFilters() {
    _filter.clear();
    loadAds();
  }

  // Filtre kaydet
  void saveFilter(String name) {
    // TODO: SharedPreferences'a kaydet
    _savedFilters.add(_filter);
    notifyListeners();
  }

  // Kayıtlı filtreyi yükle
  void loadSavedFilter(int index) {
    if (index < _savedFilters.length) {
      _filter = _savedFilters[index];
      loadAds();
    }
  }

  // Search ads
  Future<void> searchAds(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    final result = await _adRepository.searchAds(query);
    
    if (result.isSuccess) {
      _searchResults = result.data!;
      _error = null;
    } else {
      _error = result.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Toggle favorite
  Future<bool> toggleFavorite(String adId) async {
    final result = await _adRepository.toggleFavorite(adId);
    
    if (result.isSuccess) {
      loadAds();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }
}
