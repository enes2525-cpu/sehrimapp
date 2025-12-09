import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/constants/app_constants.dart';
import '../models/notification_model.dart';
import '../../services/auth_service.dart';

/// Bildirim işlemlerini yöneten Repository
/// Push Notification + In-App Notifications
class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========== BİLDİRİM OLUŞTURMA ==========

  /// Bildirim oluştur
  Future<Result<String>> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationData = {
        'userId': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final doc = await _db
          .collection(AppConstants.collectionNotifications)
          .add(notificationData);

      // TODO: Push notification gönder (FCM)

      return Result.success(doc.id);
    } catch (e) {
      return Result.error('Bildirim oluşturulurken hata: ${e.toString()}');
    }
  }

  /// Mesaj bildirimi
  Future<Result<String>> notifyNewMessage({
    required String recipientId,
    required String senderName,
    required String chatId,
  }) async {
    return await createNotification(
      userId: recipientId,
      type: AppConstants.notificationTypeMessage,
      title: 'Yeni Mesaj',
      body: '$senderName size mesaj gönderdi',
      data: {'chatId': chatId},
    );
  }

  /// Beğeni bildirimi
  Future<Result<String>> notifyLike({
    required String recipientId,
    required String likerName,
    required String postId,
  }) async {
    return await createNotification(
      userId: recipientId,
      type: AppConstants.notificationTypeLike,
      title: 'Yeni Beğeni',
      body: '$likerName gönderinizi beğendi',
      data: {'postId': postId},
    );
  }

  /// Yorum bildirimi
  Future<Result<String>> notifyComment({
    required String recipientId,
    required String commenterName,
    required String postId,
    required String commentText,
  }) async {
    return await createNotification(
      userId: recipientId,
      type: AppConstants.notificationTypeComment,
      title: 'Yeni Yorum',
      body: '$commenterName: ${commentText.length > 50 ? commentText.substring(0, 50) + '...' : commentText}',
      data: {'postId': postId},
    );
  }

  /// Takip bildirimi
  Future<Result<String>> notifyFollow({
    required String recipientId,
    required String followerName,
  }) async {
    return await createNotification(
      userId: recipientId,
      type: AppConstants.notificationTypeFollow,
      title: 'Yeni Takipçi',
      body: '$followerName sizi takip etmeye başladı',
      data: {},
    );
  }

  /// Randevu bildirimi
  Future<Result<String>> notifyAppointment({
    required String recipientId,
    required String title,
    required String body,
    required String appointmentId,
  }) async {
    return await createNotification(
      userId: recipientId,
      type: AppConstants.notificationTypeAppointment,
      title: title,
      body: body,
      data: {'appointmentId': appointmentId},
    );
  }

  // ========== BİLDİRİMLERİ OKUMA ==========

  /// Kullanıcının bildirimlerini getir (Stream)
  Stream<List<NotificationModel>> getNotifications(
    String userId, {
    int limit = 50,
  }) {
    return _db
        .collection(AppConstants.collectionNotifications)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// Okunmamış bildirim sayısı (Stream)
  Stream<int> getUnreadCount(String userId) {
    return _db
        .collection(AppConstants.collectionNotifications)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Bildirimi okundu olarak işaretle
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await _db
          .collection(AppConstants.collectionNotifications)
          .doc(notificationId)
          .update({'isRead': true});

      return Result.success(null);
    } catch (e) {
      return Result.error('Bildirim işaretlenirken hata: ${e.toString()}');
    }
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      final notifications = await _db
          .collection(AppConstants.collectionNotifications)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      return Result.success(null);
    } catch (e) {
      return Result.error('Bildirimler işaretlenirken hata: ${e.toString()}');
    }
  }

  /// Bildirimi sil
  Future<Result<void>> deleteNotification(String notificationId) async {
    try {
      await _db
          .collection(AppConstants.collectionNotifications)
          .doc(notificationId)
          .delete();

      return Result.success(null);
    } catch (e) {
      return Result.error('Bildirim silinirken hata: ${e.toString()}');
    }
  }

  /// Tüm bildirimleri sil
  Future<Result<void>> deleteAllNotifications(String userId) async {
    try {
      final notifications = await _db
          .collection(AppConstants.collectionNotifications)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _db.batch();
      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      return Result.success(null);
    } catch (e) {
      return Result.error('Bildirimler silinirken hata: ${e.toString()}');
    }
  }

  // ========== PUSH TOKEN YÖNETİMİ ==========

  /// FCM token kaydet
  Future<Result<void>> saveFCMToken(String userId, String token) async {
    try {
      await _db.collection(AppConstants.collectionUsers).doc(userId).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Token kaydedilemedi: ${e.toString()}');
    }
  }

  /// FCM token sil
  Future<Result<void>> removeFCMToken(String userId) async {
    try {
      await _db.collection(AppConstants.collectionUsers).doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Token silinemedi: ${e.toString()}');
    }
  }
}
