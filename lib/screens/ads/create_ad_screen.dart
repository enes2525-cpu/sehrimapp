import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:sehrimapp/data/models/ad_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/image_upload_service.dart';

class CreateAdScreen extends StatefulWidget {
  const CreateAdScreen({Key? key}) : super(key: key);

  @override
  State<CreateAdScreen> createState() => _CreateAdScreenState();
}

class _CreateAdScreenState extends State<CreateAdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  
  List<File> _images = [];
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedCity;
  String? _selectedDistrict;
  bool _priceHidden = false;
  bool _isOnSale = false;
  int? _discountPercentage;
  bool _loading = false;

  final List<String> _categories = [
    'Kadın Giyim',
    'Erkek Giyim',
    'Elektronik',
    'Ev & Yaşam',
    'Otomotiv',
    'Hizmetler',
  ];

  final Map<String, List<String>> _subCategories = {
    'Kadın Giyim': ['Elbise', 'Pantolon', 'Bluz', 'Ayakkabı', 'Çanta'],
    'Erkek Giyim': ['Gömlek', 'Pantolon', 'Ayakkabı', 'Aksesuar'],
    'Elektronik': ['Telefon', 'Bilgisayar', 'Tablet', 'Aksesuar'],
    'Ev & Yaşam': ['Mobilya', 'Dekorasyon', 'Bahçe', 'Mutfak'],
    'Otomotiv': ['Araba', 'Motor', 'Parça', 'Aksesuar'],
    'Hizmetler': ['Berber', 'Kuaför', 'Tamirci', 'Temizlik'],
  };

  final List<String> _cities = [
    'Erzurum', 'İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya',
    'Adana', 'Gaziantep', 'Konya', 'Kayseri'
  ];

  final Map<String, List<String>> _districts = {
    'Erzurum': ['Yakutiye', 'Palandöken', 'Aziziye'],
    'İstanbul': ['Kadıköy', 'Beşiktaş', 'Şişli', 'Bakırköy'],
    'Ankara': ['Çankaya', 'Keçiören', 'Mamak', 'Yenimahalle'],
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= 5) {
      _showSnackBar('En fazla 5 fotoğraf ekleyebilirsiniz');
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _createAd() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_images.isEmpty) {
      _showSnackBar('En az 1 fotoğraf ekleyin');
      return;
    }

    if (_selectedCity == null) {
      _showSnackBar('Şehir seçiniz');
      return;
    }

    setState(() => _loading = true);

    try {
      final userId = AuthService.currentUserId;
      if (userId == null) throw 'Giriş yapmalısınız';

      // Kullanıcı bilgilerini al
      final user = await FirestoreService.getUser(userId);
      if (user == null) throw 'Kullanıcı bulunamadı';

      // 🔥 Fotoğrafları tek seferde yükle (GÜNCEL DOĞRU KULLANIM)
      List<String> imageUrls = [];
      for (var image in _images) {
        final url = await ImageUploadService.uploadAdImage(image, userId);
        if (url != null) {
          imageUrls.add(url);
        }
      }

      if (imageUrls.isEmpty) {
        throw 'Fotoğraf yüklenemedi';
      }

      // İlan oluştur
      final ad = AdModel(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        subcategory: _selectedSubCategory,
        price: _priceHidden ? 0 : double.tryParse(_priceController.text) ?? 0,
        priceHidden: _priceHidden,
        originalPrice: _isOnSale && !_priceHidden
            ? double.tryParse(_originalPriceController.text)
            : null,
        discountPercentage: _isOnSale ? _discountPercentage : null,
        isOnSale: _isOnSale && !_priceHidden,
        city: _selectedCity!,
        district: _selectedDistrict,
        userId: userId,
        userName: user.name,
        userPhone: user.phone,
        mainImage: imageUrls.first,
        images: imageUrls,
        createdAt: DateTime.now(),
      );

      await FirestoreService.createAd(ad);

      if (mounted) {
        _showSnackBar('İlan başarıyla oluşturuldu!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Oluştur'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPhotoSection(),
                  const SizedBox(height: 24),
                  _buildTitleField(),
                  const SizedBox(height: 16),
                  _buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  if (_selectedCategory != null) _buildSubCategoryDropdown(),
                  if (_selectedCategory != null) const SizedBox(height: 16),
                  _buildCityDropdown(),
                  const SizedBox(height: 16),
                  if (_selectedCity != null) _buildDistrictDropdown(),
                  if (_selectedCity != null) const SizedBox(height: 16),
                  _buildDescriptionField(),
                  const SizedBox(height: 16),
                  _buildPriceField(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotoğraflar (Maks. 5)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length + 1,
            itemBuilder: (context, index) {
              if (index == _images.length) {
                return _buildAddPhotoButton();
              }
              return _buildPhotoItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: () => _showImageSourceDialog(),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              'Fotoğraf Ekle',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    return Stack(
      children: [
        Container(
          width: 120,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: FileImage(_images[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 16,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'İlan Başlığı',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Başlık gerekli';
        }
        if (value.trim().length < 3) {
          return 'Başlık en az 3 karakter olmalı';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
          _selectedSubCategory = null;
        });
      },
      validator: (value) => value == null ? 'Kategori seçin' : null,
    );
  }

  Widget _buildSubCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSubCategory,
      decoration: const InputDecoration(
        labelText: 'Alt Kategori (Opsiyonel)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.subdirectory_arrow_right),
      ),
      items: _subCategories[_selectedCategory]?.map((subCategory) {
        return DropdownMenuItem(
          value: subCategory,
          child: Text(subCategory),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedSubCategory = value;
        });
      },
    );
  }

  Widget _buildCityDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCity,
      decoration: const InputDecoration(
        labelText: 'Şehir',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_city),
      ),
      items: _cities.map((city) {
        return DropdownMenuItem(
          value: city,
          child: Text(city),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCity = value;
          _selectedDistrict = null;
        });
      },
      validator: (value) => value == null ? 'Şehir seçin' : null,
    );
  }

  Widget _buildDistrictDropdown() {
    final districts = _districts[_selectedCity] ?? [];
    if (districts.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<String>(
      value: _selectedDistrict,
      decoration: const InputDecoration(
        labelText: 'İlçe (Opsiyonel)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on),
      ),
      items: districts.map((district) {
        return DropdownMenuItem(
          value: district,
          child: Text(district),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDistrict = value;
        });
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 5,
      decoration: const InputDecoration(
        labelText: 'Açıklama',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
        alignLabelWithHint: true,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Açıklama gerekli';
        }
        if (value.trim().length < 10) {
          return 'Açıklama en az 10 karakter olmalı';
        }
        return null;
      },
    );
  }

  Widget _buildPriceField() {
    return Column(
      children: [
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          enabled: !_priceHidden,
          decoration: const InputDecoration(
            labelText: 'Fiyat (₺)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
          ),
          validator: (value) {
            if (_priceHidden) return null;
            if (value == null || value.isEmpty) {
              return 'Fiyat gerekli';
            }
            if (double.tryParse(value) == null) {
              return 'Geçerli bir fiyat girin';
            }
            return null;
          },
          onChanged: (value) {
            if (_isOnSale && _originalPriceController.text.isNotEmpty) {
              _calculateDiscount();
            }
          },
        ),
        CheckboxListTile(
          title: const Text('Fiyatı Gizle'),
          value: _priceHidden,
          onChanged: (value) {
            setState(() {
              _priceHidden = value ?? false;
              if (_priceHidden) {
                _priceController.clear();
              }
            });
          },
        ),

        // İNDİRİM BÖLÜMÜ
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('İndirimde'),
          subtitle: const Text('Bu ürün indirimli mi?'),
          value: _isOnSale,
          onChanged: _priceHidden
              ? null
              : (value) {
                  setState(() {
                    _isOnSale = value ?? false;
                    if (!_isOnSale) {
                      _originalPriceController.clear();
                      _discountPercentage = null;
                    }
                  });
                },
        ),
        if (_isOnSale && !_priceHidden) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _originalPriceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'İndirim Öncesi Fiyat (₺)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.price_change),
              suffixIcon: _discountPercentage != null
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      child: Chip(
                        label: Text('%$_discountPercentage'),
                        backgroundColor: Colors.green,
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
            ),
            validator: (value) {
              if (!_isOnSale) return null;
              if (value == null || value.isEmpty) {
                return 'İndirim öncesi fiyat gerekli';
              }
              final originalPrice = double.tryParse(value);
              if (originalPrice == null) {
                return 'Geçerli bir fiyat girin';
              }
              final currentPrice = double.tryParse(_priceController.text);
              if (currentPrice != null && originalPrice <= currentPrice) {
                return 'İndirim öncesi fiyat mevcut fiyattan yüksek olmalı';
              }
              return null;
            },
            onChanged: (value) {
              _calculateDiscount();
            },
          ),
        ],
      ],
    );
  }

  void _calculateDiscount() {
    final originalPrice = double.tryParse(_originalPriceController.text);
    final currentPrice = double.tryParse(_priceController.text);

    if (originalPrice != null &&
        currentPrice != null &&
        originalPrice > currentPrice) {
      setState(() {
        _discountPercentage =
            (((originalPrice - currentPrice) / originalPrice) * 100).round();
      });
    } else {
      setState(() {
        _discountPercentage = null;
      });
    }
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _loading ? null : _createAd,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: _loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(
              'İlanı Yayınla',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }
}
