import 'package:pawly_mobile/common/utils/image_url_util.dart';

import 'message_model.dart';

class ConversationModel {
  final String id;
  final String shopId;
  final String customerId;
  final String shopName; // Thêm trường này để dễ hiển thị UI
  final String? shopAvatarUrl; // Thêm trường avatar
  final DateTime createdAt;
  final MessageModel? lastMessage; // Tin nhắn cuối cùng

  ConversationModel({
    required this.id,
    required this.shopId,
    required this.customerId,
    required this.shopName,
    this.shopAvatarUrl,
    required this.createdAt,
    this.lastMessage,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'].toString(),
      shopId: json['shopId'].toString(),
      customerId: json['customerId'].toString(),
      shopName: json['shopName'] ?? 'Shop ${json['shopId']}',
      shopAvatarUrl: ImageUrlUtil.buildPublicUrl(
        json['shopAvatarUrl']?.toString(),
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'customerId': customerId,
      'shopName': shopName,
      'shopAvatarUrl': shopAvatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastMessage': lastMessage?.toJson(),
    };
  }
}
