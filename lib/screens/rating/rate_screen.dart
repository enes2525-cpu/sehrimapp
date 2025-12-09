import 'package:flutter/material.dart';
import 'package:sehrimapp/data/models/rating_model.dart';
import 'package:sehrimapp/services/rating_service.dart';
import 'package:sehrimapp/services/auth_service.dart';

class RateScreen extends StatefulWidget {
  final String targetId;
  final String targetType; // 'business' veya 'user'
  final String targetName;

  const RateScreen({
    Key? key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
  }) : super(key: key);

  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  bool _isLoading = false;
  RatingModel? _existingRating;

  @override
  void initState() {
    super.initState();
    _loadExistingRating();
  }

  Future<void> _loadExistingRating() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;

    final existing = await RatingService.getUserRating(userId, widget.targetId);
    if (existing != null) {
      setState(() {
        _existingRating = existing;
        _rating = existing.rating;
        _commentController.text = existing.comment ?? '';
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    final userId = AuthService.currentUserId;
    final userName = AuthService.currentUserId?.displayName ?? 'Anonim';

    if (userId == null) {
      _showSnackBar('Giriş yapmalısınız');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await RatingService.addRating(
        userId: userId,
        userName: userName,
        targetId: widget.targetId,
        targetType: widget.targetType,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
      );

      if (mounted) {
        _showSnackBar('Değerlendirmeniz kaydedildi');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Hata: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        title: Text('${widget.targetName} - Değerlendir'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bilgi kartı
            if (_existingRating != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Daha önce değerlendirme yapmışsınız. Güncelleyebilirsiniz.',
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),

            // Puan verme
            const Text(
              'Puanınız',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  // Yıldızlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        iconSize: 48,
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = (index + 1).toDouble();
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRatingText(_rating),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getRatingColor(_rating),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Yorum
            const Text(
              'Yorumunuz (İsteğe bağlı)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 5,
              maxLength: 500,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Deneyiminizi paylaşın...',
              ),
            ),
            const SizedBox(height: 24),

            // Gönder butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_existingRating == null
                        ? 'Değerlendirmeyi Gönder'
                        : 'Değerlendirmeyi Güncelle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 5) return 'Mükemmel';
    if (rating >= 4) return 'Çok İyi';
    if (rating >= 3) return 'İyi';
    if (rating >= 2) return 'Orta';
    return 'Kötü';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }
}
