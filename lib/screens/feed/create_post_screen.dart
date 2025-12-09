import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:sehrimapp/services/feed_service.dart';
import 'package:sehrimapp/services/auth_service.dart';
import 'package:sehrimapp/services/image_upload_service.dart';
import 'package:sehrimapp/services/firestore_service.dart';
import 'package:sehrimapp/data/models/user_model.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _contentController = TextEditingController();
  final List<File> _images = [];
  bool _loading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty && (_images.length + pickedFiles.length) <= 4) {
      setState(() {
        _images.addAll(pickedFiles.map((xFile) => File(xFile.path)));
      });
    } else if ((_images.length + pickedFiles.length) > 4) {
      _showSnackBar('En fazla 4 fotoğraf ekleyebilirsiniz');
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty && _images.isEmpty) {
      _showSnackBar('İçerik veya fotoğraf ekleyin');
      return;
    }

    final userId = AuthService.currentUserId;
    if (userId == null) {
      _showSnackBar('Giriş yapmalısınız');
      return;
    }

    setState(() => _loading = true);

    try {
      // 🔥 Firestore'dan kullanıcı bilgilerini al
      final UserModel? user = await FirestoreService.getUser(userId);
      if (user == null) {
        _showSnackBar('Kullanıcı bilgisi alınamadı');
        return;
      }

      // 🔥 Fotoğrafları yükle
      List<String> imageUrls = [];
      for (var image in _images) {
        final url = await ImageUploadService.uploadAdImage(image, userId);
        if (url != null) imageUrls.add(url);
      }

      // 🔥 Paylaşım oluştur
      await FeedService.createPost(
        userId: userId,
        userName: user.name,
        userPhotoUrl: user.photoUrl,
        content: _contentController.text.trim(),
        images: imageUrls.isEmpty ? null : imageUrls,
      );

      if (mounted) {
        _showSnackBar('Paylaşım oluşturuldu!');
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
        title: const Text('Yeni Paylaşım'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _createPost,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Paylaş',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'Ne düşünüyorsun?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            if (_images.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _images.map((image) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          image,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 16,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _images.remove(image);
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            if (_images.length < 4)
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text('Fotoğraf Ekle (${_images.length}/4)'),
              ),
          ],
        ),
      ),
    );
  }
}
