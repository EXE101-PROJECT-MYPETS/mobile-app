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
      if (conversationId == 'temp_conv') {
        _currentMessages = [];
      } else {
        _currentMessages = await _chatService.getMessages(conversationId);
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> sendMessage(
    String conversationId,
    String shopId,
    String body,
  ) async {
    if (body.trim().isEmpty) return null;

    String targetConvId = conversationId;

    try {
      if (targetConvId == 'temp_conv') {
        final newConv = await _chatService.createConversation(shopId);
        targetConvId = newConv.id;
      }

      // Optimistic UI update
      final tempMsg = MessageModel(
        id: 'temp_\${DateTime.now().millisecondsSinceEpoch}',
        conversationId: targetConvId,
        shopId: shopId,
        senderType: 'USER',
        body: body,
        createdAt: DateTime.now(),
      );
      _currentMessages.add(tempMsg);
      notifyListeners();

      final realMsg = await _chatService.sendMessage(
        targetConvId,
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

      return targetConvId;
    } catch (e) {
      // Revert optimistic update if there was one
      _currentMessages.removeWhere((m) => m.id.startsWith('temp_'));
      debugPrint('Error sending message: $e');
      notifyListeners();
      return null;
    }
  }
}
