import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:petpee_mobile/common/store/app_state.dart';
import 'package:petpee_mobile/apps/cart/model/cart_item_model.dart';
import 'address_selection_screen.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selectedItems = state.cartItems.where((i) => i.isSelected).toList();
    final address = state.defaultAddress;

    // Group by shop
    final Map<String, List<CartItemModel>> groupedCart = {};
    for (var item in selectedItems) {
      if (!groupedCart.containsKey(item.shopName)) {
        groupedCart[item.shopName] = [];
      }
      groupedCart[item.shopName]!.add(item);
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final totalMerchandise = state.cartTotalPrice;
    const shippingFee = 22200.0;
    const shippingDiscount = -22200.0;
    final totalPayment = totalMerchandise + shippingFee + shippingDiscount;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light grey background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFB7185), // Pink theme to match PetPee Cart
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thanh toán',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Address Section
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddressSelectionScreen()),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.mapPin, color: Color(0xFFFB7185)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: address == null
                                ? const Text("Vui lòng chọn địa chỉ giao hàng", style: TextStyle(color: Colors.red))
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${address.name} - ${address.phone}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        address.location,
                                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                                      ),
                                      Text(
                                        address.region,
                                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                    ],
                                  ),
                          ),
                          const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ),

                  // Shops
                  ...groupedCart.entries.map((entry) {
                    final shopName = entry.key;
                    final items = entry.value;
                    double shopTotal = items.fold(0, (sum, i) => sum + (i.priceAsDouble * i.quantity));

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.store, size: 18, color: Color(0xFFFB7185)),
                                const SizedBox(width: 8),
                                Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ...items.map((item) => _buildProductItem(item)),
                          
                          // Shop options
                          _buildOptionRow('Voucher của Shop', 'Chọn hoặc nhập mã', hasArrow: true),
                          const Divider(height: 1),
                          _buildOptionRow('Lời nhắn cho Shop', 'Để lại lời nhắn', hasArrow: true),
                          const Divider(height: 1),
                          _buildShippingRow('Phương thức vận chuyển', 'Giao hàng tiêu chuẩn', 'Nhận từ 22 Th04 - 23 Th04', shippingFee),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tổng số tiền (${items.length} sản phẩm)', style: const TextStyle(fontSize: 14)),
                                Text(
                                  currencyFormat.format(shopTotal),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFB7185)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // PetPee Voucher
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _buildOptionRow('PetPee Voucher', 'Chọn Giảm giá', hasArrow: true, icon: LucideIcons.ticket),
                  ),

                  // PetPee Coins
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(LucideIcons.coins, color: Colors.amber, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text('Dùng 400 Xu', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        Switch(value: false, onChanged: (v) {}, activeColor: const Color(0xFFFB7185)),
                      ],
                    ),
                  ),

                  // Payment Method
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOptionRow('Phương thức thanh toán', 'Xem tất cả', hasArrow: true),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(LucideIcons.creditCard, color: Color(0xFF0284C7), size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Text('Chuyển khoản / Thẻ', style: TextStyle(fontWeight: FontWeight.w500)),
                              const Spacer(),
                              const Icon(LucideIcons.checkCircle2, color: Color(0xFFFB7185), size: 18),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  // Payment Details
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.receipt, size: 18, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Chi tiết thanh toán', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ]
                        ),
                        const SizedBox(height: 16),
                        _buildPaymentDetailRow('Tổng tiền hàng', currencyFormat.format(totalMerchandise)),
                        _buildPaymentDetailRow('Tổng tiền phí vận chuyển', currencyFormat.format(shippingFee)),
                        _buildPaymentDetailRow('Giảm giá phí vận chuyển', currencyFormat.format(shippingDiscount), color: const Color(0xFFFB7185)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Tổng thanh toán', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      currencyFormat.format(totalPayment),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFFB7185)),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed: () {
                    // Xử lý tạo đơn hàng
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB7185),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Đặt hàng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductItem(CartItemModel item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade100,
              image: DecorationImage(image: NetworkImage(item.product.image), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.product.price,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE04F43)),
                    ),
                    Text('x${item.quantity}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(String title, String subtitle, {bool hasArrow = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, color: const Color(0xFFFB7185), size: 20), const SizedBox(width: 8)],
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          if (hasArrow) ...[
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildShippingRow(String title, String method, String time, double fee) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Text('Xem tất cả', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F1), // Light pink tint
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFD1D6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(method, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(currencyFormat.format(fee), style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(LucideIcons.truck, color: Color(0xFFFB7185), size: 14),
                    const SizedBox(width: 6),
                    Text(time, style: const TextStyle(color: Color(0xFFFB7185), fontSize: 12)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPaymentDetailRow(String title, String value, {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
