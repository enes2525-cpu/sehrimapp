import 'package:flutter/material.dart';
import 'package:sehrimapp/features/profile/screens/profile_screen.dart'
    as feature_profile;

/// Eski route'lar hâlâ `screens/profile/profile_screen.dart` yolunu
/// kullanıyorsa, buradan yeni profile ekranına yönlendirilir.
class ProfileScreen extends feature_profile.ProfileScreen {
  const ProfileScreen({Key? key}) : super(key: key);
}
