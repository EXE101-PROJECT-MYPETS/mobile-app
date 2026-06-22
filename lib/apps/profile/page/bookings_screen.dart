import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pawly_mobile/apps/service/api/service_service.dart';
import 'package:pawly_mobile/apps/service/model/booking_list_item_dto.dart';
import 'package:pawly_mobile/common/auth/store/auth_provider.dart';
import 'package:pawly_mobile/common/toast/app_toast.dart';
import 'package:pawly_mobile/common/component/write_review_sheet.dart';
import 'package:pawly_mobile/features/chat/providers/chat_provider.dart';
import 'package:pawly_mobile/features/chat/screens/chat_detail_screen.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      initialIndex: initialTabIndex.clamp(0, 4),
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
            'Lịch hẹn dịch vụ',
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
              Tab(text: 'Đã xác nhận'),
              Tab(text: 'Đang thực hiện'),
              Tab(text: 'Hoàn thành'),
              Tab(text: 'Đã hủy / Từ chối'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BookingsList(status: null),
            _BookingsList(status: 'CONFIRMED'),
            _BookingsList(status: 'IN_PROGRESS'),
            _BookingsList(status: 'COMPLETED'),
            _BookingsList(status: 'CANCELLED'),
          ],
        ),
      ),
    );
  }
}

class _BookingsList extends StatefulWidget {
  final String? status;
  const _BookingsList({this.status});

  @override
  State<_BookingsList> createState() => _BookingsListState();
}

class _BookingsListState extends State<_BookingsList> {
  final ServiceBookingService _bookingService = ServiceBookingService();
  final ScrollController _scrollController = ScrollController();

  List<BookingListItemDTO> _bookings = [];
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
      final response = await _bookingService.getCustomerBookings(
        status: widget.status,
        token: token,
      );

      setState(() {
        _bookings = response.content;
        _cursor = response.nextCursor != null
            ? int.tryParse(response.nextCursor.toString())
            : null;
        _hasMore = response.hasNext;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể tải lịch hẹn. Vui lòng thử lại.';
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
      final response = await _bookingService.getCustomerBookings(
        status: widget.status,
        cursor: _cursor,
        token: token,
      );

      setState(() {
        _bookings.addAll(response.content);
        _cursor = response.nextCursor != null
            ? int.tryParse(response.nextCursor.toString())
            : null;
        _hasMore = response.hasNext;
      });
    } catch (e) {
      // Ignore pagination errors
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

      final response = await _bookingService.getCustomerBookings(
        status: widget.status,
        token: token,
      );

      if (mounted) {
        if (response.content.isNotEmpty) {
          if (_scrollController.hasClients &&
              _scrollController.position.pixels < 100) {
            setState(() {
              _bookings = response.content;
              _cursor = response.nextCursor != null
                  ? int.tryParse(response.nextCursor.toString())
                  : null;
              _hasMore = response.hasNext;
            });
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'DRAFT':
        return 'Chờ xác nhận';
      case 'CONFIRMED':
        return 'Đã xác nhận';
      case 'IN_PROGRESS':
        return 'Đang thực hiện';
      case 'COMPLETED':
        return 'Đã hoàn thành';
      case 'REJECTED':
        return 'Bị từ chối';
      case 'CANCELLED':
        return 'Đã hủy';
      default:
        return status ?? 'Chờ xác nhận';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'DRAFT':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'IN_PROGRESS':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.green;
      case 'REJECTED':
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openChatForBooking(BookingListItemDTO booking) async {
    final shopId = booking.shopId;
    if (shopId == null) {
      showAppToast(
        context,
        message: 'Không xác định được shop để mở chat',
        type: AppToastType.error,
      );
      return;
    }

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
            shopName: 'Cửa hàng',
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

  void _onReviewTap(BookingListItemDTO booking) {
    if (booking.items.isEmpty) {
      showAppToast(
        context,
        message: 'Không tìm thấy thông tin dịch vụ để đánh giá',
        type: AppToastType.error,
      );
      return;
    }

    if (booking.items.length == 1) {
      final item = booking.items.first;
      if (item.serviceId == null) {
        showAppToast(
          context,
          message: 'Lịch hẹn này không phải là dịch vụ chăm sóc',
          type: AppToastType.error,
        );
        return;
      }
      showWriteReviewSheet(
        context: context,
        serviceId: item.serviceId,
        name: item.name ?? 'Dịch vụ',
        onReviewSubmitted: _loadInitialData,
      );
    } else {
      // Multiple items, show service chooser
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Chọn dịch vụ đánh giá',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: booking.items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = booking.items[index];
                return ListTile(
                  title: Text(
                    item.name ?? 'Dịch vụ',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Color(0xFFFB7185)),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (item.serviceId == null) {
                      showAppToast(
                        context,
                        message: 'Sản phẩm này không hỗ trợ đánh giá dịch vụ',
                        type: AppToastType.error,
                      );
                      return;
                    }
                    showWriteReviewSheet(
                      context: context,
                      serviceId: item.serviceId,
                      name: item.name ?? 'Dịch vụ',
                      onReviewSubmitted: _loadInitialData,
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Đóng',
                style: GoogleFonts.inter(
                    color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBookingCard(
      BookingListItemDTO booking, NumberFormat currencyFormat) {
    final statusColor = _getStatusColor(booking.status);
    final statusLabel = _formatStatus(booking.status);

    String formattedDate = '';
    if (booking.startAt != null) {
      try {
        final parsed = DateTime.parse(booking.startAt!);
        formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(parsed.toLocal());
      } catch (_) {
        formattedDate = booking.startAt!;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mã lịch hẹn: ${booking.bookingCode ?? booking.id}',
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                'Thời gian: $formattedDate',
                style: GoogleFonts.inter(
                  color: const Color(0xFF334155),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (booking.petName != null && booking.petName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.pets, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  'Thú cưng: ${booking.petName}',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF334155),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Dịch vụ đặt lịch:',
            style: GoogleFonts.inter(
              color: const Color(0xFF475569),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          ...booking.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '• ${item.name ?? 'Dịch vụ'} (x${item.quantity ?? 1})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF1E293B),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      currencyFormat.format(item.amount ?? 0),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF475569),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng tiền thanh toán:',
                style: GoogleFonts.inter(
                  color: const Color(0xFF1E293B),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currencyFormat.format(booking.totalAmount ?? 0),
                style: GoogleFonts.inter(
                  color: const Color(0xFFE53935),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _openChatForBooking(booking),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF111827),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Liên hệ Shop'),
              ),
              if (booking.status == 'COMPLETED') ...[
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _onReviewTap(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFB7185),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Đánh giá dịch vụ'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _bookings.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFB7185)),
      );
    }

    if (_error != null && _bookings.isEmpty) {
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

    if (_bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Chưa có lịch hẹn nào',
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
        itemCount: _bookings.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _bookings.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFB7185)),
              ),
            );
          }

          final booking = _bookings[index];
          return _buildBookingCard(booking, currencyFormat);
        },
      ),
    );
  }
}
