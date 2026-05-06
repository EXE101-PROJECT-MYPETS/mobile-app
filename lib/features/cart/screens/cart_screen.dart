import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../models/cart_item_model.dart';
import 'package:intl/intl.dart';
import '../../checkout/screens/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cartItems = state.cartItems;

    // Group by shop
    final Map<String, List<CartItemModel>> groupedCart = {};
    for (var item in cartItems) {
      if (!groupedCart.containsKey(item.shopName)) {
        groupedCart[item.shopName] = [];
      }
      groupedCart[item.shopName]!.add(item);
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFB7185), // Pink
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Giỏ hàng của bạn',
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
            child: groupedCart.isEmpty
                ? const Center(child: Text("Giỏ hàng trống", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: groupedCart.keys.length,
                    itemBuilder: (context, index) {
                      final shopName = groupedCart.keys.elementAt(index);
                      final itemsInShop = groupedCart[shopName]!;
                      
                      // Check if all items in this shop are selected
                      bool allShopItemsSelected = itemsInShop.every((i) => i.isSelected);

                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            // Shop Header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: allShopItemsSelected,
                                    activeColor: const Color(0xFFFB7185),
                                    shape: const CircleBorder(),
                                    onChanged: (val) {
                                      for (var item in itemsInShop) {
                                        context.read<AppState>().toggleCartSelection(item.id, val);
                                      }
                                    },
                                  ),
                                  Text(
                                    'Shop: $shopName',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            // Shop Items
                            ...itemsInShop.map((item) => _buildCartItemCard(context, item)),
                            const SizedBox(height: 8),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          // Bottom Bar
          if (cartItems.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Voucher Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.ticket, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        const Text('Voucher', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Nhập mã PetPees',
                                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    height: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFB7185),
                                      borderRadius: BorderRadius.horizontal(right: Radius.circular(3)),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text('Áp dụng', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Total Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      children: [
                        Checkbox(
                          value: state.isAllCartSelected,
                          activeColor: const Color(0xFFFB7185),
                          shape: const CircleBorder(),
                          onChanged: (val) {
                            context.read<AppState>().toggleAllCartSelection(val);
                          },
                        ),
                        const Text('Chọn tất cả', style: TextStyle(fontSize: 14)),
                        const Spacer(),
                        const Text('Tổng thanh toán: ', style: TextStyle(fontSize: 13)),
                        Text(
                          currencyFormat.format(state.cartTotalPrice),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFE04F43)),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  
                  // Checkout Button
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: MediaQuery.of(context).padding.bottom + 8),
                    child: ElevatedButton(
                      onPressed: () {
                        final selectedItems = cartItems.where((i) => i.isSelected).toList();
                        if (selectedItems.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CheckoutScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng chọn sản phẩm để thanh toán')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF95B30), // Vibe shopee / orange
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Mua hàng (${cartItems.where((i) => i.isSelected).length})',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _buildCartItemCard(BuildContext context, CartItemModel item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: item.isSelected,
            activeColor: const Color(0xFFFB7185),
            shape: const CircleBorder(),
            onChanged: (val) {
              context.read<AppState>().toggleCartSelection(item.id, val);
            },
          ),
          // Product Image
          Container(
            width: 70,
            height: 70,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(image: NetworkImage(item.product.image), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          // Product Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12, right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.product.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.product.price,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFE04F43)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Subtitle / Variant dummy
                      const Expanded(
                        child: Text(
                          'Phân loại: Mặc định',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      
                      // Quantity controls
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => context.read<AppState>().updateCartQuantity(item.id, -1),
                              child: Container(
                                width: 28,
                                alignment: Alignment.center,
                                child: const Icon(LucideIcons.minus, size: 14, color: Colors.grey),
                              ),
                            ),
                            Container(
                              width: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(border: Border.symmetric(vertical: BorderSide(color: Colors.grey.shade300))),
                              child: Text('${item.quantity}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            ),
                            InkWell(
                              onTap: () => context.read<AppState>().updateCartQuantity(item.id, 1),
                              child: Container(
                                width: 28,
                                alignment: Alignment.center,
                                child: const Icon(LucideIcons.plus, size: 14, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Delete icon
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.grey),
                        onPressed: () => context.read<AppState>().removeFromCart(item.id),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
