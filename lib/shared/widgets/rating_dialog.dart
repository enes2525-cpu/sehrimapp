import 'package:flutter/material.dart';
import '../services/rating_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class RatingDialog extends StatefulWidget {
  final String targetId;
  final String targetType; // 'business' veya 'user'
  final String targetName;

  const RatingDialog({
    Key? key,
    required this.targetId,
    required this.targetType,
    required this.targetName,
  }) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double _rating = 5.0;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      _showSnackBar('Giriş yapmalısınız');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await FirestoreService.getUser(userId);

      await RatingService.addRating(
        userId: userId,
        userName: user?.name ?? 'Anonim',
        targetId: widget.targetId,
        targetType: widget.targetType,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty 
            ? null 
            : _commentController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        _showSnackBar('Değerlendirmeniz kaydedildi');
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
    return AlertDialog(
      title: Text('${widget.targetName} için değerlendirme'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Yıldız gösterimi
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() => _rating = index + 1.0);
                  },
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _getRatingText(_rating),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _getRatingColor(_rating),
              ),
            ),
            const SizedBox(height: 16),

            // Yorum
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Yorumunuz (Opsiyonel)',
                border: OutlineInputBorder(),
                hintText: 'Deneyiminizi paylaşın...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitRating,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Gönder'),
        ),
      ],
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Mükemmel';
    if (rating >= 3.5) return 'İyi';
    if (rating >= 2.5) return 'Orta';
    if (rating >= 1.5) return 'Kötü';
    return 'Çok Kötü';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }
}

// Helper function
void showRatingDialog(
  BuildContext context, {
  required String targetId,
  required String targetType,
  required String targetName,
}) {
  showDialog(
    context: context,
    builder: (context) => RatingDialog(
      targetId: targetId,
      targetType: targetType,
      targetName: targetName,
    ),
  );
}
