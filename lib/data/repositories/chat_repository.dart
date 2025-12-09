import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/result.dart';
import '../../core/constants/app_constants.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import 'token_repository.dart';

/// Message Model (basitleştirilmiş)
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isRead;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      chatId: data['chatId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }
}

/// Chat işlemlerini yöneten Repository
/// Mesajlaşma + Token kontrolü + Bildirim
class ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TokenRepository _tokenRepository;

  ChatRepository({
    TokenRepository? tokenRepository,
  }) : _tokenRepository = tokenRepository ?? TokenRepository();

  // ========== CHAT İŞLEMLERİ ==========

  /// Chat oluştur veya mevcut chat'i getir
  Future<Result<String>> getOrCreateChat(
    String user1Id,
    String user2Id,
  ) async {
    try {
      if (user1Id == user2Id) {
        return Result.error('Kendinize mesaj gönderemezsiniz');
      }

      // Mevcut chat var mı kontrol et
      final existingChat = await _db
          .collection(AppConstants.collectionChats)
          .where('participants', arrayContains: user1Id)
          .get();

      for (var doc in existingChat.docs) {
        final participants = List<String>.from(doc.data()['participants'] ?? []);
        if (participants.contains(user2Id)) {
          return Result.success(doc.id);
        }
      }

      // Yeni chat oluştur
      final chatData = {
        'participants': [user1Id, user2Id],
        'participantNames': {}, // TODO: İsimleri ekle
        'lastMessage': null,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final chatDoc = await _db.collection(AppConstants.collectionChats).add(chatData);

      return Result.success(chatDoc.id);
    } catch (e) {
      return Result.error('Chat oluşturulurken hata: ${e.toString()}');
    }
  }

  /// Chat bilgilerini getir
  Future<Result<Conversation>> getChat(String chatId) async {
    try {
      final chatDoc = await _db
          .collection(AppConstants.collectionChats)
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        return Result.error('Chat bulunamadı');
      }

      final chat = Conversation.fromFirestore(chatDoc);
      return Result.success(chat);
    } catch (e) {
      return Result.error('Chat yüklenirken hata: ${e.toString()}');
    }
  }

  // ========== KONUŞMALAR (CONVERSATIONS) ==========

  /// Kullanıcının tüm konuşmalarını getir (Stream)
  Stream<List<Conversation>> getConversations(String userId) {
    return _db
        .collection(AppConstants.collectionChats)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Conversation.fromFirestore(doc)).toList());
  }

  /// Okunmamış mesaj sayısı (tüm chatler)
  Stream<int> getUnreadMessageCount(String userId) {
    return _db
        .collection(AppConstants.collectionChats)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (var chat in snapshot.docs) {
        final data = chat.data();
        if (data['lastMessageSender'] != userId && 
            data['lastMessage'] != null) {
          count++;
        }
      }
      return count;
    });
  }

  // ========== MESAJ GÖNDERME ==========

  /// Mesaj gönder (Token kontrolü ile)
  Future<Result<String>> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String text,
    bool requireToken = true,
  }) async {
    try {
      // Boş mesaj kontrolü
      if (text.trim().isEmpty) {
        return Result.error('Mesaj boş olamaz');
      }

      // Token kontrolü (ilk mesaj ücretsiz)
      if (requireToken) {
        final firstMessage = await _isFirstMessage(chatId);
        
        if (!firstMessage) {
          // Token kontrolü yap
          final hasEnough = await _tokenRepository.hasEnoughTokens(
            senderId,
            AppConstants.tokenPerMessage,
          );

          if (!hasEnough) {
            return Result.error(
              'Yetersiz token. Mesaj göndermek için ${AppConstants.tokenPerMessage} token gerekli.',
            );
          }

          // Token düş
          final deductResult = await _tokenRepository.deductTokens(
            senderId,
            AppConstants.tokenPerMessage,
            reason: 'Mesaj gönderme',
            metadata: {'chatId': chatId},
          );

          if (!deductResult.isSuccess) {
            return Result.error(deductResult.error ?? 'Token düşülemedi');
          }
        }
      }

      // Mesaj oluştur
      final message = Message(
        id: '',
        chatId: chatId,
        senderId: senderId,
        text: text,
        createdAt: DateTime.now(),
      );

      final messageDoc = await _db
          .collection(AppConstants.collectionMessages)
          .add(message.toMap());

      // Chat'i güncelle (son mesaj bilgisi)
      await _db.collection(AppConstants.collectionChats).doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': senderId,
      });

      // Bildirim gönder
      await _sendMessageNotification(
        senderId: senderId,
        receiverId: receiverId,
        chatId: chatId,
      );

      return Result.success(messageDoc.id);
    } catch (e) {
      return Result.error('Mesaj gönderilirken hata: ${e.toString()}');
    }
  }

  /// İlk mesaj mı kontrol et
  Future<bool> _isFirstMessage(String chatId) async {
    final messages = await _db
        .collection(AppConstants.collectionMessages)
        .where('chatId', isEqualTo: chatId)
        .limit(1)
        .get();

    return messages.docs.isEmpty;
  }

  // ========== MESAJLAR ==========

  /// Chat mesajlarını getir (Stream)
  Stream<List<Message>> getMessages(String chatId, {int limit = 50}) {
    return _db
        .collection(AppConstants.collectionMessages)
        .where('chatId', isEqualTo: chatId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  /// Mesajları okundu olarak işaretle
  Future<Result<void>> markMessagesAsRead(String chatId, String userId) async {
    try {
      final messages = await _db
          .collection(AppConstants.collectionMessages)
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      return Result.success(null);
    } catch (e) {
      return Result.error('Mesajlar işaretlenirken hata: ${e.toString()}');
    }
  }

  /// Okunmamış mesaj sayısı (tek chat)
  Future<Result<int>> getUnreadCount(String chatId, String userId) async {
    try {
      final messages = await _db
          .collection(AppConstants.collectionMessages)
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return Result.success(messages.docs.length);
    } catch (e) {
      return Result.error('Okunmamış sayı hesaplanırken hata: ${e.toString()}');
    }
  }

  // ========== MESAJ SİLME ==========

  /// Mesaj sil
  Future<Result<void>> deleteMessage(String messageId, String userId) async {
    try {
      final messageDoc = await _db
          .collection(AppConstants.collectionMessages)
          .doc(messageId)
          .get();

      if (!messageDoc.exists) {
        return Result.error('Mesaj bulunamadı');
      }

      final senderId = messageDoc.data()?['senderId'];
      if (senderId != userId) {
        return Result.error('Bu mesajı silme yetkiniz yok');
      }

      await _db
          .collection(AppConstants.collectionMessages)
          .doc(messageId)
          .delete();

      return Result.success(null);
    } catch (e) {
      return Result.error('Mesaj silinirken hata: ${e.toString()}');
    }
  }

  /// Konuşmayı sil (tüm mesajlar)
  Future<Result<void>> deleteConversation(String chatId, String userId) async {
    try {
      // Chat'e erişim kontrolü
      final chatDoc = await _db
          .collection(AppConstants.collectionChats)
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        return Result.error('Chat bulunamadı');
      }

      final participants = List<String>.from(
        chatDoc.data()?['participants'] ?? [],
      );

      if (!participants.contains(userId)) {
        return Result.error('Bu konuşmaya erişim yetkiniz yok');
      }

      // Tüm mesajları sil
      final messages = await _db
          .collection(AppConstants.collectionMessages)
          .where('chatId', isEqualTo: chatId)
          .get();

      final batch = _db.batch();
      for (var doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // Chat'i sil
      batch.delete(_db.collection(AppConstants.collectionChats).doc(chatId));

      await batch.commit();

      return Result.success(null);
    } catch (e) {
      return Result.error('Konuşma silinirken hata: ${e.toString()}');
    }
  }

  // ========== MESAJ ARAMA ==========

  /// Mesajlarda ara
  Future<Result<List<Message>>> searchMessages(
    String chatId,
    String query,
  ) async {
    try {
      if (query.trim().isEmpty) {
        return Result.success([]);
      }

      // Firestore full-text search yok, basit contains kullanalım
      final messages = await _db
          .collection(AppConstants.collectionMessages)
          .where('chatId', isEqualTo: chatId)
          .get();

      final filteredMessages = messages.docs
          .map((doc) => Message.fromFirestore(doc))
          .where((msg) => msg.text.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return Result.success(filteredMessages);
    } catch (e) {
      return Result.error('Arama yapılırken hata: ${e.toString()}');
    }
  }

  // ========== BİLDİRİM ==========

  /// Mesaj bildirimi gönder
  Future<void> _sendMessageNotification({
    required String senderId,
    required String receiverId,
    required String chatId,
  }) async {
    try {
      // Gönderen kullanıcı bilgisi
      final senderDoc = await _db
          .collection(AppConstants.collectionUsers)
          .doc(senderId)
          .get();

      final senderName = senderDoc.data()?['name'] ?? 'Bir kullanıcı';

      // Bildirim gönder
      await NotificationService.notifyNewMessage(
        recipientId: receiverId,
        senderName: senderName,
        chatId: chatId,
      );
    } catch (e) {
      // Bildirim hatası uygulamayı durdurmamalı
      print('Bildirim gönderilemedi: $e');
    }
  }

  // ========== İSTATİSTİKLER ==========

  /// Toplam mesaj sayısı
  Future<Result<int>> getTotalMessageCount(String chatId) async {
    try {
      final messages = await _db
          .collection(AppConstants.collectionMessages)
          .where('chatId', isEqualTo: chatId)
          .get();

      return Result.success(messages.docs.length);
    } catch (e) {
      return Result.error('Mesaj sayısı hesaplanırken hata: ${e.toString()}');
    }
  }

  /// Chat istatistikleri
  Future<Result<Map<String, dynamic>>> getChatStats(
    String chatId,
    String userId,
  ) async {
    try {
      final allMessages = await _db
          .collection(AppConstants.collectionMessages)
          .where('chatId', isEqualTo: chatId)
          .get();

      final userMessages = allMessages.docs
          .where((doc) => doc.data()['senderId'] == userId)
          .length;

      final otherMessages = allMessages.docs.length - userMessages;

      final unreadResult = await getUnreadCount(chatId, userId);

      final stats = {
        'totalMessages': allMessages.docs.length,
        'userMessages': userMessages,
        'otherMessages': otherMessages,
        'unreadMessages': unreadResult.data ?? 0,
      };

      return Result.success(stats);
    } catch (e) {
      return Result.error('İstatistikler hesaplanırken hata: ${e.toString()}');
    }
  }

  // ========== OKUNDU İŞARETLE ==========

  /// Konuşmadaki tüm mesajları okundu olarak işaretle
  Future<Result<void>> markAsRead(String chatId, String userId) async {
    try {
      // Kullanıcının okunmamış mesajlarını bul
      final messagesSnapshot = await _db
          .collection(AppConstants.collectionMessages)
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      // Batch update
      final batch = _db.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      // Batch commit
      await batch.commit();

      // Chat'teki unreadCount'u sıfırla
      await _db.collection(AppConstants.collectionChats).doc(chatId).update({
        'unreadCounts.$userId': 0,
      });

      return Result.success(null);
    } catch (e) {
      return Result.error('Mesajlar okundu işaretlenirken hata: ${e.toString()}');
    }
  }
}
