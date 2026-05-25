import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/apps/cart/model/cart_item_model.dart';
import 'package:petpee_mobile/apps/checkout/api/checkout_service.dart';
import 'package:petpee_mobile/apps/checkout/api/shipping_service.dart';
import 'package:petpee_mobile/apps/checkout/model/address_model.dart';
import 'package:petpee_mobile/apps/checkout/model/checkout_request_model.dart';
import 'package:petpee_mobile/apps/checkout/model/ghtk_fee_model.dart';
import 'package:petpee_mobile/apps/checkout/page/address_selection_screen.dart';
import 'package:petpee_mobile/apps/checkout/page/checkout_success_screen.dart';
import 'package:petpee_mobile/apps/profile/page/add_pet_screen.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/common/store/app_state.dart';
import 'package:petpee_mobile/common/toast/app_toast.dart';
import 'package:petpee_mobile/common/user/model/user_model.dart';
import 'package:petpee_mobile/common/utils/price_formatter.dart';
import 'package:provider/provider.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem>? selectedItems;

  const CheckoutScreen({super.key, this.selectedItems});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final ShippingService _shippingService = ShippingService();
  final CheckoutService _checkoutService = CheckoutService();
  final TextEditingController _noteController = TextEditingController();
  static const int _pickupFeeValue = 50000;

  AddressModel? _selectedAddress;
  int? _selectedPetId;
  DateTime? _selectedBookingDate;
  TimeOfDay? _selectedBookingTime;
  int _transportOption = 0;
  double? _shippingFee;
  String? _shippingFeeError;
  bool _isLoadingFee = false;
  bool _isSubmitting = false;
  int _feeRequestId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final authProvider = context.read<AuthProvider>();
      final appState = context.read<AppState>();
      await appState.loadCurrentUserAddresses(authProvider.token);
      if (!mounted) return;
      _syncDefaultAddress(appState.defaultAddress);
      if (_hasServiceItems(appState)) {
        await appState.loadMyPets();
        if (!mounted) return;
        if (appState.myPets.isNotEmpty && _selectedPetId == null) {
          setState(() {
            _selectedPetId = appState.myPets.first.id;
          });
        }
      }
      if (_hasProductItems(appState)) {
        await _refreshShippingFee();
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _syncDefaultAddress(AddressModel? address) {
    if (_selectedAddress == null && address != null) {
      setState(() {
        _selectedAddress = address;
      });
    }
  }

  List<CartItem> _getCheckoutItems(AppState state) {
    final items = widget.selectedItems ?? state.selectedCartItems;
    return items;
  }

  bool _hasProductItems(AppState state) {
    final items = _getCheckoutItems(state);
    return items.any((item) => !item.isService);
  }

  bool _hasServiceItems(AppState state) {
    final items = _getCheckoutItems(state);
    return items.any((item) => item.isService);
  }

  int _productSubtotal(AppState state) {
    return _getCheckoutItems(state)
        .where((item) => !item.isService)
        .fold(0, (sum, item) => sum + item.amount);
  }

  int _serviceSubtotal(AppState state) {
    return _getCheckoutItems(state)
        .where((item) => item.isService)
        .fold(0, (sum, item) => sum + item.amount);
  }

  int _subtotalAmount(AppState state) {
    return _productSubtotal(state) + _serviceSubtotal(state);
  }

  Future<void> _refreshShippingFee() async {
    final appState = context.read<AppState>();
    if (!_hasProductItems(appState)) {
      setState(() {
        _shippingFee = 0;
        _shippingFeeError = null;
      });
      return;
    }

    final address = _selectedAddress ?? appState.defaultAddress;
    if (address == null) {
      setState(() {
        _shippingFee = null;
        _shippingFeeError = null;
      });
      return;
    }

    final requestId = ++_feeRequestId;
    setState(() {
      _isLoadingFee = true;
      _shippingFeeError = null;
    });

    try {
          final int weight = _getCheckoutItems(appState)
          .where((item) => !item.isService)
          .fold<int>(0, (sum, item) => sum + item.quantity * 500)
            .clamp(500, 5000)
            .toInt();

      final feeResponse = await _shippingService.getShippingFee(
        GhtkFeeRequest(
          userAddressId: int.tryParse(address.id) ?? 0,
          weight: weight,
          value: _productSubtotal(appState),
          transport: 'road',
        ),
      );

      if (!mounted || requestId != _feeRequestId) return;
      setState(() {
        _shippingFee = feeResponse.fee.toDouble();
        _shippingFeeError = null;
        _isLoadingFee = false;
      });
    } catch (error) {
      if (!mounted || requestId != _feeRequestId) return;
      setState(() {
        _shippingFee = null;
        _shippingFeeError = 'Không thể tính phí vận chuyển';
        _isLoadingFee = false;
      });
    }
  }

  Future<void> _pickBookingDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBookingDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      helpText: 'Chọn ngày làm spa',
    );

    if (picked == null || !mounted) return;
    setState(() {
      _selectedBookingDate = picked;
    });
  }

  Future<void> _pickBookingTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedBookingTime ?? TimeOfDay.now(),
      helpText: 'Chọn giờ làm spa',
    );

    if (picked == null || !mounted) return;
    setState(() {
      _selectedBookingTime = picked;
    });
  }

  Future<void> _onSelectAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressSelectionScreen(),
      ),
    );

    if (!mounted) return;
    final appState = context.read<AppState>();
    setState(() {
      _selectedAddress = appState.defaultAddress;
      _shippingFee = null;
      _shippingFeeError = null;
    });
    await _refreshShippingFee();
  }

  String _formatBookingSchedule() {
    if (_selectedBookingDate == null || _selectedBookingTime == null) {
      return 'Chưa chọn lịch';
    }
    final dateText = DateFormat('dd/MM/yyyy').format(_selectedBookingDate!);
    final timeText = _selectedBookingTime!.format(context);
    return '$dateText lúc $timeText';
  }

  String _buildShippingAddressText(AddressModel address, UserModel? user) {
    final parts = <String>[
      address.location,
      address.region,
    ].where((item) => item.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  Future<void> _submitCheckout() async {
    final appState = context.read<AppState>();
    final authProvider = context.read<AuthProvider>();
    final items = _getCheckoutItems(appState);
    final user = authProvider.currentUser;

    if (user == null || authProvider.token == null || authProvider.token!.isEmpty) {
      _showMessage('Bạn cần đăng nhập để thực hiện thanh toán.');
      return;
    }

    if (items.isEmpty) {
      _showMessage('Giỏ hàng không có sản phẩm hoặc dịch vụ để thanh toán.');
      return;
    }

    final shopIds = items.map((item) => item.shopId).toSet();
    if (shopIds.length > 1) {
      _showMessage(
        'Giỏ hàng đang có mục từ nhiều shop. Vui lòng chỉ chọn sản phẩm và dịch vụ thuộc cùng một shop để thanh toán.',
      );
      return;
    }

    final hasProducts = items.any((item) => !item.isService);
    final hasServices = items.any((item) => item.isService);

    if (hasProducts && _selectedAddress == null && appState.defaultAddress == null) {
      _showMessage('Vui lòng chọn địa chỉ giao hàng.');
      return;
    }

    if (hasServices) {
      if (appState.myPets.isEmpty) {
        _showMessage('Vui lòng thêm thú cưng trước khi đặt lịch spa.');
        return;
      }
      if (_selectedPetId == null) {
        _showMessage('Vui lòng chọn thú cưng cho dịch vụ spa.');
        return;
      }
      if (_selectedBookingDate == null || _selectedBookingTime == null) {
        _showMessage('Vui lòng chọn ngày và giờ làm spa.');
        return;
      }
    }

    final address = _selectedAddress ?? appState.defaultAddress;
    final shippingAddressText = address != null ? _buildShippingAddressText(address, user) : '';
    final shippingFeeValue = hasProducts ? (_shippingFee ?? 0).round() : 0;
    final pickupFeeValue = hasServices && _transportOption == 1 ? _pickupFeeValue : 0;

    final selectedShopId = items.first.shopId;
    final productOrders = items
        .where((item) => !item.isService)
        .map(
          (item) => CheckoutProductOrderRequest(
            productId: item.productId ?? int.tryParse(item.id) ?? 0,
            qty: item.quantity,
            unitPrice: item.unitPrice,
          ),
        )
        .toList();

    final selectedBookingDate = _selectedBookingDate!;
    final selectedBookingTime = _selectedBookingTime!;
    final bookingDateTime = DateTime(
      selectedBookingDate.year,
      selectedBookingDate.month,
      selectedBookingDate.day,
      selectedBookingTime.hour,
      selectedBookingTime.minute,
    );

    final serviceBookings = items
        .where((item) => item.isService)
        .map(
          (item) => CheckoutServiceBookingRequest(
            serviceId: item.serviceId ?? int.tryParse(item.id) ?? 0,
            petId: _selectedPetId!,
            bookingDate: bookingDateTime,
            bookingTime: bookingDateTime,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          ),
        )
        .toList();

    final request = CheckoutRequestModel(
      shopId: selectedShopId,
      userId: user.id,
      receiverName: user.fullName,
      receiverPhone: user.phone,
      shippingAddress: shippingAddressText,
      shippingFee: shippingFeeValue,
      pickupFee: pickupFeeValue,
      discountAmount: 0,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      productOrders: productOrders,
      serviceBookings: serviceBookings,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _checkoutService.checkout(request);
      if (!mounted) return;

      context.read<AppState>().removeSelectedCartItems();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutSuccessScreen(response: response),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage('Thanh toán thất bại: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    showAppToast(context, message: message, type: AppToastType.warning);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final authProvider = context.watch<AuthProvider>();
    final items = _getCheckoutItems(state);
    final hasProducts = items.any((item) => !item.isService);
    final hasServices = items.any((item) => item.isService);
    final address = _selectedAddress ?? state.defaultAddress;
    final shippingFee = _shippingFee ?? 0;
    final pickupFee = hasServices && _transportOption == 1 ? _pickupFeeValue : 0;
    final subtotalAmount = _subtotalAmount(state);
    final totalAmount = subtotalAmount + shippingFee + pickupFee - 0;

    final productItems = items.where((item) => !item.isService).toList();
    final serviceItems = items.where((item) => item.isService).toList();

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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasProducts) ...[
                    _CheckoutCard(
                      title: 'Địa chỉ giao hàng',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _onSelectAddress,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(LucideIcons.mapPin, color: Color(0xFFFB7185), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          address != null ? address.name : 'Chọn địa chỉ nhận hàng',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          address != null
                                              ? _buildShippingAddressText(address, authProvider.currentUser)
                                              : 'Nhấn để chọn hoặc thêm địa chỉ giao hàng',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF64748B),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(LucideIcons.chevronRight, color: Color(0xFF94A3B8), size: 18),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            label: 'Phí vận chuyển',
                            value: _isLoadingFee
                                ? 'Đang tính...'
                                : _shippingFeeError != null
                                    ? _shippingFeeError!
                                    : PriceFormatter.formatVnd(_shippingFee ?? 0),
                            valueColor: _shippingFeeError != null
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF111827),
                          ),
                          if (_shippingFeeError != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _refreshShippingFee,
                              child: const Text('Thử lại'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (hasServices) ...[
                    _CheckoutCard(
                      title: 'Lịch dịch vụ Spa',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.isLoadingPets) ...[
                            const Center(child: CircularProgressIndicator()),
                            const SizedBox(height: 12),
                          ] else if (state.myPets.isEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bạn chưa có thú cưng nào',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Hãy thêm thú cưng để tiếp tục đặt lịch spa.',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final appState = context.read<AppState>();
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const AddPetScreen(),
                                          ),
                                        );
                                        if (result == true && mounted) {
                                          await appState.loadMyPets();
                                        }
                                      },
                                      icon: const Icon(LucideIcons.plus, size: 18),
                                      label: const Text('Thêm thú cưng'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            DropdownButtonFormField<int>(
                              initialValue: _selectedPetId,
                              decoration: InputDecoration(
                                labelText: 'Chọn thú cưng',
                                labelStyle: GoogleFonts.inter(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              items: state.myPets
                                  .map(
                                    (pet) => DropdownMenuItem<int>(
                                      value: pet.id,
                                      child: Text(
                                        pet.name,
                                        style: GoogleFonts.inter(),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPetId = value;
                                });
                              },
                              hint: Text(
                                'Chọn thú cưng',
                                style: GoogleFonts.inter(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () async {
                                  final appState = context.read<AppState>();
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddPetScreen(),
                                    ),
                                  );
                                  if (result == true && mounted) {
                                    await appState.loadMyPets();
                                  }
                                },
                                icon: const Icon(LucideIcons.plus, size: 18),
                                label: const Text('Thêm thú cưng'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickBookingDate,
                                  icon: const Icon(LucideIcons.calendarDays, size: 18),
                                  label: Text(
                                    _selectedBookingDate == null
                                        ? 'Chọn ngày'
                                        : DateFormat('dd/MM/yyyy').format(_selectedBookingDate!),
                                    style: GoogleFonts.inter(),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickBookingTime,
                                  icon: const Icon(LucideIcons.clock3, size: 18),
                                  label: Text(
                                    _selectedBookingTime == null
                                        ? 'Chọn giờ'
                                        : _selectedBookingTime!.format(context),
                                    style: GoogleFonts.inter(),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _SummaryRow(
                            label: 'Lịch đã chọn',
                            value: _formatBookingSchedule(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CheckoutCard(
                      title: 'Hình thức nhận bé',
                      child: Column(
                        children: [
                          _TransportOptionCard(
                            selected: _transportOption == 0,
                            title: 'Đến shop',
                            subtitle: 'Bạn tự đưa bé đến spa',
                            onTap: () => setState(() => _transportOption = 0),
                          ),
                          const SizedBox(height: 12),
                          _TransportOptionCard(
                            selected: _transportOption == 1,
                            title: 'Shop đến đón bé',
                            subtitle:
                                'Cộng thêm ${PriceFormatter.formatVnd(_pickupFeeValue)}',
                            onTap: () => setState(() => _transportOption = 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _CheckoutCard(
                    title: 'Tóm tắt chi phí',
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: 'Tổng sản phẩm',
                          value: PriceFormatter.formatVnd(_productSubtotal(state)),
                        ),
                        _SummaryRow(
                          label: 'Tổng dịch vụ',
                          value: PriceFormatter.formatVnd(_serviceSubtotal(state)),
                        ),
                        _SummaryRow(
                          label: 'Phí vận chuyển',
                          value: PriceFormatter.formatVnd(shippingFee),
                        ),
                        if (hasServices) ...[
                          _SummaryRow(
                            label: 'Phí đón bé',
                            value: PriceFormatter.formatVnd(pickupFee),
                          ),
                        ],
                        _SummaryRow(
                          label: 'Giảm giá',
                          value: PriceFormatter.formatVnd(0),
                        ),
                        const Divider(height: 28),
                        _SummaryRow(
                          label: 'Tổng thanh toán',
                          value: PriceFormatter.formatVnd(totalAmount),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                          valueStyle: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CheckoutCard(
                    title: 'Ghi chú',
                    child: TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Nhập ghi chú cho đơn hàng hoặc lịch spa',
                        hintStyle: GoogleFonts.inter(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CheckoutCard(
                    title: 'Danh sách đã chọn',
                    child: Column(
                      children: [
                        ...productItems.map(
                          (item) => _CompactCheckoutItem(item: item),
                        ),
                        ...serviceItems.map(
                          (item) => _CompactCheckoutItem(item: item),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFB7185),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(
                        'Xác nhận đặt hàng',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _CheckoutCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TransportOptionCard extends StatelessWidget {
  const _TransportOptionCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFB7185) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? const Color(0xFFFB7185) : const Color(0xFF94A3B8),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFB7185),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: labelStyle ?? GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: valueStyle ??
                GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF111827),
                ),
          ),
        ],
      ),
    );
  }
}

class _CompactCheckoutItem extends StatelessWidget {
  final CartItem item;

  const _CompactCheckoutItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item.imageUrl,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 46,
                  height: 46,
                  color: const Color(0xFFE2E8F0),
                  child: const Icon(Icons.pets, size: 18, color: Color(0xFF94A3B8)),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.isService ? 'Dịch vụ Spa' : 'Sản phẩm mua sắm',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            PriceFormatter.formatVnd(item.amount),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}