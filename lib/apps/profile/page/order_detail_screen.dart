import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:petpee_mobile/apps/checkout/api/order_service.dart';
import 'package:petpee_mobile/apps/product/page/product_detail_screen.dart';
import 'package:petpee_mobile/apps/shop/page/shop_detail_screen.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/common/config/api_config.dart';
import 'package:petpee_mobile/common/toast/app_toast.dart';
import 'package:petpee_mobile/features/chat/providers/chat_provider.dart';
import 'package:petpee_mobile/features/chat/screens/chat_detail_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  late Future<Map<String, dynamic>> _orderFuture;
  bool _isCancelling = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
  );

  @override
  void initState() {
    super.initState();
    _orderFuture = _loadOrder();
  }

  Future<Map<String, dynamic>> _loadOrder() {
    final token = context.read<AuthProvider>().token;
    return _orderService.getCustomerOrderDetail(
      id: widget.orderId,
      token: token,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _orderFuture = _loadOrder();
    });
    await _orderFuture;
  }

  String _asString(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  num _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
  }

  List<Map<String, dynamic>> _itemsOf(Map<String, dynamic> order) {
    final rawItems = order['items'];
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Map<String, dynamic> _shippingOf(Map<String, dynamic> order) {
    final raw = order['shippingSnapshot'];
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  int _totalQuantity(List<Map<String, dynamic>> items) {
    final total = items.fold<int>(
      0,
      (sum, item) => sum + (_asInt(item['qty']) ?? 0),
    );
    return total > 0 ? total : items.length;
  }

  String _formatAddress(Map<String, dynamic> shipping) {
    final parts = [
      _asString(shipping['address']),
      _asString(shipping['street']),
      _asString(shipping['hamlet']),
      _asString(shipping['ward']),
      _asString(shipping['district']),
      _asString(shipping['province']),
    ].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? 'Chưa có địa chỉ nhận hàng' : parts.join(', ');
  }

  String _imageUrl(Map<String, dynamic> item) {
    return ApiConfig.formatImageUrl(_asString(item['productImageUrl']));
  }

  Future<void> _openChat(Map<String, dynamic> order) async {
    final shopId = _asInt(order['shopId']);
    if (shopId == null || shopId <= 0) {
      showAppToast(
        context,
        message: 'Không xác định được shop để mở chat',
        type: AppToastType.error,
      );
      return;
    }

    try {
      final conversation = await context
          .read<ChatProvider>()
          .openConversationForShop(shopId.toString());
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            conversationId: conversation.id,
            shopId: conversation.shopId,
            shopName: _asString(order['shopName'], 'Cửa hàng'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: 'Không thể mở chat với shop',
        type: AppToastType.error,
      );
    }
  }

  void _openShop(Map<String, dynamic> order) {
    final shopId = _asInt(order['shopId']);
    if (shopId == null || shopId <= 0) {
      showAppToast(
        context,
        message: 'Không xác định được shop',
        type: AppToastType.error,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopDetailScreen(
          shopId: shopId,
          shopName: _asString(order['shopName'], 'Cửa hàng'),
        ),
      ),
    );
  }

  void _openProduct(Map<String, dynamic> item) {
    final productId = _asInt(item['productId']);
    if (productId == null || productId <= 0) {
      showAppToast(
        context,
        message: 'Không xác định được sản phẩm',
        type: AppToastType.error,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ProductDetailScreen(productId: productId.toString()),
      ),
    );
  }

  void _copyOrderCode(Map<String, dynamic> order) {
    final code = _asString(order['orderCode'], _asString(order['id']));
    Clipboard.setData(ClipboardData(text: code));
    showAppToast(
      context,
      message: 'Đã sao chép mã đơn hàng',
      type: AppToastType.success,
    );
  }

  Future<void> _showCancelDialog(Map<String, dynamic> order) async {
    final orderId = _asInt(order['id']);
    if (orderId == null || orderId <= 0) {
      showAppToast(
        context,
        message: 'Không xác định được đơn hàng',
        type: AppToastType.error,
      );
      return;
    }

    const reasons = [
      'Tôi muốn đổi địa chỉ nhận hàng',
      'Tôi muốn thay đổi sản phẩm trong đơn',
      'Không còn nhu cầu mua nữa',
      'Thời gian giao hàng không phù hợp',
      'Tôi đặt nhầm đơn hàng',
    ];
    String? selectedReason;

    final reason = await showDialog<String?>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Hủy đơn hàng',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chọn lý do hủy đơn hàng trước khi xác nhận.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF334155),
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...reasons.map(
                    (reason) => CheckboxListTile(
                      value: selectedReason == reason,
                      onChanged: (checked) {
                        setDialogState(() {
                          selectedReason = checked == true ? reason : null;
                        });
                      },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFFFF4D2D),
                      title: Text(
                        reason,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF111827),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Đóng'),
                ),
                FilledButton(
                  onPressed: selectedReason == null
                      ? null
                      : () => Navigator.pop(dialogContext, selectedReason),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D2D),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Xác nhận hủy'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || reason == null) return;

    setState(() => _isCancelling = true);
    try {
      final token = context.read<AuthProvider>().token;
      await _orderService.cancelCustomerOrder(
        id: orderId,
        reason: reason,
        token: token,
      );
      if (!mounted) return;

      showAppToast(
        context,
        message: 'Đã hủy đơn hàng',
        type: AppToastType.success,
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: 'Không thể hủy đơn hàng',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFF4D2D)),
        ),
        titleSpacing: 0,
        title: Text(
          'Thông tin đơn hàng',
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4D2D)),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return _OrderDetailError(onRetry: _refresh);
          }

          return _buildContent(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> order) {
    final items = _itemsOf(order);
    final shipping = _shippingOf(order);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFFFF4D2D),
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              children: [
                _GuaranteeBanner(),
                const SizedBox(height: 8),
                _ShippingStatus(
                  statusLabel: _asString(
                    order['statusLabel'],
                    _asString(order['status'], 'Đang cập nhật'),
                  ),
                  updatedAt: _formatDate(order['updatedAt']),
                ),
                const SizedBox(height: 8),
                _ShippingAddressCard(
                  receiverName: _asString(
                    shipping['receiverName'],
                    _asString(order['userFullName'], 'Người nhận'),
                  ),
                  receiverPhone: _asString(
                    shipping['receiverPhone'],
                    _asString(order['userPhone']),
                  ),
                  address: _formatAddress(shipping),
                ),
                const SizedBox(height: 8),
                _ProductDetailCard(
                  shopName: _asString(order['shopName'], 'Cửa hàng'),
                  items: items,
                  totalQuantity: _totalQuantity(items),
                  totalAmount: _asNum(order['totalAmount']),
                  currencyFormat: _currencyFormat,
                  imageUrl: _imageUrl,
                  asString: _asString,
                  asInt: _asInt,
                  asNum: _asNum,
                  onOpenShop: () => _openShop(order),
                  onOpenProduct: _openProduct,
                ),
                const SizedBox(height: 8),
                _SupportCard(onChat: () => _openChat(order)),
              ],
            ),
          ),
        ),
        _OrderDetailBottomBar(
          orderCode: _asString(order['orderCode'], _asString(order['id'])),
          onCopy: () => _copyOrderCode(order),
          onCancel: () => _showCancelDialog(order),
          onChat: () => _openChat(order),
          isCancelling: _isCancelling,
        ),
      ],
    );
  }
}

class _GuaranteeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF12A594),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'Thời gian đảm bảo nhận hàng: 30 Th05 - 2 Th06\nNgười bán đang chuẩn bị hàng',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 12,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ShippingStatus extends StatelessWidget {
  const _ShippingStatus({required this.statusLabel, required this.updatedAt});

  final String statusLabel;
  final String updatedAt;

  @override
  Widget build(BuildContext context) {
    final suffix = updatedAt.isEmpty ? '' : ' - Cập nhật $updatedAt';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            size: 16,
            color: Color(0xFF12A594),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$statusLabel$suffix',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF475569),
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShippingAddressCard extends StatelessWidget {
  const _ShippingAddressCard({
    required this.receiverName,
    required this.receiverPhone,
    required this.address,
  });

  final String receiverName;
  final String receiverPhone;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Địa chỉ nhận hàng',
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$receiverName${receiverPhone.isEmpty ? '' : ' | $receiverPhone'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF111827),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF475569),
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductDetailCard extends StatelessWidget {
  const _ProductDetailCard({
    required this.shopName,
    required this.items,
    required this.totalQuantity,
    required this.totalAmount,
    required this.currencyFormat,
    required this.imageUrl,
    required this.asString,
    required this.asInt,
    required this.asNum,
    required this.onOpenShop,
    required this.onOpenProduct,
  });

  final String shopName;
  final List<Map<String, dynamic>> items;
  final int totalQuantity;
  final num totalAmount;
  final NumberFormat currencyFormat;
  final String Function(Map<String, dynamic> item) imageUrl;
  final String Function(dynamic value, [String fallback]) asString;
  final int? Function(dynamic value) asInt;
  final num Function(dynamic value) asNum;
  final VoidCallback onOpenShop;
  final void Function(Map<String, dynamic> item) onOpenProduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4D2D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'Yêu thích',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: onOpenShop,
                    child: Text(
                      shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF111827),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Không có sản phẩm'),
            )
          else
            ...items.map(
              (item) => _DetailProductRow(
                item: item,
                imageUrl: imageUrl(item),
                currencyFormat: currencyFormat,
                asString: asString,
                asInt: asInt,
                asNum: asNum,
                onTap: () => onOpenProduct(item),
              ),
            ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    'Thành tiền ($totalQuantity sản phẩm):',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF111827),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  currencyFormat.format(totalAmount),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF111827),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

class _DetailProductRow extends StatelessWidget {
  const _DetailProductRow({
    required this.item,
    required this.imageUrl,
    required this.currencyFormat,
    required this.asString,
    required this.asInt,
    required this.asNum,
    required this.onTap,
  });

  final Map<String, dynamic> item;
  final String imageUrl;
  final NumberFormat currencyFormat;
  final String Function(dynamic value, [String fallback]) asString;
  final int? Function(dynamic value) asInt;
  final num Function(dynamic value) asNum;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final qty = asInt(item['qty']) ?? 1;
    final amount = asNum(item['amount']);
    final unitPrice = asNum(item['unitPrice']);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 72,
                height: 72,
                child: imageUrl.isEmpty
                    ? const _ProductImagePlaceholder()
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _ProductImagePlaceholder(),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    asString(item['productName'], 'Sản phẩm'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF111827),
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'x$qty',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      currencyFormat.format(amount > 0 ? amount : unitPrice),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF111827),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.onChat});

  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              'Bạn cần hỗ trợ?',
              style: GoogleFonts.inter(
                color: const Color(0xFF111827),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ListTile(
            dense: true,
            minLeadingWidth: 18,
            leading: const Icon(Icons.chat_bubble_outline, size: 17),
            title: const Text('Liên hệ Shop'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: onChat,
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const ListTile(
            dense: true,
            minLeadingWidth: 18,
            leading: Icon(Icons.help_outline, size: 17),
            title: Text('Trung tâm Hỗ trợ'),
            trailing: Icon(Icons.chevron_right, size: 18),
          ),
        ],
      ),
    );
  }
}

class _OrderDetailBottomBar extends StatelessWidget {
  const _OrderDetailBottomBar({
    required this.orderCode,
    required this.onCopy,
    required this.onCancel,
    required this.onChat,
    required this.isCancelling,
  });

  final String orderCode;
  final VoidCallback onCopy;
  final VoidCallback onCancel;
  final VoidCallback onChat;
  final bool isCancelling;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Mã đơn hàng',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF111827),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    orderCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF475569),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(onPressed: onCopy, child: const Text('SAO CHÉP')),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isCancelling ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF111827),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Text(isCancelling ? 'Đang hủy...' : 'Hủy đơn hàng'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onChat,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF111827),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text('Liên hệ Shop'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImagePlaceholder extends StatelessWidget {
  const _ProductImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFF94A3B8),
        size: 24,
      ),
    );
  }
}

class _OrderDetailError extends StatelessWidget {
  const _OrderDetailError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Không thể tải thông tin đơn hàng',
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
