import 'dart:convert';
import 'package:pawly_mobile/common/config/api_client.dart';
import 'package:pawly_mobile/common/config/api_config.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatService {
  final ApiClient _client;

  ChatService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  Future<List<ConversationModel>> getConversations() async {
    final uri = Uri.parse(ApiConfig.chatConversationsUrl);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse is List) {
        return jsonResponse
            .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    throw Exception('Failed to load conversations: ${response.statusCode}');
  }

  Future<List<MessageModel>> getMessages(String conversationId) async {
    final allMessages = <MessageModel>[];
    int? cursor;
    bool hasNext = true;
    int guard = 0;

    while (hasNext && guard < 100) {
      final uri =
          Uri.parse('${ApiConfig.chatUrl}/$conversationId/messages').replace(
        queryParameters: {
          'size': '50',
          if (cursor != null) 'cursor': cursor.toString(),
        },
      );
      final response = await _client.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }

      final jsonResponse = json.decode(response.body);
      if (jsonResponse is! Map<String, dynamic>) {
        break;
      }

      final pageContent = jsonResponse['content'];
      if (pageContent is List) {
        allMessages.addAll(
          pageContent
              .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }

      hasNext = jsonResponse['hasNext'] == true;
      final nextCursorRaw = jsonResponse['nextCursor'];
      if (nextCursorRaw == null) {
        hasNext = false;
      } else {
        cursor = int.tryParse(nextCursorRaw.toString());
        if (cursor == null) {
          hasNext = false;
        }
      }
      guard++;
    }

    allMessages.sort((a, b) {
      final idA = int.tryParse(a.id) ?? 0;
      final idB = int.tryParse(b.id) ?? 0;
      return idA.compareTo(idB);
    });

    final deduped = <String, MessageModel>{};
    for (final message in allMessages) {
      deduped[message.id] = message;
    }
    return deduped.values.toList();
  }

  Future<MessageModel> sendMessage(
    String conversationId,
    String shopId,
    String body,
  ) async {
    final uri = Uri.parse('${ApiConfig.chatUrl}/$conversationId/messages');
    final response = await _client.post(
      uri,
      body: json.encode({'body': body, 'senderType': 'USER'}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      return MessageModel.fromJson(jsonResponse);
    }

    throw Exception('Failed to send message: ${response.statusCode}');
  }

  Future<ConversationModel> createConversation(String shopId) async {
    final uri = Uri.parse(ApiConfig.chatConversationsUrl);
    final response = await _client.post(
      uri,
      body: json.encode({'shopId': int.parse(shopId)}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      return ConversationModel.fromJson(jsonResponse);
    }

    throw Exception('Failed to create conversation: ${response.statusCode}');
  }
}
