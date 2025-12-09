import 'package:flutter/material.dart';
import '../services/report_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ReportDialog extends StatefulWidget {
  final String targetId;
  final String targetType; // 'ad' veya 'user'

  const ReportDialog({
    Key? key,
    required this.targetId,
    required this.targetType,
  }) : super(key: key);

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  final List<String> _adReasons = [
    'Spam veya Yanıltıcı',
    'Dolandırıcılık',
    'Uygunsuz İçerik',
    'Sahte Ürün/Hizmet',
    'Yasadışı İçerik',
    'Telif Hakkı İhlali',
    'Diğer',
  ];

  final List<String> _userReasons = [
    'Spam Gönderiyor',
    'Dolandırıcılık',
    'Taciz veya Zorbalık',
    'Sahte Profil',
    'Uygunsuz Davranış',
    'Diğer',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null) {
      _showSnackBar('Lütfen bir neden seçin');
      return;
    }

    final userId = AuthService.currentUserId;
    if (userId == null) {
      _showSnackBar('Giriş yapmalısınız');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Kullanıcı bilgisini al
      final user = await FirestoreService.getUser(userId);
      
      await ReportService.createReport(
        reporterId: userId,
        reporterName: user?.name ?? 'Anonim',
        targetId: widget.targetId,
        targetType: widget.targetType,
        reason: _selectedReason!,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Rapor gönderildi. İnceleme sürecine alındı.');
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString());
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
    final reasons = widget.targetType == 'ad' ? _adReasons : _userReasons;
    final title = widget.targetType == 'ad' ? 'İlan Bildir' : 'Kullanıcı Bildir';

    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Neden bildirmek istiyorsunuz?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...reasons.map((reason) => RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) {
                setState(() => _selectedReason = value);
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            )),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Açıklama (Opsiyonel)',
                border: OutlineInputBorder(),
                hintText: 'Detaylı açıklama yazabilirsiniz...',
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
          onPressed: _isLoading ? null : _submitReport,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Bildir'),
        ),
      ],
    );
  }
}

// Helper function - Kolayca açmak için
void showReportDialog(BuildContext context, String targetId, String targetType) {
  showDialog(
    context: context,
    builder: (context) => ReportDialog(
      targetId: targetId,
      targetType: targetType,
    ),
  );
}
