import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawly_mobile/apps/cart/model/cart_item_model.dart';
import 'package:pawly_mobile/apps/checkout/page/checkout_screen.dart';
import 'package:pawly_mobile/apps/service/api/service_service.dart';
import 'package:pawly_mobile/apps/shop/api/shop_public_service.dart';
import 'package:pawly_mobile/apps/shop/model/nearby_shop_dto.dart';
import 'package:pawly_mobile/common/auth/store/auth_provider.dart';
import 'package:pawly_mobile/common/component/common_bottom_nav.dart';
import 'package:pawly_mobile/common/component/login_required_sheet.dart';
import 'package:pawly_mobile/common/component/service_card.dart';
import 'package:pawly_mobile/common/navigation/main_tab_navigation.dart';
import 'package:pawly_mobile/common/store/app_state.dart';
import 'package:pawly_mobile/common/user/dto/service_public_dto.dart';
import 'package:pawly_mobile/common/utils/external_url_launcher.dart';
import 'package:pawly_mobile/common/utils/price_formatter.dart';
import 'package:provider/provider.dart';

class SpaServiceScreen extends StatefulWidget {
  const SpaServiceScreen({
    super.key,
    this.petId,
    this.prefillKeyword,
    this.serviceType,
    this.preferredDateText,
    this.service,
  });

  final ServicePublicDTO? service;
  final int? petId;
  final String? prefillKeyword;
  final String? serviceType;
  final String? preferredDateText;

  @override
  State<SpaServiceScreen> createState() => _SpaServiceScreenState();
}

class _SpaServiceScreenState extends State<SpaServiceScreen> {
  final ShopPublicService _shopService = ShopPublicService();
  final ServicePublicService _serviceService = ServicePublicService();

  List<NearbyShopDTO> _nearbyShops = const [];
  NearbyShopDTO? _selectedShop;
  List<ServicePublicDTO> _shopServices = const [];
  bool _isLoadingShops = false;
  bool _isLoadingServices = false;
  String? _shopsError;
  String? _servicesError;
  double? _userLat;
  double? _userLng;
  int _serviceRequestSerial = 0;

  @override
  void initState() {
    super.initState();
    if (widget.service == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNearbyShops();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.service != null) {
      return _buildServiceLanding(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Đặt lịch nhanh',
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNearbyShops,
        child: _buildQuickBookingBody(),
      ),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 0,
        onTap: (index) =>
            MainTabNavigation.open(context, index, currentIndex: -1),
      ),
    );
  }

  Future<void> _loadNearbyShops() async {
    if (_isLoadingShops) return;

    setState(() {
      _isLoadingShops = true;
      _shopsError = null;
      _servicesError = null;
    });

    try {
      final location = await _resolveUserLocation();
      final shops = await _shopService.getNearby(
        lat: location.lat,
        lng: location.lng,
        size: 10,
      );

      if (!mounted) return;

      final nearestShop = shops.isNotEmpty ? shops.first : null;
      setState(() {
        _userLat = location.lat;
        _userLng = location.lng;
        _nearbyShops = shops;
        _selectedShop = nearestShop;
        _shopServices = const [];
        _isLoadingShops = false;
      });

      if (nearestShop != null) {
        await _loadServicesForShop(nearestShop);
      }
    } on _LocationUnavailableException catch (error) {
      if (!mounted) return;
      setState(() {
        _shopsError = error.message;
        _isLoadingShops = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _shopsError =
            'Không thể tải shop gần bạn. Vui lòng kiểm tra kết nối và thử lại.';
        _isLoadingShops = false;
      });
    }
  }

  Future<_UserLocation> _resolveUserLocation() async {
    final appState = context.read<AppState>();
    final cachedLat = appState.serviceUserLat;
    final cachedLng = appState.serviceUserLng;
    if (_hasValidLocation(cachedLat, cachedLng)) {
      return _UserLocation(cachedLat!, cachedLng!);
    }

    try {
      await Geolocator.isLocationServiceEnabled();

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const _LocationUnavailableException(
          'Ứng dụng cần vị trí của bạn để tìm shop gần nhất.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!_hasValidLocation(position.latitude, position.longitude)) {
        throw const _LocationUnavailableException(
          'Vị trí hiện tại chưa hợp lệ. Vui lòng thử lại.',
        );
      }

      return _UserLocation(position.latitude, position.longitude);
    } on _LocationUnavailableException {
      rethrow;
    } catch (_) {
      throw const _LocationUnavailableException(
        'Không thể lấy vị trí hiện tại. Vui lòng bật vị trí và thử lại.',
      );
    }
  }

  bool _hasValidLocation(double? lat, double? lng) {
    return lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  Future<void> _loadServicesForShop(NearbyShopDTO shop) async {
    final shopId = shop.id;
    if (shopId == null) return;
    final requestSerial = ++_serviceRequestSerial;

    setState(() {
      _selectedShop = shop;
      _shopServices = const [];
      _isLoadingServices = true;
      _servicesError = null;
    });

    try {
      final response = await _serviceService.getByShopForScroll(
        shopId: shopId,
        size: 20,
      );
      final services = response.content
          .map(
            (service) => service.distanceKm == null
                ? ServicePublicDTO(
                    service: service.service,
                    shop: service.shop,
                    distanceKm: shop.distanceKm,
                  )
                : service,
          )
          .toList(growable: false);

      if (!mounted || requestSerial != _serviceRequestSerial) return;
      setState(() {
        _shopServices = services;
        _isLoadingServices = false;
      });
    } catch (_) {
      if (!mounted || requestSerial != _serviceRequestSerial) return;
      setState(() {
        _servicesError = 'Không thể tải dịch vụ của shop này.';
        _isLoadingServices = false;
      });
    }
  }

  Widget _buildQuickBookingBody() {
    if (_isLoadingShops && _nearbyShops.isEmpty) {
      return const _ScrollableStateShell(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_shopsError != null && _nearbyShops.isEmpty) {
      return _ScrollableStateShell(
        child: _QuickBookingStateView(
          icon: LucideIcons.map_pin_off,
          title: 'Chưa lấy được vị trí',
          subtitle: _shopsError!,
          actionLabel: 'Thử lại',
          onAction: _loadNearbyShops,
        ),
      );
    }

    if (_nearbyShops.isEmpty) {
      return _ScrollableStateShell(
        child: _QuickBookingStateView(
          icon: LucideIcons.store,
          title: 'Chưa có shop gần bạn',
          subtitle: 'Hiện chưa tìm thấy shop đang hoạt động quanh vị trí này.',
          actionLabel: 'Tải lại',
          onAction: _loadNearbyShops,
        ),
      );
    }

    final veterinaryServices = _shopServices.where(_isVeterinary).toList();
    final spaServices = _shopServices
        .where((service) => !_isVeterinary(service))
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        if (_hasAiPrefill) ...[
          _AiPrefillCard(
            petId: widget.petId,
            prefillKeyword: widget.prefillKeyword,
            serviceType: widget.serviceType,
            preferredDateText: widget.preferredDateText,
          ),
          const SizedBox(height: 16),
        ],
        _SectionTitle(
          title: 'Chọn shop gần bạn',
          subtitle: _userLat != null && _userLng != null
              ? 'Hiển thị tối đa 10 shop gần vị trí hiện tại'
              : 'Shop được sắp xếp theo khoảng cách tăng dần',
        ),
        const SizedBox(height: 12),
        _NearbyShopStrip(
          shops: _nearbyShops,
          selectedShop: _selectedShop,
          isLoadingServices: _isLoadingServices,
          onSelect: _loadServicesForShop,
        ),
        const SizedBox(height: 18),
        if (_isLoadingServices && _shopServices.isEmpty)
          const _ServiceLoadingPanel()
        else if (_servicesError != null && _shopServices.isEmpty)
          _QuickBookingStateView(
            icon: LucideIcons.circle_alert,
            title: 'Không tải được dịch vụ',
            subtitle: _servicesError!,
            actionLabel: 'Tải lại',
            onAction: _selectedShop == null
                ? null
                : () => _loadServicesForShop(_selectedShop!),
          )
        else ...[
          _ServiceCarouselSection(
            title: 'Dịch vụ spa',
            subtitle: 'Tắm, grooming và chăm sóc tổng quát',
            services: spaServices,
            emptyTitle: 'Shop này chưa có dịch vụ spa',
          ),
          const SizedBox(height: 22),
          _ServiceCarouselSection(
            title: 'Dịch vụ thú y',
            subtitle: 'Khám bệnh, tiêm phòng và chăm sóc y tế',
            services: veterinaryServices,
            emptyTitle: 'Shop này chưa có dịch vụ thú y',
          ),
        ],
        if (_isLoadingServices && _shopServices.isNotEmpty) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(minHeight: 3),
        ],
      ],
    );
  }

  bool get _hasAiPrefill =>
      widget.petId != null ||
      (widget.prefillKeyword?.trim().isNotEmpty ?? false) ||
      (widget.serviceType?.trim().isNotEmpty ?? false) ||
      (widget.preferredDateText?.trim().isNotEmpty ?? false);

  bool _isVeterinary(ServicePublicDTO service) {
    final type = service.serviceType?.trim().toUpperCase();
    final veterinaryType = service.veterinaryServiceType?.trim();
    return type == 'VETERINARY' ||
        type == 'VET' ||
        (veterinaryType != null && veterinaryType.isNotEmpty);
  }

  Widget _buildServiceLanding(BuildContext context) {
    final service = widget.service!;
    final shopName = service.shopName?.trim() ?? 'Thông tin shop';
    final shopAddress = service.shopAddress?.trim();
    final distanceText = service.distanceKm != null
        ? _formatDistance(service.distanceKm!)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Thông tin spa',
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SpaLandingCard(
            title: 'Shop và vị trí',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name ?? 'Dịch vụ spa',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  shopName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
                if (shopAddress != null && shopAddress.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    shopAddress,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
                if (distanceText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Cách bạn: $distanceText',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFFE11D48),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final lat = service.shopLat;
                      final lng = service.shopLng;
                      final Uri uri = lat != null && lng != null
                          ? Uri.parse('google.navigation:q=$lat,$lng')
                          : Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(shopAddress ?? shopName)}',
                            );
                      await openExternalUrl(uri);
                    },
                    icon: const Icon(LucideIcons.map_pin, size: 18),
                    label: const Text('Chỉ đường'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SpaLandingCard(
            title: 'Dịch vụ đã chọn',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bạn sẽ chọn ngày, giờ, thú cưng và hình thức nhận bé ở màn thanh toán tiếp theo.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Giá dịch vụ',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        PriceFormatter.formatVnd(service.basePrice ?? 0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE11D48),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                final authProvider = context.read<AuthProvider>();
                if (authProvider.currentUser == null) {
                  showLoginRequiredSheet(context);
                  return;
                }

                final appState = context.read<AppState>();
                appState.prepareBuyNowService(service);
                final selectedItems = List<CartItem>.from(
                  appState.selectedCartItems,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CheckoutScreen(selectedItems: selectedItems),
                  ),
                );
              },
              child: Text(
                'Tiếp tục đặt lịch',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyShopStrip extends StatelessWidget {
  const _NearbyShopStrip({
    required this.shops,
    required this.selectedShop,
    required this.isLoadingServices,
    required this.onSelect,
  });

  final List<NearbyShopDTO> shops;
  final NearbyShopDTO? selectedShop;
  final bool isLoadingServices;
  final ValueChanged<NearbyShopDTO> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 164,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: shops.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final shop = shops[index];
            return _NearbyShopCard(
              shop: shop,
              isSelected: selectedShop?.id == shop.id,
              isBusy: isLoadingServices && selectedShop?.id == shop.id,
              onTap: () => onSelect(shop),
            );
          },
        ),
      ),
    );
  }
}

class _NearbyShopCard extends StatelessWidget {
  const _NearbyShopCard({
    required this.shop,
    required this.isSelected,
    required this.isBusy,
    required this.onTap,
  });

  final NearbyShopDTO shop;
  final bool isSelected;
  final bool isBusy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final openingHours = shop.openingHours?.trim();
    final closingHours = shop.closingHours?.trim();
    final hasHours =
        (openingHours?.isNotEmpty ?? false) ||
        (closingHours?.isNotEmpty ?? false);

    return SizedBox(
      width: 286,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF1F6) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF4F8B)
                    : const Color(0xFFE2E8F0),
                width: isSelected ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShopImage(url: shop.displayImageUrl),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name ?? 'Shop thú cưng',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF111827),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            shop.address ?? 'Địa chỉ đang cập nhật',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 160),
                      child: isBusy
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              isSelected
                                  ? LucideIcons.circle_check
                                  : LucideIcons.chevron_right,
                              key: ValueKey(isSelected),
                              color: isSelected
                                  ? const Color(0xFFE91E63)
                                  : const Color(0xFF94A3B8),
                              size: 18,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                SizedBox(
                  height: 17,
                  child: Visibility(
                    visible: isSelected && hasHours,
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.clock,
                          size: 13,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Giờ mở cửa: ${openingHours ?? '--:--'} - ${closingHours ?? '--:--'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF475569),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (shop.distanceKm != null)
                      _MetricBadge(
                        icon: LucideIcons.map_pin,
                        text: _formatDistance(shop.distanceKm!),
                        color: const Color(0xFFFF8B15),
                        foregroundColor: Colors.white,
                      ),
                    _MetricBadge(
                      icon: LucideIcons.sparkles,
                      text: '${shop.serviceCount ?? 0} dịch vụ',
                      color: const Color(0xFFFFE4EC),
                      foregroundColor: const Color(0xFFE11D48),
                    ),
                    if ((shop.rating ?? 0) > 0)
                      _MetricBadge(
                        icon: LucideIcons.star,
                        text: (shop.rating ?? 0).toStringAsFixed(1),
                        color: const Color(0xFFFFF7ED),
                        foregroundColor: const Color(0xFFC2410C),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceCarouselSection extends StatelessWidget {
  const _ServiceCarouselSection({
    required this.title,
    required this.subtitle,
    required this.services,
    required this.emptyTitle,
  });

  final String title;
  final String subtitle;
  final List<ServicePublicDTO> services;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title, subtitle: subtitle),
        const SizedBox(height: 12),
        if (services.isEmpty)
          _CompactEmptyState(title: emptyTitle)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const itemGap = 12.0;
              final itemWidth = ((constraints.maxWidth - itemGap) / 2).clamp(
                176.0,
                204.0,
              );

              return SizedBox(
                height: 282,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                    },
                  ),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: services.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: itemGap),
                    itemBuilder: (context, index) {
                      return ServiceCard(
                        service: services[index],
                        width: itemWidth,
                      );
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _AiPrefillCard extends StatelessWidget {
  const _AiPrefillCard({
    required this.petId,
    required this.prefillKeyword,
    required this.serviceType,
    required this.preferredDateText,
  });

  final int? petId;
  final String? prefillKeyword;
  final String? serviceType;
  final String? preferredDateText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD8BE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.bot, color: Color(0xFFE76F51), size: 18),
              const SizedBox(width: 8),
              Text(
                'Gợi ý từ Pawly AI',
                style: GoogleFonts.inter(
                  color: const Color(0xFF2E251F),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (petId != null)
            _PrefillLine(label: 'Thú cưng', value: 'ID $petId'),
          if (prefillKeyword?.trim().isNotEmpty ?? false)
            _PrefillLine(label: 'Từ khóa', value: prefillKeyword!.trim()),
          if (serviceType?.trim().isNotEmpty ?? false)
            _PrefillLine(label: 'Nhóm dịch vụ', value: serviceType!.trim()),
          if (preferredDateText?.trim().isNotEmpty ?? false)
            _PrefillLine(
              label: 'Thời gian gợi ý',
              value: preferredDateText!.trim(),
            ),
        ],
      ),
    );
  }
}

class _PrefillLine extends StatelessWidget {
  const _PrefillLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '$label: $value',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: const Color(0xFF7B685B),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        if (subtitle?.trim().isNotEmpty ?? false) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.3,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.icon,
    required this.text,
    required this.color,
    required this.foregroundColor,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: foregroundColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopImage extends StatelessWidget {
  const _ShopImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 54,
        height: 54,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _ShopImageFallback(),
              )
            : const _ShopImageFallback(),
      ),
    );
  }
}

class _ShopImageFallback extends StatelessWidget {
  const _ShopImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFE4EC),
      child: const Icon(LucideIcons.store, color: Color(0xFFE11D48)),
    );
  }
}

class _ServiceLoadingPanel extends StatelessWidget {
  const _ServiceLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 282,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _CompactEmptyState extends StatelessWidget {
  const _CompactEmptyState({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QuickBookingStateView extends StatelessWidget {
  const _QuickBookingStateView({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: const Color(0xFFFF4F8B)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sunny Spa - CS1',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.map_pin, size: 12, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '123 Đường Cầu Giấy, Q. Cầu Giấy, Hà Nội',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(LucideIcons.navigation, size: 12, color: Colors.pink),
                    SizedBox(width: 4),
                    Text(
                      'Cách bạn 1.2 km',
                      style: TextStyle(
                        color: Colors.pink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(LucideIcons.refresh_cw, size: 16),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScrollableStateShell extends StatelessWidget {
  const _ScrollableStateShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        child,
      ],
    );
  }
}

class _SpaLandingCard extends StatelessWidget {
  const _SpaLandingCard({required this.title, required this.child});

  final String title;
  final Widget child;

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

class _UserLocation {
  const _UserLocation(this.lat, this.lng);

  final double lat;
  final double lng;
}

class _LocationUnavailableException implements Exception {
  const _LocationUnavailableException(this.message);

  final String message;
}

String _formatDistance(double distanceKm) {
  if (distanceKm < 1) {
    return '< 1 km';
  }
  if (distanceKm >= 100) {
    return '${distanceKm.round()} km';
  }
  final value = distanceKm.toStringAsFixed(1);
  return '${value.endsWith('.0') ? value.substring(0, value.length - 2) : value} km';
}
