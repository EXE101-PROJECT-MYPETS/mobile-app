import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pawly_mobile/common/component/common_bottom_nav.dart';
import 'package:pawly_mobile/common/navigation/main_tab_navigation.dart';
import 'package:pawly_mobile/common/toast/app_toast.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
            ),
            onPressed: () {
              showAppToast(
                context,
                message: 'Đã đánh dấu tất cả đã đọc',
                type: AppToastType.success,
              );
            },
            tooltip: 'Đánh dấu đã đọc',
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, color: Colors.black12),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final isRead = notif['isRead'] as bool;

          return GestureDetector(
            onTap: () {
              // Handle notification tap - navigate to relevant screen
              final title = notif['title'] as String;
              try {
                if (title.contains('Spa') || title.contains('lịch')) {
                  // TODO: Implement BookingsScreen
                  showAppToast(
                    context,
                    message: 'Chức năng sắp ra mắt',
                    type: AppToastType.info,
                  );
                } else if (title.contains('Đơn hàng') ||
                    title.contains('giao')) {
                  // TODO: Implement OrdersScreen
                  showAppToast(
                    context,
                    message: 'Chức năng sắp ra mắt',
                    type: AppToastType.info,
                  );
                } else if (title.contains('tiêm phòng') ||
                    title.contains('Nhắc')) {
                  // Navigate to pets screen
                  Navigator.of(context).pushNamed('/pets');
                }
              } catch (e) {
                showAppToast(
                  context,
                  message: 'Không thể mở màn hình',
                  type: AppToastType.error,
                );
              }
            },
            child: Container(
              color: isRead
                  ? Colors.white
                  : Colors.pink.shade50.withOpacity(0.3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: notif['bgColor'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      notif['icon'] as IconData,
                      color: notif['color'] as Color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                notif['title'] as String,
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  fontSize: 15,
                                  color: isRead ? Colors.black87 : Colors.black,
                                ),
                              ),
                            ),
                            Text(
                              notif['time'] as String,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          notif['body'] as String,
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
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 3,
        onTap: (index) =>
            MainTabNavigation.open(context, index, currentIndex: 3),
      ),
    );
  }
}
