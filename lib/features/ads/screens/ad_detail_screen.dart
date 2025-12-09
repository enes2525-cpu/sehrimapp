import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

import 'package:sehrimapp/data/models/ad_model.dart';
import 'package:sehrimapp/data/models/user_model.dart';
import 'package:sehrimapp/services/firestore_service.dart';
import 'package:sehrimapp/services/auth_service.dart';
import 'package:sehrimapp/widgets/badge_widget.dart';

class AdDetailScreen extends StatefulWidget {
  final String adId;

  const AdDetailScreen({Key? key, required this.adId}) : super(key: key);

  @override
  State<AdDetailScreen> createState() => _AdDetailScreenState();
}

class _AdDetailScreenState extends State<AdDetailScreen> {
  bool _isFavorite = false;
  bool _isLoading = true;
  AdModel? _ad;
  UserModel? _seller;

  @override
  void initState() {
    super.initState();
    _loadAdDetails();
  }

  Future<void> _loadAdDetails() async {
    try {
      final ad = await FirestoreService.getAd(widget.adId);
      if (ad == null) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      /// GÖRÜNTÜLENME SAYISI ARTIYOR (DÜZGÜN ŞEKİLDE)
      await FirestoreService.incrementAdViews(ad.id, ad.userId);

      final seller = await FirestoreService.getUser(ad.userId);

      final userId = AuthService.currentUserId;
      bool isFav = false;

      if (userId != null) {
        isFav = await FirestoreService.isAdFavorite(userId, widget.adId);
      }

      if (mounted) {
        setState(() {
          _ad = ad;
          _seller = seller;
          _isFavorite = isFav;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_ad == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('İlan bulunamadı')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Detayı'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildImageGallery(),
                  _buildAdInfo(),
                  _buildSellerInfo(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = _ad!.images;
    if (images.isEmpty) {
      return Container(
        height: 300,
        color: Colors.grey[200],
      );
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          final path = images[index];

          if (path.startsWith('/') || path.startsWith('file://')) {
            return Image.file(
              File(path),
              fit: BoxFit.cover,
            );
          }

          return CachedNetworkImage(
            imageUrl: path,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }

  Widget _buildAdInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _ad!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(_ad!.description),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    if (_seller == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text('Satıcı: ${_seller!.name}'),
    );
  }
}
