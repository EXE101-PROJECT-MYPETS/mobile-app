import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/apps/checkout/model/checkout_response_model.dart';
import 'package:petpee_mobile/apps/home/page/home_screen.dart';
import 'package:petpee_mobile/apps/profile/page/orders_screen.dart';

class CheckoutSuccessScreen extends StatelessWidget {
  const CheckoutSuccessScreen({super.key, required this.response});

  final CheckoutResponseModel response;

  @override
  Widget build(BuildContext context) {
    final hasOrder = response.orderId != null || response.orderCode != null;
    final message = hasOrder
        ? 'Đơn hàng của bạn đang chờ shop xác nhận. PetPee sẽ cập nhật trạng thái đơn trong mục Đơn mua.'
        : 'Lịch dịch vụ của bạn đang chờ shop xác nhận. PetPee sẽ cập nhật trạng thái trong mục Đơn mua.';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _ShopeeLikeHeader(
              message: message,
              onBack: () => _goHome(context),
              onHome: () => _goHome(context),
              onOrders: () => _openOrders(context),
            ),
            const Expanded(child: ColoredBox(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  static void _goHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  static void _openOrders(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrdersScreen(initialTabIndex: 1),
      ),
    );
  }
}

class _ShopeeLikeHeader extends StatelessWidget {
  const _ShopeeLikeHeader({
    required this.message,
    required this.onBack,
    required this.onHome,
    required this.onOrders,
  });

  final String message;
  final VoidCallback onBack;
  final VoidCallback onHome;
  final VoidCallback onOrders;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, topPadding + 8, 12, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFF5A2C),
        gradient: LinearGradient(
          colors: [Color(0xFFFF6A3D), Color(0xFFFF4D2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Quay lại',
                onPressed: onBack,
                icon: const Icon(
                  LucideIcons.arrowLeft,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const Spacer(),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.messageCircle,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Icon(LucideIcons.alertCircle, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            'Đang chờ xác nhận',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeaderButton(label: 'Trang chủ', onPressed: onHome),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeaderButton(label: 'Đơn mua', onPressed: onOrders),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}
