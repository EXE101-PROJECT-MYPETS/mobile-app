import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:petpee_mobile/common/config/api_client.dart';
import 'package:petpee_mobile/common/config/api_config.dart';
import '../model/notification_model.dart';

class NotificationService {
  Future<List<NotificationModel>> getUserNotifications({int size = 40}) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/notifications/users/me?size=$size',
      );
      final response = await ApiClient.instance.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final content = decoded['content'] as List<dynamic>;
        return content
            .map(
              (json) =>
                  NotificationModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        debugPrint(
          'Failed to load user notifications: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      debugPrint('Error getting user notifications: $e');
      return [];
    }
  }

  Future<bool> markAllRead() async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/notifications/users/me/read-all',
      );
      final response = await ApiClient.instance.patch(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
      return false;
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/notifications/$notificationId/read',
      );
      final response = await ApiClient.instance.patch(uri);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking notification $notificationId as read: $e');
      return false;
    }
  }
}
