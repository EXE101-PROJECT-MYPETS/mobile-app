import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ConversationModel> _conversations = [];
  List<ConversationModel> get conversations => _conversations;

  List<MessageModel> _currentMessages = [];
  List<MessageModel> get currentMessages => _currentMessages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _conversations = await _chatService.getConversations();
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String conversationId) async {
    _isLoading = true;
    // Don't clear immediately to avoid flickering, or clear if needed
    notifyListeners();

    try {
      _currentMessages = await _chatService.getMessages(conversationId);
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(
    String conversationId,
    String shopId,
    String body,
  ) async {
    if (body.trim().isEmpty) return;

    // Optimistic UI update
    final tempMsg = MessageModel(
      id: 'temp_\${DateTime.now().millisecondsSinceEpoch}',
      conversationId: conversationId,
      shopId: shopId,
      senderType: 'CUSTOMER',
      body: body,
      createdAt: DateTime.now(),
    );
    _currentMessages.add(tempMsg);
    notifyListeners();

    try {
      final realMsg = await _chatService.sendMessage(
        conversationId,
        shopId,
        body,
      );
      // Replace temp with real
      final index = _currentMessages.indexWhere((m) => m.id == tempMsg.id);
      if (index != -1) {
        _currentMessages[index] = realMsg;
      }

      // Update conversations list so the last message is correct
      await fetchConversations();
    } catch (e) {
      // Revert optimistic update
      _currentMessages.removeWhere((m) => m.id == tempMsg.id);
      debugPrint('Error sending message: $e');
      notifyListeners();
    }
  }
}
