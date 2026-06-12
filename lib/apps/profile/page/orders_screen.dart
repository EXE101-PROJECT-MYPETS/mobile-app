import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pawly_mobile/apps/checkout/api/order_service.dart';
import 'package:pawly_mobile/common/auth/store/auth_provider.dart';
import 'package:pawly_mobile/common/config/api_config.dart';
import 'package:pawly_mobile/common/toast/app_toast.dart';
import 'package:pawly_mobile/apps/profile/page/order_detail_screen.dart';
import 'package:pawly_mobile/features/chat/providers/chat_provider.dart';
import 'package:pawly_mobile/features/chat/screens/chat_detail_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8,
      initialIndex: initialTabIndex.clamp(0, 7),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Quay lại',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFFFB7185),
              size: 16,
            ),
          ),
          title: Text(
            'Đơn mua',
            style: GoogleFonts.inter(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFFE91E63),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFFE91E63),
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
            tabs: [
              Tab(text: 'Tất cả'),
              Tab(text: 'Chờ xác nhận'),
              Tab(text: 'Đã xác nhận'),
              Tab(text: 'Chờ lấy hàng'),
              Tab(text: 'Chờ giao hàng'),
              Tab(text: 'Đang giao'),
              Tab(text: 'Đã hoàn thành'),
              Tab(text: 'Đã hủy'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OrdersList(status: null),
            _OrdersList(status: 'PENDING'),
            _OrdersList(status: 'CONFIRMED'),
            _OrdersList(status: 'PACKING'),
            _OrdersList(status: 'WAITING_GHTK_PICKUP'),
            _OrdersList(status: 'SHIPPING'),
            _OrdersList(status: 'COMPLETED'),
            _OrdersList(status: 'CANCELLED'),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatefulWidget {
  final String? status;
  const _OrdersList({this.status});

  @override
  State<_OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<_OrdersList> {
  final OrderService _orderService = OrderService();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _orders = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int? _cursor;
  Timer? _refreshTimer;
  String? _error;
  final Set<String> _expandedOrderIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);

    // Auto refresh every 10 seconds to keep data fresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _silentlyRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token;
      final response = await _orderService.getCustomerOrders(
        status: widget.status,
        token: token,
      );

      setState(() {
        _orders = response['content'] ?? [];
        _cursor = response['nextCursor'];
        _hasMore = response['hasNext'] ?? false;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải đơn hàng. Vui lòng thử lại.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final token = context.read<AuthProvider>().token;
      final response = await _orderService.getCustomerOrders(
        status: widget.status,
        cursor: _cursor,
        token: token,
      );

      setState(() {
        _orders.addAll(response['content'] ?? []);
        _cursor = response['nextCursor'];
        _hasMore = response['hasNext'] ?? false;
      });
    } catch (e) {
      // Ignore errors on pagination
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _silentlyRefresh() async {
    try {
      if (!mounted) return;
      final token = context.read<AuthProvider>().token;
      if (token == null) return;

      final response = await _orderService.getCustomerOrders(
        status: widget.status,
        token: token,
      );

      if (mounted) {
        // Compare first items to see if we should update
        final newOrders = response['content'] ?? [];
        if (newOrders.isNotEmpty) {
          // If the list changed or is empty, just replace it (only for the first page)
          // To prevent jumping, we only replace if we are near the top, or we can just replace
          if (_scrollController.hasClients &&
              _scrollController.position.pixels < 100) {
            setState(() {
              _orders = newOrders;
              _cursor = response['nextCursor'];
              _hasMore = response['hasNext'] ?? false;
            });
          }
        }
      }
    } catch (e) {
      // silently ignore
    }
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'PACKING':
        return 'Chờ lấy hàng';
      case 'WAITING_GHTK_PICKUP':
        return 'Chờ giao hàng';
      case 'SHIPPING':
        return 'Đang giao';
      case 'COMPLETED':
        return 'Đã hoàn thành';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status ?? 'Không xác định';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
      case 'PACKING':
      case 'WAITING_GHTK_PICKUP':
        return Colors.blue;
      case 'SHIPPING':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _getOrderItems(dynamic rawItems) {
    if (rawItems is! List) return const [];
    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
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

  int _getTotalQuantity(List<Map<String, dynamic>> items) {
    final total = items.fold<int>(
      0,
      (sum, item) => sum + (_asInt(item['qty']) ?? 0),
    );
    return total > 0 ? total : items.length;
  }

  String _orderExpansionKey(Map<String, dynamic> order) {
    return _asString(order['id'], _asString(order['orderCode']));
  }

  void _toggleExpandedOrder(Map<String, dynamic> order) {
    final key = _orderExpansionKey(order);
    if (key.isEmpty) return;

    setState(() {
      if (_expandedOrderIds.contains(key)) {
        _expandedOrderIds.remove(key);
      } else {
        _expandedOrderIds.add(key);
      }
    });
  }

  String _resolveImageUrl(Map<String, dynamic> item) {
    return ApiConfig.formatImageUrl(_asString(item['productImageUrl']));
  }

  int? _resolveShopId(Map<String, dynamic> order) {
    final orderShopId = _asInt(order['shopId']);
    if (orderShopId != null && orderShopId > 0) return orderShopId;

    final items = _getOrderItems(order['items']);
    for (final item in items) {
      final itemShopId = _asInt(item['shopId']);
      if (itemShopId != null && itemShopId > 0) return itemShopId;
    }

    return null;
  }

  Future<void> _openChatForOrder(Map<String, dynamic> order) async {
    final shopId = _resolveShopId(order);
    if (shopId == null) {
      showAppToast(
        context,
        message: 'Không xác định được shop để mở chat',
        type: AppToastType.error,
      );
      return;
    }

    final shopName = _asString(order['shopName'], 'Cửa hàng');
    final chatProvider = context.read<ChatProvider>();

    try {
      final conversation = await chatProvider.openConversationForShop(
        shopId.toString(),
      );
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            conversationId: conversation.id,
            shopId: conversation.shopId,
            shopName: shopName,
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

<<<<<<< feature/notifications-update
  String _getProductsNames(List<dynamic>? items) {
    if (items == null || items.isEmpty) return 'Không có sản phẩm';
    final names = items
        .map((i) => i['productName']?.toString() ?? 'Sản phẩm')
        .toList();
    if (names.length == 1) return names.first;
    return '${names.first} và ${names.length - 1} sản phẩm khác';
=======
  void _openOrderDetail(Map<String, dynamic> order) {
    final orderId = _asInt(order['id']);
    if (orderId == null) {
      showAppToast(
        context,
        message: 'Không xác định được đơn hàng',
        type: AppToastType.error,
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(orderId: orderId),
      ),
    );
  }

  Widget _buildOrderCard(
    Map<String, dynamic> order,
    NumberFormat currencyFormat,
  ) {
    final statusString = order['status'] as String?;
    final statusLabel = _formatStatus(statusString);
    final statusColor = _getStatusColor(statusString);
    final items = _getOrderItems(order['items']);
    final totalQuantity = _getTotalQuantity(items);
    final expansionKey = _orderExpansionKey(order);
    final isExpanded = _expandedOrderIds.contains(expansionKey);
    final visibleItems = isExpanded ? items : items.take(1).toList();
    final hasHiddenItems = items.length > 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openOrderDetail(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Icon(
                      Icons.store,
                      size: 13,
                      color: Color(0xFFFB7185),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _asString(order['shopName'], 'Cửa hàng'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF111827),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                'Mã đơn: ${order['orderCode'] ?? order['id']}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Text(
                  'Không có sản phẩm',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              )
            else
              ...visibleItems.map(
                (item) => _OrderItemRow(
                  item: item,
                  imageUrl: _resolveImageUrl(item),
                  currencyFormat: currencyFormat,
                  asString: _asString,
                  asInt: _asInt,
                  asNum: _asNum,
                ),
              ),
            if (hasHiddenItems)
              Center(
                child: TextButton.icon(
                  onPressed: () => _toggleExpandedOrder(order),
                  iconAlignment: IconAlignment.end,
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                  ),
                  label: Text(isExpanded ? 'Thu gọn' : 'Xem thêm'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    textStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            const Divider(height: 16, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          'Tổng số tiền ($totalQuantity sản phẩm):',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF111827),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        currencyFormat.format(_asNum(order['totalAmount'])),
                        style: GoogleFonts.inter(
                          color: const Color(0xFFE53935),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => _openChatForOrder(order),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF111827),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Liên hệ Shop'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
>>>>>>> main
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFB7185)),
      );
    }

    if (_error != null && _orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadInitialData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có đơn hàng nào',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: const Color(0xFFFB7185),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: _orders.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFB7185)),
              ),
            );
          }

          final rawOrder = _orders[index];
          if (rawOrder is! Map) return const SizedBox.shrink();
          return _buildOrderCard(
            Map<String, dynamic>.from(rawOrder),
            currencyFormat,
          );
        },
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.item,
    required this.imageUrl,
    required this.currencyFormat,
    required this.asString,
    required this.asInt,
    required this.asNum,
  });

  final Map<String, dynamic> item;
  final String imageUrl;
  final NumberFormat currencyFormat;
  final String Function(dynamic value, [String fallback]) asString;
  final int? Function(dynamic value) asInt;
  final num Function(dynamic value) asNum;

  String _formatItemDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final qty = asInt(item['qty']) ?? 1;
    final unitPrice = asNum(item['unitPrice']);
    final amount = asNum(item['amount']);
    final createdAtText = _formatItemDate(item['createdAt']);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              width: 72,
              height: 72,
              child: imageUrl.isEmpty
                  ? const _OrderItemImagePlaceholder()
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _OrderItemImagePlaceholder(),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        asString(item['productName'], 'Sản phẩm'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF111827),
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'x$qty',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: unitPrice > 0
                          ? Text(
                              currencyFormat.format(unitPrice),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Text(
                      currencyFormat.format(amount > 0 ? amount : unitPrice),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF111827),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (createdAtText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ngày tạo: $createdAtText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemImagePlaceholder extends StatelessWidget {
  const _OrderItemImagePlaceholder();

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
