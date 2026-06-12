import 'package:flutter/material.dart';
import '../api/notification_service.dart';
import '../model/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _notificationService.getUserNotifications();
    } catch (e) {
      debugPrint('Error fetching notifications in Provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    final success = await _notificationService.markAllRead();
    if (success) {
      _notifications = _notifications.map((n) {
        return NotificationModel(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
        );
      }).toList();
      notifyListeners();
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final success = await _notificationService.markAsRead(notificationId);
    if (success) {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final n = _notifications[index];
        _notifications[index] = NotificationModel(
          id: n.id,
          type: n.type,
          title: n.title,
          body: n.body,
          readAt: DateTime.now(),
          createdAt: n.createdAt,
        );
        notifyListeners();
      }
    }
  }
}
