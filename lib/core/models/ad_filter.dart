import 'package:flutter/foundation.dart';

/// Gelişmiş Filtre Modeli
class AdFilter {
  String? category;
  String? subCategory;
  String? city;
  double? minPrice;
  double? maxPrice;
  String? condition; // new, used, like_new
  String? adType; // individual, business
  SortOption sortBy;
  bool? isFeatured;
  
  AdFilter({
    this.category,
    this.subCategory,
    this.city,
    this.minPrice,
    this.maxPrice,
    this.condition,
    this.adType,
    this.sortBy = SortOption.newest,
    this.isFeatured,
  });

  // Filtre aktif mi?
  bool get hasActiveFilters {
    return category != null ||
        subCategory != null ||
        city != null ||
        minPrice != null ||
        maxPrice != null ||
        condition != null ||
        adType != null ||
        isFeatured != null;
  }

  // Filtre sayısı
  int get activeFilterCount {
    int count = 0;
    if (category != null) count++;
    if (subCategory != null) count++;
    if (city != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (condition != null) count++;
    if (adType != null) count++;
    if (isFeatured != null) count++;
    return count;
  }

  // Filtreyi temizle
  void clear() {
    category = null;
    subCategory = null;
    city = null;
    minPrice = null;
    maxPrice = null;
    condition = null;
    adType = null;
    sortBy = SortOption.newest;
    isFeatured = null;
  }

  // Copy with
  AdFilter copyWith({
    String? category,
    String? subCategory,
    String? city,
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? adType,
    SortOption? sortBy,
    bool? isFeatured,
  }) {
    return AdFilter(
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      city: city ?? this.city,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      condition: condition ?? this.condition,
      adType: adType ?? this.adType,
      sortBy: sortBy ?? this.sortBy,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  // To map
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'subCategory': subCategory,
      'city': city,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'condition': condition,
      'adType': adType,
      'sortBy': sortBy.name,
      'isFeatured': isFeatured,
    };
  }

  // From map
  factory AdFilter.fromMap(Map<String, dynamic> map) {
    return AdFilter(
      category: map['category'],
      subCategory: map['subCategory'],
      city: map['city'],
      minPrice: map['minPrice'],
      maxPrice: map['maxPrice'],
      condition: map['condition'],
      adType: map['adType'],
      sortBy: SortOption.values.firstWhere(
        (e) => e.name == map['sortBy'],
        orElse: () => SortOption.newest,
      ),
      isFeatured: map['isFeatured'],
    );
  }
}

/// Sıralama seçenekleri
enum SortOption {
  newest('En Yeni'),
  oldest('En Eski'),
  priceLowToHigh('Ucuzdan Pahalıya'),
  priceHighToLow('Pahalıdan Ucuza'),
  mostViewed('En Çok Görüntülenen'),
  mostFavorited('En Çok Favorilenen');

  final String label;
  const SortOption(this.label);
}

/// Alt kategoriler (Kategori bazlı)
class SubCategories {
  static const Map<String, List<String>> categories = {
    'Elektronik': [
      'Telefon',
      'Bilgisayar',
      'Tablet',
      'Kulaklık',
      'Kamera',
      'Oyun Konsolu',
    ],
    'Ev & Yaşam': [
      'Mobilya',
      'Beyaz Eşya',
      'Dekorasyon',
      'Aydınlatma',
      'Mutfak',
      'Banyo',
    ],
    'Araç': [
      'Otomobil',
      'Motosiklet',
      'Bisiklet',
      'Yedek Parça',
      'Aksesuar',
    ],
    'Emlak': [
      'Daire',
      'Villa',
      'Arsa',
      'İşyeri',
      'Depo',
    ],
    'Moda & Giyim': [
      'Kadın Giyim',
      'Erkek Giyim',
      'Çocuk Giyim',
      'Ayakkabı',
      'Çanta',
      'Aksesuar',
    ],
    'Hizmetler': [
      'Temizlik',
      'Taşımacılık',
      'Tadilat',
      'Özel Ders',
      'Bakım',
    ],
  };

  static List<String> getSubCategories(String category) {
    return categories[category] ?? [];
  }
}
