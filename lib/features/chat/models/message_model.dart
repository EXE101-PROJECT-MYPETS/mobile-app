class MessageModel {
  final String id;
  final String conversationId;
  final String shopId;
  final String senderType; // 'CUSTOMER' or 'SHOP_USER'
  final String? senderCustomerId;
  final String? senderUserId;
  final String body;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.shopId,
    required this.senderType,
    this.senderCustomerId,
    this.senderUserId,
    required this.body,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'].toString(),
      conversationId: json['conversationId'].toString(),
      shopId: json['shopId'].toString(),
      senderType: json['senderType'] ?? 'CUSTOMER',
      senderCustomerId: json['senderCustomerId']?.toString(),
      senderUserId: json['senderUserId']?.toString(),
      body: json['body'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'shopId': shopId,
      'senderType': senderType,
      'senderCustomerId': senderCustomerId,
      'senderUserId': senderUserId,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
