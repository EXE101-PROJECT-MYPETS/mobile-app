import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pawly_mobile/apps/cart/model/cart_item_model.dart';
import 'package:pawly_mobile/apps/checkout/api/checkout_service.dart';
import 'package:pawly_mobile/apps/checkout/api/shipping_service.dart';
import 'package:pawly_mobile/apps/checkout/model/address_model.dart';
import 'package:pawly_mobile/apps/checkout/model/checkout_request_model.dart';
import 'package:pawly_mobile/apps/checkout/model/ghtk_fee_model.dart';
import 'package:pawly_mobile/apps/checkout/page/address_selection_screen.dart';
import 'package:pawly_mobile/apps/checkout/page/checkout_success_screen.dart';
import 'package:pawly_mobile/apps/product/api/product_service.dart';
import 'package:pawly_mobile/apps/profile/page/add_pet_screen.dart';
import 'package:pawly_mobile/apps/shop/page/shop_detail_screen.dart';
import 'package:pawly_mobile/common/auth/store/auth_provider.dart';
import 'package:pawly_mobile/common/store/app_state.dart';
import 'package:pawly_mobile/common/toast/app_toast.dart';
import 'package:pawly_mobile/common/user/model/user_model.dart';
import 'package:pawly_mobile/common/utils/price_formatter.dart';
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
  final ProductService _productService = ProductService();
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
    return _getCheckoutItems(
      state,
    ).where((item) => item.isService).fold(0, (sum, item) => sum + item.amount);
  }

  int _subtotalAmount(AppState state) {
    return _productSubtotal(state) + _serviceSubtotal(state);
  }

  Future<num> _productWeight(AppState state) async {
    double totalWeight = 0;
    final productItems = _getCheckoutItems(
      state,
    ).where((item) => !item.isService);

    for (final item in productItems) {
      var weightKg = item.weightKg;
      if ((weightKg == null || weightKg <= 0) && item.productId != null) {
        try {
          final detail = await _productService.getProductDetail(
            item.productId.toString(),
          );
          weightKg = detail.weightKg;
        } catch (_) {
          weightKg = null;
        }
      }

      if (weightKg != null && weightKg > 0) {
        totalWeight += weightKg * item.quantity;
      }
    }

    return totalWeight;
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
      final num weight = await _productWeight(appState);

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
      MaterialPageRoute(builder: (context) => const AddressSelectionScreen()),
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

    if (user == null ||
        authProvider.token == null ||
        authProvider.token!.isEmpty) {
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

    if (hasProducts &&
        _selectedAddress == null &&
        appState.defaultAddress == null) {
      _showMessage('Vui lòng chọn địa chỉ giao hàng.');
      return;
    }

    if (hasProducts && _isLoadingFee) {
      _showMessage('Vui lòng chờ hệ thống tính phí vận chuyển.');
      return;
    }

    if (hasProducts && _shippingFeeError != null) {
      _showMessage('Vui lòng tính lại phí vận chuyển trước khi đặt hàng.');
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
    final userAddressId = hasProducts && address != null
        ? int.tryParse(address.id)
        : null;
    if (hasProducts && (userAddressId == null || userAddressId <= 0)) {
      _showMessage('Địa chỉ giao hàng chưa hợp lệ. Vui lòng chọn lại địa chỉ.');
      return;
    }

    final shippingAddressText = address != null
        ? _buildShippingAddressText(address, user)
        : '';
    final shippingFeeValue = hasProducts ? (_shippingFee ?? 0).round() : 0;
    final pickupFeeValue = hasServices && _transportOption == 1
        ? _pickupFeeValue
        : 0;

    final selectedShopId = items.first.shopId;
    if (selectedShopId <= 0) {
      _showMessage('Không tìm thấy thông tin cửa hàng của giỏ hàng.');
      return;
    }

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

    if (hasProducts &&
        productOrders.any((item) => item.productId <= 0 || item.qty <= 0)) {
      _showMessage('Thông tin sản phẩm trong giỏ hàng chưa hợp lệ.');
      return;
    }

    final DateTime? bookingDateTime = hasServices
        ? DateTime(
            _selectedBookingDate!.year,
            _selectedBookingDate!.month,
            _selectedBookingDate!.day,
            _selectedBookingTime!.hour,
            _selectedBookingTime!.minute,
          )
        : null;

    final serviceBookings = hasServices
        ? items
              .where((item) => item.isService)
              .map(
                (item) => CheckoutServiceBookingRequest(
                  serviceId: item.serviceId ?? int.tryParse(item.id) ?? 0,
                  petId: _selectedPetId!,
                  bookingDate: bookingDateTime!,
                  bookingTime: bookingDateTime,
                  note: _noteController.text.trim().isEmpty
                      ? null
                      : _noteController.text.trim(),
                ),
              )
              .toList()
        : <CheckoutServiceBookingRequest>[];

    if (hasServices &&
        serviceBookings.any((item) => item.serviceId <= 0 || item.petId <= 0)) {
      _showMessage('Thông tin dịch vụ trong giỏ hàng chưa hợp lệ.');
      return;
    }

    final request = CheckoutRequestModel(
      shopId: selectedShopId,
      userId: user.id,
      userAddressId: userAddressId,
      receiverName: user.fullName,
      receiverPhone: user.phone,
      shippingAddress: shippingAddressText,
      shippingFee: shippingFeeValue,
      pickupFee: pickupFeeValue,
      discountAmount: 0,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
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
    final shippingFee = (_shippingFee ?? 0).round();
    final pickupFee = hasServices && _transportOption == 1
        ? _pickupFeeValue
        : 0;
    final subtotalAmount = _subtotalAmount(state);
    final totalAmount = subtotalAmount + shippingFee + pickupFee - 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Color(0xFFFF4D2D)),
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
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasProducts) ...[
                    _AddressCheckoutBlock(
                      addressName: address?.name,
                      phone: address?.phone,
                      addressText: address != null
                          ? _buildShippingAddressText(
                              address,
                              authProvider.currentUser,
                            )
                          : null,
                      onTap: _onSelectAddress,
                    ),
                    const SizedBox(height: 10),
                  ],
                  _ShopCheckoutBlock(
                    shopName: items.isNotEmpty
                        ? items.first.shopName
                        : 'Cửa hàng Pawly',
                    shopId: items.isNotEmpty ? items.first.shopId : null,
                    items: items,
                    noteController: _noteController,
                  ),
                  const SizedBox(height: 10),
                  if (hasProducts) ...[
                    _ShippingMethodBlock(
                      isLoading: _isLoadingFee,
                      error: _shippingFeeError,
                      fee: shippingFee,
                      onRetry: _refreshShippingFee,
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (hasServices) ...[
                    _CheckoutCard(
                      title: 'Thông tin lịch dịch vụ',
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
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
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
                                        final appState = context
                                            .read<AppState>();
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AddPetScreen(),
                                          ),
                                        );
                                        if (result == true && mounted) {
                                          await appState.loadMyPets();
                                        }
                                      },
                                      icon: const Icon(
                                        LucideIcons.plus,
                                        size: 18,
                                      ),
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
                                      builder: (context) =>
                                          const AddPetScreen(),
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
                                  icon: const Icon(
                                    LucideIcons.calendar_days,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _selectedBookingDate == null
                                        ? 'Chọn ngày'
                                        : DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_selectedBookingDate!),
                                    style: GoogleFonts.inter(),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 12,
                                    ),
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
                                  icon: const Icon(
                                    LucideIcons.clock_3,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _selectedBookingTime == null
                                        ? 'Chọn giờ'
                                        : _selectedBookingTime!.format(context),
                                    style: GoogleFonts.inter(),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 12,
                                    ),
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
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 10),
                  ],
                  const _PaymentMethodBlock(),
                  const SizedBox(height: 10),
                  _PaymentDetailBlock(
                    productTotal: _productSubtotal(state),
                    serviceTotal: _serviceSubtotal(state),
                    shippingFee: shippingFee,
                    pickupFee: pickupFee,
                    showPickupFee: hasServices,
                    totalAmount: totalAmount,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Nhấn "Đặt hàng" đồng nghĩa với việc bạn đồng ý với điều khoản mua hàng và đặt lịch của Pawly.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _CheckoutBottomBar(
            totalAmount: totalAmount,
            isSubmitting: _isSubmitting,
            onSubmit: _submitCheckout,
          ),
        ],
      ),
    );
  }
}

class _AddressCheckoutBlock extends StatelessWidget {
  const _AddressCheckoutBlock({
    required this.addressName,
    required this.phone,
    required this.addressText,
    required this.onTap,
  });

  final String? addressName;
  final String? phone;
  final String? addressText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAddress = addressText?.trim().isNotEmpty == true;

    return _FlatCheckoutBlock(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.map_pin,
                  color: Color(0xFFFF4D2D),
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasAddress
                          ? [addressName?.trim(), phone?.trim()]
                                .whereType<String>()
                                .where((v) => v.isNotEmpty)
                                .join('  ')
                          : 'Chọn địa chỉ nhận hàng',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF111827),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasAddress
                          ? addressText!
                          : 'Nhấn để chọn địa chỉ giao hàng mặc định',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Icon(
                  LucideIcons.chevron_right,
                  color: Color(0xFFCBD5E1),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopCheckoutBlock extends StatelessWidget {
  const _ShopCheckoutBlock({
    required this.shopName,
    required this.shopId,
    required this.items,
    required this.noteController,
  });

  final String shopName;
  final int? shopId;
  final List<CartItem> items;
  final TextEditingController noteController;

  @override
  Widget build(BuildContext context) {
    void openShop() {
      final id = shopId;
      if (id == null || id <= 0) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ShopDetailScreen(shopId: id, shopName: shopName),
        ),
      );
    }

    final canOpenShop = shopId != null && shopId! > 0;

    return _FlatCheckoutBlock(
      child: Column(
        children: [
          InkWell(
            onTap: canOpenShop ? openShop : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 8),
              child: Row(
                children: [
                  Expanded(
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
                  if (canOpenShop) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.chevron_right,
                      color: Color(0xFFCBD5E1),
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Column(
              children: items
                  .map((item) => _CompactCheckoutItem(item: item))
                  .toList(),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _CheckoutActionRow(
            label: 'Voucher của Shop',
            value: '-0đ',
            valueColor: const Color(0xFFFF4D2D),
            onTap: () {},
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
            child: Row(
              children: [
                Text(
                  'Lời nhắn cho Shop',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF334155),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: noteController,
                    textAlign: TextAlign.right,
                    minLines: 1,
                    maxLines: 2,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Để lại lời nhắn',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFFCBD5E1),
                        fontSize: 13,
                      ),
                    ),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF111827),
                      fontSize: 13,
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

class _ShippingMethodBlock extends StatelessWidget {
  const _ShippingMethodBlock({
    required this.isLoading,
    required this.error,
    required this.fee,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final num fee;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final shippingWindow = _formatShippingWindow(DateTime.now());

    return _FlatCheckoutBlock(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Phương thức vận chuyển',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF111827),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  'Xem tất cả',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  LucideIcons.chevron_right,
                  color: Color(0xFFCBD5E1),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FFFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF99DCC5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Giao hàng tiêu chuẩn',
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
                        isLoading
                            ? 'Đang tính...'
                            : error != null
                            ? 'Chưa có phí'
                            : PriceFormatter.formatVnd(fee),
                        style: GoogleFonts.inter(
                          color: error != null
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF059669),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nhận từ $shippingWindow. Đơn hàng sẽ được shop xác nhận trước khi giao.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onRetry,
                        child: const Text('Tính lại phí'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodBlock extends StatelessWidget {
  const _PaymentMethodBlock();

  @override
  Widget build(BuildContext context) {
    return _FlatCheckoutBlock(
      child: Column(
        children: [
          _CheckoutActionRow(
            label: 'Phương thức thanh toán',
            value: 'Xem tất cả',
            onTap: () {},
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.badge_dollar_sign,
                  color: Color(0xFFFF4D2D),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Thanh toán khi nhận hàng',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF111827),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  LucideIcons.circle_check_big,
                  color: Color(0xFFFF4D2D),
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentDetailBlock extends StatelessWidget {
  const _PaymentDetailBlock({
    required this.productTotal,
    required this.serviceTotal,
    required this.shippingFee,
    required this.pickupFee,
    required this.showPickupFee,
    required this.totalAmount,
  });

  final int productTotal;
  final int serviceTotal;
  final num shippingFee;
  final int pickupFee;
  final bool showPickupFee;
  final int totalAmount;

  @override
  Widget build(BuildContext context) {
    return _FlatCheckoutBlock(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chi tiết thanh toán',
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              label: 'Tổng tiền hàng',
              value: PriceFormatter.formatVnd(productTotal),
            ),
            if (serviceTotal > 0)
              _SummaryRow(
                label: 'Tổng tiền dịch vụ',
                value: PriceFormatter.formatVnd(serviceTotal),
              ),
            _SummaryRow(
              label: 'Tổng phí vận chuyển',
              value: PriceFormatter.formatVnd(shippingFee),
            ),
            if (showPickupFee)
              _SummaryRow(
                label: 'Phí đón bé',
                value: PriceFormatter.formatVnd(pickupFee),
              ),
            _SummaryRow(
              label: 'Tổng giảm giá',
              value: PriceFormatter.formatVnd(0),
            ),
            const Divider(height: 24, color: Color(0xFFF1F5F9)),
            _SummaryRow(
              label: 'Tổng thanh toán',
              value: PriceFormatter.formatVnd(totalAmount),
              labelStyle: GoogleFonts.inter(
                color: const Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              valueStyle: GoogleFonts.inter(
                color: const Color(0xFFFF4D2D),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutBottomBar extends StatelessWidget {
  const _CheckoutBottomBar({
    required this.totalAmount,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final int totalAmount;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Tổng cộng',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF334155),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  PriceFormatter.formatVnd(totalAmount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFF4D2D),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 122,
            height: 48,
            child: FilledButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF4D2D),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFFCA5A5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Đặt hàng',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlatCheckoutBlock extends StatelessWidget {
  const _FlatCheckoutBlock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class _CheckoutActionRow extends StatelessWidget {
  const _CheckoutActionRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF334155),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: GoogleFonts.inter(
                color: valueColor ?? const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              LucideIcons.chevron_right,
              color: Color(0xFFCBD5E1),
              size: 16,
            ),
          ],
        ),
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
                  color: selected
                      ? const Color(0xFFFB7185)
                      : const Color(0xFF94A3B8),
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

  const _SummaryRow({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
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
              style:
                  labelStyle ??
                  GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style:
                valueStyle ??
                GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
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
                  child: const Icon(
                    Icons.pets,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
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

String _formatShippingWindow(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final startDate = today.add(const Duration(days: 2));
  final endDate = today.add(const Duration(days: 5));
  return '${_formatShippingDate(startDate)} - ${_formatShippingDate(endDate)}';
}

String _formatShippingDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day Th$month';
}
