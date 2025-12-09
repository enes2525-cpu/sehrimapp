import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sehrimapp/data/models/chat_model.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Konuşma oluştur veya mevcut konuşmayı getir
  Future<String> getOrCreateConversation({
    required String adId,
    required String adTitle,
    required String sellerId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Giriş yapmalısınız';

    final buyerId = user.uid;

    // Mevcut konuşmayı ara
    final existingConversation = await _firestore
        .collection('conversations')
        .where('adId', isEqualTo: adId)
        .where('buyerId', isEqualTo: buyerId)
        .where('sellerId', isEqualTo: sellerId)
        .limit(1)
        .get();

    if (existingConversation.docs.isNotEmpty) {
      return existingConversation.docs.first.id;
    }

    // Yeni konuşma oluştur
    final conversationRef = await _firestore.collection('conversations').add({
      'adId': adId,
      'adTitle': adTitle,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return conversationRef.id;
  }

  // Mesaj gönder
  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'Giriş yapmalısınız';

    // Mesajı kaydet
    await _firestore.collection('messages').add({
      'conversationId': conversationId,
      'senderId': user.uid,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Konuşmayı güncelle
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': FieldValue.increment(1),
    });
  }

  // Mesajları getir
  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  // Kullanıcının konuşmalarını getir
  Stream<List<Conversation>> getUserConversations() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('buyerId', isEqualTo: user.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((buyerSnapshot) async {
      // Satıcı olarak konuşmaları da getir
      final sellerSnapshot = await _firestore
          .collection('conversations')
          .where('sellerId', isEqualTo: user.uid)
          .orderBy('lastMessageTime', descending: true)
          .get();

      final allDocs = [...buyerSnapshot.docs, ...sellerSnapshot.docs];
      return allDocs.map((doc) => Conversation.fromFirestore(doc)).toList();
    });
  }

  // Mesajları okundu olarak işaretle
  Future<void> markAsRead(String conversationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final messages = await _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .where('receiverId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in messages.docs) {
      await doc.reference.update({'isRead': true});
    }

    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCount': 0,
    });
  }
}