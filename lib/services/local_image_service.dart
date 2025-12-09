import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocalImageService {
  final ImagePicker _picker = ImagePicker();

  // Fotoğraf seç (kamera veya galeri)
  Future<File?> pickImage({required ImageSource source}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Fotoğraf seçme hatası: $e');
      return null;
    }
  }

  // Çoklu fotoğraf seç
  Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFiles.length > maxImages) {
        return pickedFiles
            .take(maxImages)
            .map((xFile) => File(xFile.path))
            .toList();
      }

      return pickedFiles.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      debugPrint('Çoklu fotoğraf seçme hatası: $e');
      return [];
    }
  }

  // Fotoğrafı sıkıştır
  Future<File> compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return file;

      // Boyutlandır (max 1200px)
      if (image.width > 1200 || image.height > 1200) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? 1200 : null,
          height: image.height > image.width ? 1200 : null,
        );
      }

      // JPEG olarak sıkıştır
      final compressedBytes = img.encodeJpg(image, quality: 85);

      // Yeni dosya oluştur
      final compressedFile = File('${file.path}_compressed.jpg')
        ..writeAsBytesSync(compressedBytes);

      return compressedFile;
    } catch (e) {
      debugPrint('Sıkıştırma hatası: $e');
      return file;
    }
  }

  // Profil fotoğrafını yerel kaydet
  Future<String?> saveProfileImageLocally({
    required String userId,
    required File imageFile,
    required String type, // 'user' veya 'business'
  }) async {
    try {
      // Sıkıştır
      final compressedFile = await compressImage(imageFile);

      // Uygulama dizinini al
      final directory = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${directory.path}/profiles/$type/$userId');
      
      // Klasör yoksa oluştur
      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      // Dosya yolu
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${profileDir.path}/$fileName';

      // Dosyayı kopyala
      await compressedFile.copy(savedPath);

      // Sıkıştırılmış geçici dosyayı sil
      if (compressedFile.path != imageFile.path) {
        await compressedFile.delete();
      }

      // Firestore'da LOCAL path olarak kaydet
      return savedPath;
    } catch (e) {
      debugPrint('Yerel kaydetme hatası: $e');
      return null;
    }
  }

  // İlan fotoğraflarını yerel kaydet
  Future<List<String>> saveAdImagesLocally({
    required String adId,
    required List<File> imageFiles,
  }) async {
    final List<String> savedPaths = [];

    try {
      final directory = await getApplicationDocumentsDirectory();
      final adsDir = Directory('${directory.path}/ads/$adId');
      
      if (!await adsDir.exists()) {
        await adsDir.create(recursive: true);
      }

      for (int i = 0; i < imageFiles.length; i++) {
        final compressedFile = await compressImage(imageFiles[i]);
        final fileName = 'image_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '${adsDir.path}/$fileName';

        await compressedFile.copy(savedPath);
        savedPaths.add(savedPath);

        if (compressedFile.path != imageFiles[i].path) {
          await compressedFile.delete();
        }
      }

      return savedPaths;
    } catch (e) {
      debugPrint('Çoklu yerel kaydetme hatası: $e');
      return savedPaths;
    }
  }

  // Eski fotoğrafı sil
  Future<bool> deleteLocalImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Silme hatası: $e');
      return false;
    }
  }

  // Fotoğrafın var olup olmadığını kontrol et
  Future<bool> imageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}