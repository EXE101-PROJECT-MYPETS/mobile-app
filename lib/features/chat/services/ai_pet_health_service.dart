import 'dart:convert';

import 'package:pawly_mobile/common/config/api_client.dart';
import 'package:pawly_mobile/common/config/api_config.dart';
import 'package:pawly_mobile/features/chat/models/ai_pet_health_models.dart';

class AiPetHealthService {
  AiPetHealthService({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<AiPetHealthConversation> getOrCreateConversation(int petId) async {
    final uri = Uri.parse(ApiConfig.aiPetHealthGetOrCreateConversationUrl);
    final response = await _client.post(
      uri,
      body: jsonEncode({'petId': petId}),
      includeContextHeaders: false,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AiPetHealthConversation.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception('Không thể mở cuộc trò chuyện AI: ${response.statusCode}');
  }

  Future<List<AiPetHealthMessage>> getMessages(int conversationId) async {
    final uri = Uri.parse(
      '${ApiConfig.aiPetHealthConversationsUrl}/$conversationId/messages',
    );
    final response = await _client.get(uri, includeContextHeaders: false);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse is! List) return [];
      return jsonResponse
          .map(
            (item) => AiPetHealthMessage.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    throw Exception('Không thể tải tin nhắn AI: ${response.statusCode}');
  }

  Future<AiPetHealthChatResponse> sendMessage({
    required int petId,
    int? conversationId,
    required String message,
  }) async {
    final uri = Uri.parse(ApiConfig.aiPetHealthChatUrl);
    final payload = <String, Object?>{'petId': petId, 'message': message};
    if (conversationId != null) {
      payload['conversationId'] = conversationId;
    }

    final response = await _client.post(
      uri,
      body: jsonEncode(payload),
      includeContextHeaders: false,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return AiPetHealthChatResponse.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception('Không thể gửi tin nhắn AI: ${response.statusCode}');
  }
}
