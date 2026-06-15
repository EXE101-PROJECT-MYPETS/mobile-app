import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pawly_mobile/common/component/common_bottom_nav.dart';
import 'package:pawly_mobile/common/navigation/main_tab_navigation.dart';
import 'package:pawly_mobile/common/notification/store/notification_provider.dart';
import 'package:pawly_mobile/common/toast/app_toast.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationProvider>().fetchNotifications();
      }
    });
  }

  String _getRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    }
  }

  Map<String, dynamic> _getNotificationStyle(String type) {
    switch (type) {
      case 'ORDER_CREATED':
      case 'ORDER_STATUS_UPDATED':
      case 'PAYMENT_CONFIRMED':
        return {
          'icon': LucideIcons.truck,
          'color': Colors.orange,
          'bgColor': Colors.orange.shade50,
        };
      case 'BOOKING_CREATED':
      case 'BOOKING_STATUS_UPDATED':
      case 'SERVICE_BOOKED':
        return {
          'icon': LucideIcons.calendar_check,
          'color': Colors.pink,
          'bgColor': Colors.pink.shade50,
        };
      case 'CHAT_MESSAGE':
        return {
          'icon': LucideIcons.message_square,
          'color': Colors.blue,
          'bgColor': Colors.blue.shade50,
        };
      case 'GENERAL':
      default:
        return {
          'icon': LucideIcons.bell,
          'color': Colors.red,
          'bgColor': Colors.red.shade50,
        };
    }
  }

  Future<void> _openNotification(
    NotificationProvider provider,
    int notificationId,
    String type,
    bool isRead,
  ) async {
    if (!isRead) {
      await provider.markAsRead(notificationId);
    }

    if (!mounted) return;
    if (type.contains('ORDER')) {
      Navigator.of(context).pushNamed('/orders');
    } else if (type.contains('BOOKING') || type.contains('SERVICE')) {
      showAppToast(
        context,
        message: 'Lịch hẹn đang được xử lý',
        type: AppToastType.info,
      );
    } else if (type == 'CHAT_MESSAGE') {
      Navigator.of(context).pushNamed('/conversations');
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        MainTabNavigation.backToPreviousOrHome(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () => MainTabNavigation.backToPreviousOrHome(context),
          ),
          title: Text(
            'Thông báo',
            style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
            Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                if (provider.notifications.isEmpty) {
                  return const SizedBox.shrink();
                }

                return IconButton(
                  icon: const Icon(
                    LucideIcons.check_check,
                    color: Colors.pink,
                    size: 22,
                  ),
                  onPressed: provider.unreadCount == 0
                      ? null
                      : () async {
                          await provider.markAllRead();
                          if (!context.mounted) return;
                          showAppToast(
                            context,
                            message: 'Đã đánh dấu tất cả đã đọc',
                            type: AppToastType.success,
                          );
                        },
                  tooltip: 'Đánh dấu tất cả đã đọc',
                );
              },
            ),
          ],
        ),
        body: Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.notifications.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.pink),
              );
            }

            final notifications = provider.notifications;
            if (notifications.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.bell_off,
                          size: 48,
                          color: Colors.pink,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không có thông báo nào',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bạn sẽ nhận được thông báo khi có hoạt động mới.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: provider.fetchNotifications,
              color: Colors.pink,
              child: ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Colors.black12),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final style = _getNotificationStyle(notification.type);
                  final isRead = notification.isRead;

                  return InkWell(
                    onTap: () => _openNotification(
                      provider,
                      notification.id,
                      notification.type,
                      isRead,
                    ),
                    child: Container(
                      color: isRead
                          ? Colors.white
                          : Colors.pink.shade50.withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: style['bgColor'] as Color,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              style['icon'] as IconData,
                              color: style['color'] as Color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontWeight: isRead
                                              ? FontWeight.w600
                                              : FontWeight.bold,
                                          fontSize: 15,
                                          color: isRead
                                              ? Colors.black87
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _getRelativeTime(notification.createdAt),
                                      style: GoogleFonts.inter(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notification.body,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: isRead
                                        ? Colors.grey.shade600
                                        : Colors.black87,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        bottomNavigationBar: CommonBottomNavBar(
          currentIndex: 3,
          onTap: (index) =>
              MainTabNavigation.open(context, index, currentIndex: 3),
        ),
      ),
    );
  }
}
