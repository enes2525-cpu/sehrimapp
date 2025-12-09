import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAdScreen extends StatefulWidget {
  final String adId;
  final Map<String, dynamic> adData;

  const EditAdScreen({
    Key? key,
    required this.adId,
    required this.adData,
  }) : super(key: key);

  @override
  State<EditAdScreen> createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  bool _hasShipping = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.adData['title']);
    _descriptionController = TextEditingController(text: widget.adData['description']);
    _priceController = TextEditingController(text: widget.adData['price']?.toString() ?? '');
    _hasShipping = widget.adData['hasShipping'] ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _updateAd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('ads')
          .doc(widget.adId)
          .update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': int.tryParse(_priceController.text) ?? 0,
        'hasShipping': _hasShipping,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İlan güncellendi')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Düzenle'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Başlık
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'İlan Başlığı',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Başlık giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Açıklama
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Açıklama giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Fiyat
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Fiyat (₺)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Fiyat giriniz';
                }
                if (int.tryParse(value) == null) {
                  return 'Geçerli bir fiyat giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Kargo
            SwitchListTile(
              title: const Text('Kargo ile gönderilebilir'),
              value: _hasShipping,
              onChanged: (value) {
                setState(() {
                  _hasShipping = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Güncelle Butonu
            ElevatedButton(
              onPressed: _loading ? null : _updateAd,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Güncelle',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}