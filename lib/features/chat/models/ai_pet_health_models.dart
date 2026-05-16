class AiPetHealthConversation {
  const AiPetHealthConversation({
    required this.id,
    required this.petId,
    required this.petName,
    required this.title,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int petId;
  final String petName;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AiPetHealthConversation.fromJson(Map<String, dynamic> json) {
    return AiPetHealthConversation(
      id: _parseInt(json['id']) ?? 0,
      petId: _parseInt(json['petId']) ?? 0,
      petName: json['petName']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }
}

class AiPetHealthMessage {
  const AiPetHealthMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.metadata = const {},
  });

  final int id;
  final String role;
  final String content;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  bool get isUser => role.trim().toUpperCase() == 'USER';
  String? get riskLevel => metadata['riskLevel']?.toString();
  bool get shouldBookVet => metadata['shouldBookVet'] == true;
  AiAction? get action {
    final actionRaw = metadata['action'];
    if (actionRaw is Map<String, dynamic>) {
      return AiAction.fromJson(actionRaw);
    }
    return null;
  }

  factory AiPetHealthMessage.fromJson(Map<String, dynamic> json) {
    final metadataRaw = json['metadata'];
    return AiPetHealthMessage(
      id: _parseInt(json['id']) ?? 0,
      role: json['role']?.toString() ?? 'ASSISTANT',
      content: json['content']?.toString() ?? '',
      metadata: metadataRaw is Map<String, dynamic> ? metadataRaw : const {},
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class AiPetHealthChatResponse {
  const AiPetHealthChatResponse({
    required this.conversationId,
    required this.answer,
    this.riskLevel,
    this.shouldBookVet = false,
    this.recommendedActions = const [],
    this.action,
  });

  final int conversationId;
  final String answer;
  final String? riskLevel;
  final bool shouldBookVet;
  final List<String> recommendedActions;
  final AiAction? action;

  factory AiPetHealthChatResponse.fromJson(Map<String, dynamic> json) {
    final actionsRaw = json['recommendedActions'];
    final actionRaw = json['action'];
    return AiPetHealthChatResponse(
      conversationId: _parseInt(json['conversationId']) ?? 0,
      answer: json['answer']?.toString() ?? '',
      riskLevel: json['riskLevel']?.toString(),
      shouldBookVet: json['shouldBookVet'] == true,
      recommendedActions: actionsRaw is List
          ? actionsRaw.map((item) => item.toString()).toList(growable: false)
          : const [],
      action: actionRaw is Map<String, dynamic>
          ? AiAction.fromJson(actionRaw)
          : null,
    );
  }

  Map<String, dynamic> toMetadata() {
    return {
      if (riskLevel != null) 'riskLevel': riskLevel,
      'shouldBookVet': shouldBookVet,
      'recommendedActions': recommendedActions,
      if (action != null) 'action': action!.toJson(),
    };
  }
}

typedef AiChatResponse = AiPetHealthChatResponse;

class AiAction {
  const AiAction({
    required this.type,
    this.toolName,
    required this.arguments,
    required this.missingFields,
  });

  final String type;
  final String? toolName;
  final Map<String, dynamic> arguments;
  final List<String> missingFields;

  factory AiAction.fromJson(Map<String, dynamic> json) {
    final argumentsRaw = json['arguments'];
    final missingFieldsRaw = json['missingFields'];
    return AiAction(
      type: json['type']?.toString() ?? 'NONE',
      toolName: json['toolName']?.toString(),
      arguments: argumentsRaw is Map<String, dynamic> ? argumentsRaw : const {},
      missingFields: missingFieldsRaw is List
          ? missingFieldsRaw
                .map((item) => item.toString())
                .toList(growable: false)
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (toolName != null) 'toolName': toolName,
      'arguments': arguments,
      'missingFields': missingFields,
    };
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
