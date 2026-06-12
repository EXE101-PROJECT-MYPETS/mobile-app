import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
<<<<<<< feature/notifications-update
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:petpee_mobile/common/toast/app_toast.dart';
import 'package:petpee_mobile/common/notification/store/notification_provider.dart';
import 'package:petpee_mobile/common/notification/model/notification_model.dart';
=======
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pawly_mobile/common/component/common_bottom_nav.dart';
import 'package:pawly_mobile/common/navigation/main_tab_navigation.dart';
import 'package:pawly_mobile/common/toast/app_toast.dart';
>>>>>>> main

import 'package:petpee_mobile/common/component/common_bottom_nav.dart';
import 'package:petpee_mobile/features/chat/screens/pet_ai_selection_screen.dart';
import 'package:petpee_mobile/apps/cart/page/cart_screen.dart';
import 'package:petpee_mobile/apps/profile/page/profile_screen.dart';
import 'package:petpee_mobile/apps/home/page/home_screen.dart';

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
          'icon': LucideIcons.calendarCheck,
          'color': Colors.pink,
          'bgColor': Colors.pink.shade50,
        };
      case 'CHAT_MESSAGE':
        return {
          'icon': LucideIcons.messageSquare,
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

  @override
  Widget build(BuildContext context) {
<<<<<<< feature/notifications-update
    final canPop = Navigator.canPop(context);
=======
    // Dữ liệu mock
    final notifications = [
      {
        'title': 'Đặt lịch Spa thành công!',
        'body':
            'Lịch spa của Buddy vào 10:00 AM, 22/04/2026 đã được xác nhận. Vui lòng mang bé đến đúng giờ nhé!',
        'time': 'Vừa xong',
        'isRead': false,
        'icon': LucideIcons.calendar_check,
        'color': Colors.pink,
        'bgColor': Colors.pink.shade50,
      },
      {
        'title': 'Đơn hàng đang giao',
        'body':
            'Đơn hàng thức ăn cho mèo của bạn đang được shipper Giao Hàng Nhanh vận chuyển. Sẽ đến trong hôm nay.',
        'time': '2 giờ trước',
        'isRead': false,
        'icon': LucideIcons.truck,
        'color': Colors.orange,
        'bgColor': Colors.orange.shade50,
      },
      {
        'title': 'Khuyến mãi 50% Giờ Vàng',
        'body':
            'Chỉ duy nhất hôm nay, giảm 50% cho tất cả dịch vụ Spa & Grooming. Nhanh tay đặt lịch ngay!',
        'time': '1 ngày trước',
        'isRead': true,
        'icon': LucideIcons.tag,
        'color': Colors.red,
        'bgColor': Colors.red.shade50,
      },
      {
        'title': 'Nhắc nhở tiêm phòng',
        'body':
            'Bé Lucy đã đến hạn tiêm phòng dại định kỳ hàng năm. Đặt lịch thú y để Pawly hỗ trợ nhé.',
        'time': '3 ngày trước',
        'isRead': true,
        'icon': LucideIcons.activity,
        'color': Colors.blue,
        'bgColor': Colors.blue.shade50,
      },
    ];
>>>>>>> main

    return WillPopScope(
      onWillPop: () async {
        if (canPop) {
          return true;
        } else {
          // Quay lại Trang chủ nếu không pop được (chuyển tab)
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
<<<<<<< feature/notifications-update
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          leading: canPop
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.black,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          title: Text(
            'Thông Báo',
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
                if (provider.notifications.isEmpty)
                  return const SizedBox.shrink();
                return IconButton(
                  icon: const Icon(
                    LucideIcons.checkCheck,
                    color: Colors.pink,
                    size: 22,
                  ),
                  onPressed: () async {
                    await provider.markAllRead();
                    if (mounted) {
                      showAppToast(
                        context,
                        message: 'Đã đánh dấu tất cả đã đọc',
                        type: AppToastType.success,
                      );
                    }
                  },
                  tooltip: 'Đánh dấu tất cả đã đọc',
                );
              },
=======
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => MainTabNavigation.backToPreviousOrHome(context),
        ),
        title: Text(
          'Thông Báo',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              LucideIcons.check_check,
              color: Colors.pink,
              size: 22,
>>>>>>> main
            ),
          ],
        ),
        body: Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.pink),
              );
            }

            final notifications = provider.notifications;

            if (notifications.isEmpty) {
              return Center(
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
                        LucideIcons.bellOff,
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
              );
            }

            return RefreshIndicator(
              onRefresh: () => provider.fetchNotifications(),
              color: Colors.pink,
              child: ListView.separated(
                itemCount: notifications.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Colors.black12),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  final style = _getNotificationStyle(notif.type);
                  final isRead = notif.isRead;

                  return GestureDetector(
                    onTap: () async {
                      if (!isRead) {
                        await provider.markAsRead(notif.id);
                      }

                      if (mounted) {
                        if (notif.type.contains('ORDER')) {
                          Navigator.of(context).pushNamed('/orders');
                        } else if (notif.type.contains('BOOKING') ||
                            notif.type.contains('SERVICE')) {
                          showAppToast(
                            context,
                            message: 'Lịch hẹn đang được xử lý',
                            type: AppToastType.info,
                          );
                        } else if (notif.type == 'CHAT_MESSAGE') {
                          Navigator.of(context).pushNamed('/conversations');
                        }
                      }
                    },
                    child: Container(
                      color: isRead
                          ? Colors.white
                          : Colors.pink.shade50.withOpacity(0.1),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif.title,
                                        style: TextStyle(
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
                                    Text(
                                      _getRelativeTime(notif.createdAt),
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notif.body,
                                  style: TextStyle(
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
          onTap: (index) {
            if (index == 0) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PetAiSelectionScreen(),
                ),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            } else if (index == 4) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
                (route) => false,
              );
            }
          },
        ),
      ),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 3,
        onTap: (index) =>
            MainTabNavigation.open(context, index, currentIndex: 3),
      ),
    );
  }
}
