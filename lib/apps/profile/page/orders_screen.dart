import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/apps/checkout/api/order_service.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 80,
          leading: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFFFB7185),
              size: 16,
            ),
            label: const Text(
              'Back',
              style: TextStyle(color: Color(0xFFFB7185), fontSize: 14),
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
              Tab(text: 'Đang giao'),
              Tab(text: 'Đã hoàn thành'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OrdersList(status: null),
            _OrdersList(status: 'PENDING'),
            _OrdersList(status: 'CONFIRMED'),
            _OrdersList(status: 'SHIPPING'),
            _OrdersList(status: 'COMPLETED'),
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
        return 'Đang đóng gói';
      case 'WAITING_GHTK_PICKUP':
        return 'Chờ lấy hàng';
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

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  String _getProductsNames(List<dynamic>? items) {
    if (items == null || items.isEmpty) return 'Không có sản phẩm';
    final names = items
        .map((i) => i['productName']?.toString() ?? 'Sản phẩm')
        .toList();
    if (names.length == 1) return names.first;
    return '${names.first} và ${names.length - 1} sản phẩm khác';
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

          final order = _orders[index];
          final statusString = order['status'] as String?;
          final statusLabel = _formatStatus(statusString);
          final statusColor = _getStatusColor(statusString);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.store,
                            size: 14,
                            color: Color(0xFFFB7185),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          order['shopName']?.toString() ?? 'Cửa hàng',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Mã đơn: ${order['orderCode'] ?? order['id']}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sản phẩm: ${_getProductsNames(order['items'])}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ngày tạo: ${_formatDate(order['createdAt'])}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    currencyFormat.format(order['totalAmount'] ?? 0),
                    style: const TextStyle(
                      color: Color(0xFFC62828), // Đỏ đậm
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
