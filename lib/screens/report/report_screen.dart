import 'package:flutter/material.dart';
import '../../services/report_service.dart';
import '../../services/auth_service.dart';

class ReportScreen extends StatefulWidget {
  final String reportedId;
  final String reportType; // 'user' veya 'ad'
  final String reportedName;

  const ReportScreen({
    Key? key,
    required this.reportedId,
    required this.reportType,
    required this.reportedName,
  }) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  final Map<String, String> _categories = {
    'spam': 'Spam / Gereksiz İçerik',
    'scam': 'Dolandırıcılık',
    'inappropriate': 'Uygunsuz İçerik',
    'fake': 'Sahte İlan/Profil',
    'offensive': 'Saldırgan Davranış',
    'other': 'Diğer',
  };

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = AuthService.currentUserId;
    if (userId == null) {
      _showSnackBar('Giriş yapmalısınız');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ReportService.submitReport(
        reporterId: userId,
        reportedId: widget.reportedId,
        reportType: widget.reportType,
        category: _selectedCategory!,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        _showSnackBar('Raporunuz alındı. İncelenecektir.');
        Navigator.pop(context);
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
        title: Text('${widget.reportType == 'user' ? 'Kullanıcı' : 'İlan'} Raporla'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bilgi kartı
              Container(
                padding: const EdgeInsets.all(16),
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
                        'Raporunuz incelenecek ve gerekli işlem yapılacaktır.',
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Raporlanan
              Text(
                'Raporlanan: ${widget.reportedName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Kategori
              const Text(
                'Rapor Kategorisi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) =>
                    value == null ? 'Kategori seçin' : null,
              ),
              const SizedBox(height: 24),

              // Açıklama
              const Text(
                'Açıklama',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Lütfen detaylı açıklama yazın...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Açıklama gerekli';
                  }
                  if (value.trim().length < 10) {
                    return 'En az 10 karakter yazın';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Uyarı
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Yanlış bilgi vermek hesabınızın kapatılmasına neden olabilir.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Gönder butonu
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
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
                      : const Text('Rapor Gönder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
