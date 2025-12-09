import 'package:flutter/material.dart';
import 'package:sehrimapp/data/models/notification_model.dart';
import 'package:sehrimapp/services/notification_service.dart';
import 'package:sehrimapp/services/auth_service.dart';
import 'package:sehrimapp/screens/ads/ad_detail_screen.dart';
import 'package:sehrimapp/screens/conversations/chat_screen.dart';
import 'package:sehrimapp/screens/feed/post_detail_screen.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUserId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bildirimler')),
        body: const Center(child: Text('Giriş yapmalısınız')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          // Tümünü okundu yap
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await NotificationService.markAllAsRead(userId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tüm bildirimler okundu')),
                );
              }
            },
            tooltip: 'Tümünü Okundu Yap',
          ),
          // Tümünü sil
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Tümünü Sil'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'delete_all') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Tüm Bildirimleri Sil'),
                    content: const Text('Tüm bildirimler silinecek. Emin misiniz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sil', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await NotificationService.deleteAllNotifications(userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tüm bildirimler silindi')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: NotificationService.getUserNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz bildirim yok',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return NotificationTile(notification: notifications[index]);
            },
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const NotificationTile({Key? key, required this.notification}) : super(key: key);

  IconData _getIcon() {
    switch (notification.type) {
      case 'message':
        return Icons.message;
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'appointment':
        return Icons.event;
      case 'follow':
        return Icons.person_add;
      case 'discount':
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case 'message':
        return Colors.blue;
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.green;
      case 'appointment':
        return Colors.orange;
      case 'follow':
        return Colors.purple;
      case 'discount':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return DateFormat('dd MMM').format(date);
  }

  void _handleTap(BuildContext context) async {
    // Okundu olarak işaretle
    if (!notification.isRead) {
      await NotificationService.markAsRead(notification.id);
    }

    // Aksiyona yönlendir
    if (notification.actionType == null || notification.actionId == null) return;

    switch (notification.actionType) {
      case 'ad':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdDetailScreen(adId: notification.actionId!),
          ),
        );
        break;
      case 'chat':
        // Chat ekranına git (chatId ile)
        // TODO: Chat screen implementation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mesaj ekranına gidiliyor...')),
        );
        break;
      case 'post':
        // Post detayına git
        // TODO: Post detail with postId
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paylaşım ekranına gidiliyor...')),
        );
        break;
      case 'user':
        // Kullanıcı profiline git
        // TODO: User profile screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil ekranına gidiliyor...')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        NotificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bildirim silindi'),
            action: SnackBarAction(
              label: 'GERİ AL',
              onPressed: () {
                // TODO: Undo implementation
              },
            ),
          ),
        );
      },
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getIcon(), color: color),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _handleTap(context),
        tileColor: notification.isRead ? null : color.withOpacity(0.05),
      ),
    );
  }
}
