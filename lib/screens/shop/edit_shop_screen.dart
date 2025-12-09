import 'package:flutter/material.dart';
import '../../models/business_model.dart';
import 'package:sehrimapp/data/models/business_model.dart';

class EditShopScreen extends StatelessWidget {
  final BusinessModel business;

  const EditShopScreen({Key? key, required this.business}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dükkanı Düzenle'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Dükkan düzenleme ekranı - Mevcut kodunuz burada kullanılacak'),
      ),
    );
  }
}