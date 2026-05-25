import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:petpee_mobile/common/store/app_state.dart';

class CommonBottomNavBar extends StatelessWidget {
  const CommonBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final cartItemCount = context.watch<AppState>().cartItems.length;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFFFF5A4E),
      unselectedItemColor: const Color(0xFF6B7280),
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      onTap: onTap,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(LucideIcons.home),
          label: 'Trang chủ',
        ),
        const BottomNavigationBarItem(
          icon: Icon(LucideIcons.bot),
          label: 'Trợ lý AI',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: cartItemCount > 0,
            label: Text(cartItemCount.toString()),
            child: const Icon(LucideIcons.shoppingCart),
          ),
          label: 'Giỏ hàng',
        ),
        const BottomNavigationBarItem(
          icon: Icon(LucideIcons.bell),
          label: 'Thông báo',
        ),
        const BottomNavigationBarItem(
          icon: Icon(LucideIcons.user),
          label: 'Tôi',
        ),
      ],
    );
  }
}
