import 'package:flutter/foundation.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/chat_socket_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final ChatSocketService _chatSocketService = ChatSocketService();

  List<ConversationModel> _conversations = [];
  List<ConversationModel> get conversations => _conversations;

  List<MessageModel> _currentMessages = [];
  List<MessageModel> get currentMessages => _currentMessages;

  String? _activeConversationId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _compareMessages(MessageModel a, MessageModel b) {
    final idA = int.tryParse(a.id) ?? 0;
    final idB = int.tryParse(b.id) ?? 0;
    return idA.compareTo(idB);
  }

  void _upsertCurrentMessage(MessageModel message) {
    final index = _currentMessages.indexWhere((item) => item.id == message.id);
    if (index == -1) {
      _currentMessages.add(message);
    } else {
      _currentMessages[index] = message;
    }
    _currentMessages.sort(_compareMessages);
  }

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

  Future<void> openConversation(String conversationId, {String? shopId}) async {
    _activeConversationId = conversationId;
    await fetchMessages(conversationId);
    await _chatSocketService.listenToConversation(
      conversationId,
      _handleIncomingMessage,
      shopId: shopId,
    );
  }

  Future<ConversationModel> openConversationForShop(String shopId) async {
    await fetchConversations();

    final existingIndex = _conversations.indexWhere(
      (conversation) => conversation.shopId == shopId,
    );
    if (existingIndex != -1) {
      return _conversations[existingIndex];
    }

    final createdConversation = await _chatService.createConversation(shopId);
    await fetchConversations();
    return createdConversation;
  }

  void _handleIncomingMessage(MessageModel message) {
    if (_activeConversationId != message.conversationId) {
      fetchConversations();
      return;
    }

    _upsertCurrentMessage(message);
    notifyListeners();
    fetchConversations();
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
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: targetConvId,
        shopId: shopId,
        senderType: 'USER',
        body: body,
        createdAt: DateTime.now(),
      );
      _currentMessages.add(tempMsg);
      _currentMessages.sort(_compareMessages);
      notifyListeners();

      final realMsg = await _chatService.sendMessage(
        targetConvId,
        shopId,
        body,
      );
      _currentMessages.removeWhere((m) => m.id == tempMsg.id);
      _upsertCurrentMessage(realMsg);
      notifyListeners();

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

  Future<void> stopListening() async {
    _activeConversationId = null;
    await _chatSocketService.disconnect();
  }
}
