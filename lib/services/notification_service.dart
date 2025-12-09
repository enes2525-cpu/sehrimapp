import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/notification_model.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Bildirim oluştur
  static Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? imageUrl,
    String? actionId,
    String? actionType,
  }) async {
    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: type,
      title: title,
      body: body,
      imageUrl: imageUrl,
      actionId: actionId,
      actionType: actionType,
      createdAt: DateTime.now(),
    );

    await _db.collection('notifications').add(notification.toMap());
  }

  // Kullanıcının bildirimlerini getir (stream)
  static Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Okunmamış bildirim sayısı
  static Stream<int> getUnreadCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Bildirimi okundu olarak işaretle
  static Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Tüm bildirimleri okundu yap
  static Future<void> markAllAsRead(String userId) async {
    final snapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Bildirimi sil
  static Future<void> deleteNotification(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }

  // Tüm bildirimleri sil
  static Future<void> deleteAllNotifications(String userId) async {
    final snapshot = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // HELPER METOTLAR - Özel bildirim tipleri

  // Yeni mesaj bildirimi
  static Future<void> notifyNewMessage({
    required String recipientId,
    required String senderName,
    required String chatId,
  }) async {
    await createNotification(
      userId: recipientId,
      type: 'message',
      title: 'Yeni Mesaj',
      body: '$senderName size mesaj gönderdi',
      actionId: chatId,
      actionType: 'chat',
    );
  }

  // İlan beğeni bildirimi
  static Future<void> notifyAdLike({
    required String adOwnerId,
    required String likerName,
    required String adId,
    required String adTitle,
  }) async {
    await createNotification(
      userId: adOwnerId,
      type: 'like',
      title: 'İlanınız Beğenildi',
      body: '$likerName "$adTitle" ilanınızı beğendi',
      actionId: adId,
      actionType: 'ad',
    );
  }

  // Post beğeni bildirimi
  static Future<void> notifyPostLike({
    required String postOwnerId,
    required String likerName,
    required String postId,
  }) async {
    await createNotification(
      userId: postOwnerId,
      type: 'like',
      title: 'Paylaşımınız Beğenildi',
      body: '$likerName paylaşımınızı beğendi',
      actionId: postId,
      actionType: 'post',
    );
  }

  // Yorum bildirimi
  static Future<void> notifyComment({
    required String postOwnerId,
    required String commenterName,
    required String postId,
    required String commentText,
  }) async {
    await createNotification(
      userId: postOwnerId,
      type: 'comment',
      title: 'Yeni Yorum',
      body: '$commenterName: ${commentText.length > 50 ? commentText.substring(0, 50) + "..." : commentText}',
      actionId: postId,
      actionType: 'post',
    );
  }

  // Randevu bildirimi
  static Future<void> notifyAppointment({
    required String userId,
    required String businessName,
    required String appointmentId,
    required DateTime appointmentDate,
  }) async {
    await createNotification(
      userId: userId,
      type: 'appointment',
      title: 'Randevu Onaylandı',
      body: '$businessName ile randevunuz onaylandı',
      actionId: appointmentId,
      actionType: 'appointment',
    );
  }

  // Takip bildirimi
  static Future<void> notifyFollow({
    required String followedUserId,
    required String followerName,
    required String followerId,
  }) async {
    await createNotification(
      userId: followedUserId,
      type: 'follow',
      title: 'Yeni Takipçi',
      body: '$followerName sizi takip etmeye başladı',
      actionId: followerId,
      actionType: 'user',
    );
  }

  // İndirim bildirimi
  static Future<void> notifyDiscount({
    required String userId,
    required String adTitle,
    required String adId,
    required int discountPercentage,
  }) async {
    await createNotification(
      userId: userId,
      type: 'discount',
      title: 'İndirim Fırsatı!',
      body: '"$adTitle" ilanında %$discountPercentage indirim!',
      actionId: adId,
      actionType: 'ad',
    );
  }
}
