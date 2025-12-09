import 'package:flutter/foundation.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

/// Notification Provider
class NotificationProvider with ChangeNotifier {
  final NotificationRepository _notificationRepository = NotificationRepository();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  // Load notifications
  void loadNotifications(String userId) {
    _notificationRepository.getNotifications(userId).listen((notifications) {
      _notifications = notifications;
      _isLoading = false;
      notifyListeners();
    });

    // Load unread count
    _notificationRepository.getUnreadCount(userId).listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    await _notificationRepository.markAsRead(notificationId);
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    await _notificationRepository.markAllAsRead(userId);
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _notificationRepository.deleteNotification(notificationId);
  }
}
