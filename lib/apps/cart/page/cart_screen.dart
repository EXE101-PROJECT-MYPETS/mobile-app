import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pawly_mobile/apps/cart/model/cart_item_model.dart';
import 'package:pawly_mobile/apps/checkout/page/checkout_screen.dart';
import 'package:pawly_mobile/common/component/common_bottom_nav.dart';
import 'package:pawly_mobile/common/navigation/main_tab_navigation.dart';
import 'package:pawly_mobile/common/store/app_state.dart';
import 'package:pawly_mobile/common/toast/app_toast.dart';
import 'package:pawly_mobile/common/utils/price_formatter.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selectedItems = state.selectedCartItems;
    final productItems = state.cartItems
        .where((item) => !item.isService)
        .toList();
    final serviceItems = state.cartItems
        .where((item) => item.isService)
        .toList();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Color(0xFF111827)),
          onPressed: () => MainTabNavigation.backToPreviousOrHome(context),
        ),
        title: Text(
          'Giỏ hàng',
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: selectedItems.isEmpty && state.cartItems.isEmpty
                ? const _EmptyCartState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _CartSectionHeader(
                        title: 'Sản phẩm mua sắm',
                        subtitle: '${productItems.length} sản phẩm',
                      ),
                      const SizedBox(height: 12),
                      if (productItems.isEmpty)
                        const _SectionEmptyState(
                          message: 'Chưa có sản phẩm mua sắm nào trong giỏ.',
                        )
                      else
                        ...productItems.map(
                          (item) => _ProductCartItemCard(
                            item: item,
                            currencyFormat: currencyFormat,
                            onIncrease: () => context
                                .read<AppState>()
                                .updateCartQuantity(item.id, 1),
                            onDecrease: () => context
                                .read<AppState>()
                                .updateCartQuantity(item.id, -1),
                            onToggleSelected: (value) => context
                                .read<AppState>()
                                .toggleCartSelection(item.id, value),
                            onDelete: () => context
                                .read<AppState>()
                                .removeFromCart(item.id),
                          ),
                        ),
                      const SizedBox(height: 20),
                      _CartSectionHeader(
                        title: 'Dịch vụ Spa đặt lịch',
                        subtitle: '${serviceItems.length} dịch vụ',
                      ),
                      const SizedBox(height: 12),
                      if (serviceItems.isEmpty)
                        const _SectionEmptyState(
                          message: 'Chưa có dịch vụ spa nào trong giỏ.',
                        )
                      else
                        ...serviceItems.map(
                          (item) => _ServiceCartItemCard(
                            item: item,
                            currencyFormat: currencyFormat,
                            onToggleSelected: (value) => context
                                .read<AppState>()
                                .toggleCartSelection(item.id, value),
                            onDelete: () => context
                                .read<AppState>()
                                .removeFromCart(item.id),
                          ),
                        ),
                    ],
                  ),
          ),
          if (state.cartItems.isNotEmpty)
            _CartBottomBar(
              totalAmount: state.cartTotalPrice,
              selectedCount: selectedItems.length,
              onCheckout: () {
                if (selectedItems.isEmpty) {
                  showAppToast(
                    context,
                    message: 'Vui lòng chọn ít nhất một sản phẩm hoặc dịch vụ.',
                    type: AppToastType.warning,
                  );
                  return;
                }

                final shopIds = selectedItems
                    .map((item) => item.shopId)
                    .toSet();
                if (shopIds.length > 1) {
                  showAppToast(
                    context,
                    message:
                        'Chỉ hỗ trợ thanh toán các mục trong cùng một shop.',
                    type: AppToastType.warning,
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CheckoutScreen(selectedItems: selectedItems),
                  ),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 2,
        onTap: (index) =>
            MainTabNavigation.open(context, index, currentIndex: 2),
      ),
    );
  }
}

class _CartSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CartSectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  final String message;

  const _SectionEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
      ),
    );
  }
}

class _ProductCartItemCard extends StatelessWidget {
  final CartItem item;
  final NumberFormat currencyFormat;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final ValueChanged<bool?> onToggleSelected;
  final VoidCallback onDelete;

  const _ProductCartItemCard({
    required this.item,
    required this.currencyFormat,
    required this.onIncrease,
    required this.onDecrease,
    required this.onToggleSelected,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.isSelected,
            activeColor: const Color(0xFFFB7185),
            onChanged: onToggleSelected,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.pets, color: Color(0xFF94A3B8)),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                if ((item.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      currencyFormat.format(item.unitPrice),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(LucideIcons.trash_2, size: 18),
                      color: const Color(0xFF94A3B8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _RoundActionButton(
                      icon: LucideIcons.minus,
                      onTap: onDecrease,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'x${item.quantity}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    _RoundActionButton(
                      icon: LucideIcons.plus,
                      onTap: onIncrease,
                    ),
                    const Spacer(),
                    Text(
                      PriceFormatter.formatVnd(item.amount),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCartItemCard extends StatelessWidget {
  final CartItem item;
  final NumberFormat currencyFormat;
  final ValueChanged<bool?> onToggleSelected;
  final VoidCallback onDelete;

  const _ServiceCartItemCard({
    required this.item,
    required this.currencyFormat,
    required this.onToggleSelected,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.isSelected,
            activeColor: const Color(0xFFFB7185),
            onChanged: onToggleSelected,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 72,
                  height: 72,
                  color: const Color(0xFFFDF2F8),
                  child: const Icon(Icons.spa, color: Color(0xFFFB7185)),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Spa',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFBE185D),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(LucideIcons.trash_2, size: 18),
                      color: const Color(0xFF94A3B8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                if (item.durationMin != null && item.durationMin! > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Thời lượng dự kiến: ${item.durationMin} phút',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
                if ((item.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      currencyFormat.format(item.unitPrice),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Số lượng: ${item.quantity}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    PriceFormatter.formatVnd(item.amount),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF111827)),
      ),
    );
  }
}

class _CartBottomBar extends StatelessWidget {
  final double totalAmount;
  final int selectedCount;
  final VoidCallback onCheckout;

  const _CartBottomBar({
    required this.totalAmount,
    required this.selectedCount,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Đã chọn $selectedCount mục',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    PriceFormatter.formatVnd(totalAmount),
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFB7185),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Mua hàng',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F8),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              LucideIcons.shopping_cart,
              size: 38,
              color: Color(0xFFFB7185),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Giỏ hàng đang trống',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hãy thêm sản phẩm hoặc dịch vụ spa để bắt đầu thanh toán.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
