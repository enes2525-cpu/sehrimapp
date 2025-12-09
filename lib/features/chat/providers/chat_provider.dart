import 'package:flutter/foundation.dart';
import '../../../data/models/conversation.dart';
import '../../../data/repositories/chat_repository.dart';

/// Chat Provider (Mesajlaşma)
class ChatProvider with ChangeNotifier {
  final ChatRepository _chatRepository = ChatRepository();

  List<Conversation> _conversations = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Conversation> get conversations => _conversations;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Konuşmaları yükle
  void loadConversations(String userId) {
    _chatRepository.getConversations(userId).listen((conversations) {
      _conversations = conversations;
      _unreadCount = conversations
          .fold<int>(0, (sum, conv) => sum + conv.unreadCount);
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  // Mesaj gönder
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    final result = await _chatRepository.sendMessage(
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      text: message,
    );

    if (result.isSuccess) {
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  // Okundu işaretle
  Future<void> markAsRead(String conversationId, String userId) async {
    await _chatRepository.markAsRead(conversationId, userId);
    loadConversations(userId);
  }
}
