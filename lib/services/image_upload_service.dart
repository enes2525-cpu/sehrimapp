import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// LOCAL STORAGE VERSION - Firebase Storage gerektirmez
/// Fotoğraflar cihazda saklanır, yolu Firestore'a kaydedilir
/// Production'da Firebase Storage'a geçilecek
class ImageUploadService {
  // İlan fotoğrafı yükle (local)
  static Future<String?> uploadAdImage(File image, String userId) async {
    try {
      // Uygulama dizinini al
      final directory = await getApplicationDocumentsDirectory();
      final adsDir = Directory('${directory.path}/ads/$userId');
      
      // Klasör yoksa oluştur
      if (!await adsDir.exists()) {
        await adsDir.create(recursive: true);
      }
      
      // Dosya adı oluştur
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      final savedPath = '${adsDir.path}/$fileName';
      
      // Dosyayı kopyala
      await image.copy(savedPath);
      
      // Local path döndür
      return savedPath;
    } catch (e) {
      print('Fotoğraf kaydetme hatası: $e');
      return null;
    }
  }

  // Profil fotoğrafı yükle (local)
  static Future<String?> uploadProfileImage(File image, String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final usersDir = Directory('${directory.path}/users/$userId');
      
      if (!await usersDir.exists()) {
        await usersDir.create(recursive: true);
      }
      
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${usersDir.path}/$fileName';
      
      await image.copy(savedPath);
      
      return savedPath;
    } catch (e) {
      print('Profil fotoğrafı kaydetme hatası: $e');
      return null;
    }
  }

  // Dükkan fotoğrafı yükle (local)
  static Future<String?> uploadBusinessImage(File image, String businessId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final businessDir = Directory('${directory.path}/businesses/$businessId');
      
      if (!await businessDir.exists()) {
        await businessDir.create(recursive: true);
      }
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
      final savedPath = '${businessDir.path}/$fileName';
      
      await image.copy(savedPath);
      
      return savedPath;
    } catch (e) {
      print('Dükkan fotoğrafı kaydetme hatası: $e');
      return null;
    }
  }

  // Çoklu fotoğraf yükle
  static Future<List<String>> uploadMultipleImages(
    List<File> images,
    String userId,
    String folder,
  ) async {
    final List<String> paths = [];

    for (var image in images) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final targetDir = Directory('${directory.path}/$folder/$userId');
        
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
        
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
        final savedPath = '${targetDir.path}/$fileName';
        
        await image.copy(savedPath);
        paths.add(savedPath);
      } catch (e) {
        print('Fotoğraf kaydetme hatası: $e');
      }
    }

    return paths;
  }

  // Fotoğraf sil
  static Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Fotoğraf silme hatası: $e');
    }
  }

  // Birden fazla fotoğraf sil
  static Future<void> deleteMultipleImages(List<String> imagePaths) async {
    for (var path in imagePaths) {
      await deleteImage(path);
    }
  }

  // Local path'i kontrol et
  static Future<bool> imageExists(String imagePath) async {
    try {
      final file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}
