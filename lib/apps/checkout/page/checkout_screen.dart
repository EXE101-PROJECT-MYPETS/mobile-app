import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:petpee_mobile/apps/cart/model/cart_item_model.dart';
import 'package:petpee_mobile/apps/checkout/api/order_service.dart';
import 'package:petpee_mobile/apps/checkout/api/shipping_service.dart';
import 'package:petpee_mobile/apps/checkout/model/address_model.dart';
import 'package:petpee_mobile/apps/checkout/model/ghtk_fee_model.dart';
import 'package:petpee_mobile/apps/checkout/model/order_request_model.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/common/store/app_state.dart';

import 'address_selection_screen.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final Map<String, String> _shopNotes = {};
  final ShippingService _shippingService = ShippingService();
  final OrderService _orderService = OrderService();

  double? _shippingFee;       // null = chưa tải xong
  bool _isLoadingFee = false;
  String? _shippingFeeError;
  int _feeRequestId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final appState = context.read<AppState>();

      // 1. Tải địa chỉ
      await appState.loadCurrentUserAddresses(authProvider.token);

      // 2. Sau khi có địa chỉ, gọi ngay API tính phí ship
      if (mounted) {
        final defaultAddress = appState.defaultAddress;
        if (defaultAddress != null) {
          await _fetchShippingFee(appState, defaultAddress);
        }
      }
    });
  }

  Future<void> _fetchShippingFee(AppState appState, AddressModel address) async {
    final requestId = ++_feeRequestId;

    setState(() {
      _isLoadingFee = true;
      _shippingFeeError = null;
    });

    try {
      final feeResponse = await _shippingService.getShippingFee(
        GhtkFeeRequest(
          userAddressId: int.tryParse(address.id) ?? 0,
          weight: 1000, // TODO: Cần lấy cân nặng thật của sản phẩm
          value: appState.cartTotalPrice.toInt(),
          transport: 'road',
        ),
      );
      if (mounted) {
        setState(() {
          if (requestId != _feeRequestId) return;
          _shippingFee = feeResponse.fee.toDouble();
          _shippingFeeError = null;
          _isLoadingFee = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (requestId != _feeRequestId) return;
          _shippingFee = null;
          _shippingFeeError = 'Lỗi tính phí';
          _isLoadingFee = false;
        });
      }
    }
  }

  String _buildOrderNote() {
    final notes = _shopNotes.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .map((entry) => '${entry.key}: ${entry.value.trim()}')
        .toList();
    return notes.join(' | ');
  }

  Future<void> _onPlaceOrderPressed(AppState state, AuthProvider authProvider) async {
    final user = authProvider.currentUser;
    final address = state.defaultAddress;
    final selectedItems = state.cartItems.where((item) => item.isSelected).toList();

    if (user == null || authProvider.token == null || authProvider.token!.isEmpty) {
      _showMessage('Bạn cần đăng nhập để đặt hàng.');
      return;
    }
    if (address == null) {
      _showMessage('Vui lòng chọn địa chỉ giao hàng.');
      return;
    }
    if (selectedItems.isEmpty) {
      _showMessage('Chưa có sản phẩm nào được chọn.');
      return;
    }

    // Hiển thị loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              const SizedBox(width: 20),
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              const Text('Đang xử lý...'),
            ],
          ),
        );
      },
    );

    final request = CreateOrderRequest(
      userId: user.id,
      userAddressId: int.tryParse(address.id) ?? 0,
      shippingFee: (_shippingFee ?? 0).round(),
      discountAmount: 0,
      note: _buildOrderNote().isEmpty ? 'Thanh toán khi nhận hàng' : _buildOrderNote(),
      items: selectedItems.map((item) {
        return OrderItemRequest(
          productId: int.tryParse(item.product.id) ?? 0,
          qty: item.quantity,
          unitPrice: item.priceAsDouble.round(),
        );
      }).toList(),
    );

    if (request.userAddressId <= 0 || request.items.any((item) => item.productId <= 0)) {
      if (mounted) Navigator.pop(context);
      _showMessage('Dữ liệu đơn hàng chưa hợp lệ để gửi lên hệ thống.');
      return;
    }

    try {
      await _orderService.createOrder(request);
      if (!mounted) return;
      Navigator.pop(context); // Đóng loading dialog
      
      // Deselect tất cả sản phẩm
      for (var item in state.cartItems) {
        item.isSelected = false;
      }
      
      // Navigate tới màn hình thành công
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OrderSuccessScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Đóng loading dialog
        _showMessage('Đặt hàng thất bại: ${e.toString()}');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final authProvider = context.watch<AuthProvider>();
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
    final shippingFee = _shippingFee ?? 0.0;
    final totalPayment = totalMerchandise + shippingFee;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thanh toán',
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
                      margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                               color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                             child: const Icon(LucideIcons.mapPin, color: Color(0xFF111827)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAddressContent(state, address),
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
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                 const Icon(LucideIcons.store, size: 18, color: Color(0xFF111827)),
                                const SizedBox(width: 8),
                                Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          ...items.map((item) => _buildProductItem(item)),
                          
                          // Shop options
                          GestureDetector(
                            onTap: () => _showNoteSheet(shopName),
                            child: _buildOptionRow(
                              'Lời nhắn cho Shop',
                              _shopNotes[shopName]?.isNotEmpty == true
                                  ? _shopNotes[shopName]!
                                  : 'Để lại lời nhắn',
                              hasArrow: true,
                              subtitleColor: _shopNotes[shopName]?.isNotEmpty == true
                                  ? const Color(0xFF111827)
                                  : Colors.grey,
                            ),
                          ),
                          const Divider(height: 1),
                          _buildShippingRow('Phương thức vận chuyển', 'Giao hàng tiêu chuẩn'),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tổng số tiền (${items.length} sản phẩm)', style: const TextStyle(fontSize: 14)),
                                Text(
                                  currencyFormat.format(shopTotal),
                                   style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Payment Method
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEDD5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(LucideIcons.wallet, color: Color(0xFFEA580C), size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('Thanh toán khi nhận hàng', style: TextStyle(fontWeight: FontWeight.w500)),
                              ),
                              const Spacer(),
                               const Icon(LucideIcons.checkCircle2, color: Color(0xFF111827), size: 18),
                            ],
                          ),
                        ),
                         const SizedBox(height: 4),
                      ],
                    ),
                  ),

                  // Payment Details
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 6, 12, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(14),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // Bottom Bar
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10).copyWith(bottom: MediaQuery.of(context).padding.bottom + 10),
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
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFFEA580C)),
                     ),
                  ],
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed: () {
                    _onPlaceOrderPressed(state, authProvider);
                  },
                  style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFF111827),
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

  Widget _buildAddressContent(AppState state, AddressModel? address) {
    if (state.isLoadingAddresses) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dang tai dia chi giao hang...',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
        ],
      );
    }

    if (state.addressesError != null && state.addresses.isEmpty) {
      return Text(
        'Khong tai duoc dia chi. Vui long thu lai.',
        style: TextStyle(color: Colors.red.shade400, fontSize: 13),
      );
    }

    if (address == null) {
      return const Text(
        'Ban chua co dia chi giao hang',
        style: TextStyle(color: Colors.red, fontSize: 13),
      );
    }

    return Column(
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
    );
  }

  Widget _buildProductItem(CartItemModel item) {
    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
             width: 84,
             height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
               color: const Color(0xFFF3F4F6),
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
                   style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.product.price,
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFEA580C)),
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

  Widget _buildOptionRow(
    String title,
    String subtitle, {
    bool hasArrow = false,
    IconData? icon,
    Color subtitleColor = Colors.grey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, color: const Color(0xFF6B7280), size: 20), const SizedBox(width: 8)],
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: subtitleColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasArrow) ...[
            const SizedBox(width: 4),
            const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 16),
          ],
        ],
      ),
    );
  }

  void _showNoteSheet(String shopName) {
    final controller = TextEditingController(text: _shopNotes[shopName] ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                  child: Row(
                    children: [
                      Text(
                        'Lời nhắn cho Shop',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Text field
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    maxLines: 1,
                    maxLength: 150,
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF111827)),
                    decoration: InputDecoration(
                      hintText: 'Để lại lời nhắn',
                      hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF9CA3AF)),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF111827), width: 1.5),
                      ),
                      counterStyle: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
                // Confirm button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _shopNotes[shopName] = controller.text.trim();
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF111827),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        'Xác nhận',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShippingRow(String title, String method) {
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(method, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    if (_isLoadingFee)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF111827)),
                      )
                    else if (_shippingFeeError != null)
                      Text(_shippingFeeError!, style: const TextStyle(fontSize: 13, color: Colors.red))
                    else if (_shippingFee != null)
                      Text(
                        currencyFormat.format(_shippingFee),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.truck, size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      _isLoadingFee ? 'Đang tính toán...' : 'Nhận hàng sau 2-5 ngày',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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

