import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatService {
  // Mock Data
  static final List<MessageModel> _mockMessages = [
    MessageModel(
      id: '1',
      conversationId: '1',
      shopId: '1',
      senderType: 'CUSTOMER',
      senderCustomerId: '1',
      body: 'Chào shop, cho mình hỏi dịch vụ spa cho chó poodle bao nhiêu tiền ạ?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    MessageModel(
      id: '2',
      conversationId: '1',
      shopId: '1',
      senderType: 'SHOP_USER',
      senderUserId: '1',
      body: 'Chào bạn, bé poodle nhà bạn mấy kg rồi ạ?',
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    MessageModel(
      id: '3',
      conversationId: '1',
      shopId: '1',
      senderType: 'CUSTOMER',
      senderCustomerId: '1',
      body: 'Bé nhà mình tầm 4kg ạ.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
  ];

  static final List<ConversationModel> _mockConversations = [
    ConversationModel(
      id: '1',
      shopId: '1',
      customerId: '1',
      shopName: 'PetPee Spa & Hotel',
      shopAvatarUrl: 'https://images.unsplash.com/photo-1517849845537-4d257902454a',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      lastMessage: _mockMessages.last,
    ),
    ConversationModel(
      id: '2',
      shopId: '2',
      customerId: '1',
      shopName: 'Thú Y Mèo Ngoan',
      shopAvatarUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      lastMessage: MessageModel(
        id: '4',
        conversationId: '2',
        shopId: '2',
        senderType: 'SHOP_USER',
        body: 'Lịch khám lúc 3h chiều nay nhé bạn.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ),
  ];

  Future<List<ConversationModel>> getConversations() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockConversations;
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockMessages.where((m) => m.conversationId == conversationId).toList();
  }

  Future<MessageModel> sendMessage(String conversationId, String shopId, String body) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: conversationId,
      shopId: shopId,
      senderType: 'CUSTOMER',
      senderCustomerId: '1', // Mock user id
      body: body,
      createdAt: DateTime.now(),
    );
    _mockMessages.add(newMessage);
    
    // Update last message in conversation
    final index = _mockConversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final oldConv = _mockConversations[index];
      _mockConversations[index] = ConversationModel(
        id: oldConv.id,
        shopId: oldConv.shopId,
        customerId: oldConv.customerId,
        shopName: oldConv.shopName,
        shopAvatarUrl: oldConv.shopAvatarUrl,
        createdAt: oldConv.createdAt,
        lastMessage: newMessage,
      );
    }
    
    return newMessage;
  }
}
