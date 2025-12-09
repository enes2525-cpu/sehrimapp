import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../data/repositories/user_repository.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;
  final UserRepository _userRepo = UserRepository();
  bool _loading = false;

  UserModel? get user => _user;
  bool get isLoading => _loading;
  bool get isLoggedIn => _user != null;

  /// Kullanıcıyı Firestore'dan yükle
  Future<void> loadUser() async {
    final userId = AuthService.currentUserId;
    if (userId == null) return;

    _loading = true;
    notifyListeners();

    final result = await _userRepo.getUser(userId);

    if (result.isSuccess) {
      _user = result.data;
    }

    _loading = false;
    notifyListeners();
  }

  /// Profili güncelle
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
    String? bio,
    String? city,
    String? district,
  }) async {
    if (_user == null) return false;

    final userId = _user!.id;

    Map<String, dynamic> updateData = {};

    if (name != null) updateData['name'] = name;
    if (phone != null) updateData['phone'] = phone;
    if (photoUrl != null) updateData['photoUrl'] = photoUrl;
    if (bio != null) updateData['bio'] = bio;
    if (city != null) updateData['city'] = city;
    if (district != null) updateData['district'] = district;

    // Profil tamamlama otomatik hesaplanıyor
    final completion = _calculateCompletion(updateData);
    updateData['profileCompletion'] = completion;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update(updateData);

    /// Lokal state güncelle
    _user = _user!.copyWith(
      name: name,
      phone: phone,
      photoUrl: photoUrl,
      profileCompletion: completion,
    );

    notifyListeners();
    return true;
  }

  /// Profil tamamlama yüzdesi
  int _calculateCompletion(Map<String, dynamic> data) {
    int score = 0;

    if ((data['photoUrl'] ?? _user?.photoUrl)?.isNotEmpty ?? false) score += 20;
    if ((data['phone'] ?? _user?.phone)?.isNotEmpty ?? false) score += 20;
    if ((data['city'] ?? _user?.city)?.isNotEmpty ?? false) score += 15;
    if ((data['district'] ?? _user?.district)?.isNotEmpty ?? false) score += 10;
    if ((data['bio'] ?? '').toString().isNotEmpty) score += 15;

    return score.clamp(0, 100);
  }
}
