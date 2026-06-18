import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:pawly_mobile/apps/profile/api/pet_service.dart';
import 'package:pawly_mobile/apps/profile/model/pet_dto.dart';
import 'package:pawly_mobile/apps/service/api/service_service.dart';
import 'package:pawly_mobile/apps/service/model/booking_create_request.dart';
import 'package:pawly_mobile/apps/service/model/service_detail_dto.dart';
import 'package:pawly_mobile/apps/shop/page/shop_detail_screen.dart';
import 'package:pawly_mobile/common/auth/store/auth_provider.dart';
import 'package:pawly_mobile/common/component/login_required_sheet.dart';
import 'package:pawly_mobile/common/component/service_card.dart';
import 'package:pawly_mobile/common/user/dto/service_public_dto.dart';
import 'package:pawly_mobile/common/utils/image_url_util.dart';
import 'package:pawly_mobile/common/utils/price_formatter.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    this.name,
    this.image,
    this.price,
    this.shopId,
    this.shopName,
    this.rating,
    this.soldCount,
    this.address,
    this.distanceKm,
  });

  final int serviceId;
  final String? name;
  final String? image;
  final num? price;
  final int? shopId;
  final String? shopName;
  final double? rating;
  final int? soldCount;
  final String? address;
  final double? distanceKm;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  static const int _relatedPageSize = 10;

  final ServicePublicService _service = ServicePublicService();
  final ServiceBookingService _bookingService = ServiceBookingService();
  final PetService _petService = PetService();
  final TextEditingController _noteController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ServiceDetailDTO? _detail;
  List<PetDTO> _pets = const [];
  List<ServicePublicDTO> _relatedServices = const [];
  int? _selectedPetId;
  Object? _error;
  Object? _petsError;
  Object? _relatedError;
  int? _relatedCursor;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = true;
  bool _isLoadingPets = false;
  bool _isLoadingRelated = false;
  bool _hasMoreRelated = true;
  bool _requestedPets = false;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _loadDetail();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPetsIfNeeded();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await _service.getDetail(widget.serviceId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
      _loadPetsIfNeeded(detail: detail);
      _loadRelatedServices(reset: true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRelatedServices({bool reset = false}) async {
    if (_isLoadingRelated) return;
    if (!reset && !_hasMoreRelated) return;

    final serviceId = _detail?.id ?? widget.serviceId;

    setState(() {
      _isLoadingRelated = true;
      _relatedError = null;
      if (reset) {
        _relatedServices = const [];
        _relatedCursor = null;
        _hasMoreRelated = true;
      }
    });

    try {
      final response = await _service.getRelatedForScroll(
        serviceId: serviceId,
        cursor: reset ? null : _relatedCursor,
        size: _relatedPageSize,
      );
      if (!mounted) return;

      final existingIds = _relatedServices
          .map((service) => service.id)
          .whereType<int>()
          .toSet();
      final nextServices = response.content.where((service) {
        final id = service.id;
        return id != null && id != serviceId && !existingIds.contains(id);
      }).toList();

      setState(() {
        _relatedServices =
            reset ? nextServices : [..._relatedServices, ...nextServices];
        _relatedCursor = response.nextCursor;
        _hasMoreRelated = response.hasNext && response.nextCursor != null;
        _isLoadingRelated = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _relatedError = error;
        _hasMoreRelated = false;
        _isLoadingRelated = false;
      });
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter > 700) return;
    _loadRelatedServices();
  }

  Future<void> _loadPets() async {
    _requestedPets = true;
    setState(() {
      _isLoadingPets = true;
      _petsError = null;
    });

    try {
      final pets = await _petService.getAll();
      if (!mounted) return;
      final selectablePets = pets.where((pet) => pet.id != null).toList();
      final currentPetStillExists = selectablePets.any(
        (pet) => pet.id == _selectedPetId,
      );
      setState(() {
        _pets = pets;
        _selectedPetId = currentPetStillExists
            ? _selectedPetId
            : selectablePets.isNotEmpty
                ? selectablePets.first.id
                : null;
        _isLoadingPets = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _petsError = error;
        _isLoadingPets = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
      helpText: 'Chọn ngày đặt lịch',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (picked == null || !mounted) return;
    setState(() {
      _selectedDate = picked;
    });
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Chọn giờ đặt lịch',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (picked == null || !mounted) return;
    setState(() {
      _selectedTime = picked;
    });
  }

  Future<void> _openPets() async {
    await Navigator.pushNamed(context, '/pets');
    if (mounted) {
      _requestedPets = false;
      await _loadPets();
    }
  }

  Future<void> _openPetPicker() async {
    final petItems = _pets.where((pet) => pet.id != null).toList();
    if (petItems.isEmpty) return;

    final selectedPetId = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PetPickerSheet(
        pets: petItems,
        selectedPetId: _selectedPetId,
        onManagePets: () {
          Navigator.pop(context);
          _openPets();
        },
      ),
    );

    if (selectedPetId == null || !mounted) return;
    setState(() {
      _selectedPetId = selectedPetId;
    });
  }

  Future<void> _createBooking(ServiceDetailDTO detail) async {
    final authProvider = context.read<AuthProvider>();
    if (!_isLoggedIn(authProvider)) {
      showLoginRequiredSheet(context);
      return;
    }

    final shopId = detail.shopId;
    final serviceId = detail.id;
    final requiresPet = _requiresPet(detail);
    final selectablePets = _pets.where((pet) => pet.id != null).toList();
    final petId = requiresPet
        ? (_selectedPetId ??
            (selectablePets.isNotEmpty ? selectablePets.first.id : null))
        : null;

    if (shopId == null) {
      _showMessage('Dịch vụ chưa có thông tin cửa hàng');
      return;
    }
    if (serviceId == null) {
      _showMessage('Không tìm thấy mã dịch vụ');
      return;
    }
    if (requiresPet && petId == null) {
      _showMessage('Vui lòng chọn thú cưng');
      return;
    }

    final startAt = _selectedStartAt;
    if (!startAt.isAfter(DateTime.now())) {
      _showMessage('Vui lòng chọn thời gian trong tương lai');
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      await _bookingService.createBooking(
        shopId: shopId,
        request: BookingCreateRequest(
          petId: petId,
          startAt: startAt,
          note: _noteController.text,
          items: [
            BookingItemCreateRequest(
              itemType: 'SERVICE',
              refId: serviceId,
              qty: 1,
            ),
          ],
        ),
      );

      if (!mounted) return;
      _showMessage('Đã gửi yêu cầu đặt lịch');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  DateTime get _selectedStartAt {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  bool _isLoggedIn(AuthProvider authProvider) {
    return authProvider.currentUser != null &&
        (authProvider.token?.trim().isNotEmpty ?? false);
  }

  void _loadPetsIfNeeded({ServiceDetailDTO? detail}) {
    final effectiveDetail = detail ?? _detail;
    if (effectiveDetail == null || _requestedPets) return;
    if (!_requiresPet(effectiveDetail)) return;
    if (!_isLoggedIn(context.read<AuthProvider>())) return;

    _requestedPets = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPets();
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final isLoggedIn = _isLoggedIn(context.watch<AuthProvider>());
    if (detail != null && isLoggedIn) {
      _loadPetsIfNeeded(detail: detail);
    }

    if (_isLoading) {
      return _LoadingState(title: widget.name ?? 'Chi tiết dịch vụ');
    }

    if (_error != null) {
      return _ErrorState(error: _error!, onRetry: _loadDetail);
    }

    if (detail == null) {
      return _ErrorState(
        error: Exception('Không có dữ liệu dịch vụ'),
        onRetry: _loadDetail,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _ServiceDetailContent(
        scrollController: _scrollController,
        detail: detail,
        pets: _pets,
        relatedServices: _relatedServices,
        selectedPetId: _selectedPetId,
        selectedDate: _selectedDate,
        selectedTime: _selectedTime,
        noteController: _noteController,
        isLoggedIn: isLoggedIn,
        requiresPet: _requiresPet(detail),
        isLoadingPets: _isLoadingPets,
        isLoadingRelated: _isLoadingRelated,
        hasMoreRelated: _hasMoreRelated,
        petsError: _petsError,
        relatedError: _relatedError,
        onSelectDate: _selectDate,
        onSelectTime: _selectTime,
        onSelectPet: _openPetPicker,
        onManagePets: _openPets,
        onRetryPets: _loadPets,
        onRetryRelated: () => _loadRelatedServices(reset: true),
      ),
      bottomNavigationBar: _BookingBar(
        detail: detail,
        isBooking: _isBooking,
        onSubmit: () => _createBooking(detail),
      ),
    );
  }
}

class _ServiceDetailContent extends StatelessWidget {
  const _ServiceDetailContent({
    required this.scrollController,
    required this.detail,
    required this.pets,
    required this.relatedServices,
    required this.selectedPetId,
    required this.selectedDate,
    required this.selectedTime,
    required this.noteController,
    required this.isLoggedIn,
    required this.requiresPet,
    required this.isLoadingPets,
    required this.isLoadingRelated,
    required this.hasMoreRelated,
    required this.petsError,
    required this.relatedError,
    required this.onSelectDate,
    required this.onSelectTime,
    required this.onSelectPet,
    required this.onManagePets,
    required this.onRetryPets,
    required this.onRetryRelated,
  });

  final ScrollController scrollController;
  final ServiceDetailDTO detail;
  final List<PetDTO> pets;
  final List<ServicePublicDTO> relatedServices;
  final int? selectedPetId;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final TextEditingController noteController;
  final bool isLoggedIn;
  final bool requiresPet;
  final bool isLoadingPets;
  final bool isLoadingRelated;
  final bool hasMoreRelated;
  final Object? petsError;
  final Object? relatedError;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;
  final VoidCallback onSelectPet;
  final VoidCallback onManagePets;
  final VoidCallback onRetryPets;
  final VoidCallback onRetryRelated;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverAppBar(
          pinned: true,
          stretch: true,
          expandedHeight: 320,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          leading: IconButton.filled(
            tooltip: 'Quay lại',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.92),
              foregroundColor: const Color(0xFF111827),
            ),
            icon: const Icon(LucideIcons.arrow_left, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Chi tiết dịch vụ',
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: _HeroImage(detail: detail),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderPanel(detail: detail),
                const SizedBox(height: 12),
                _QuickInfoPanel(detail: detail),
                const SizedBox(height: 12),
                _ShopPanel(detail: detail),
                const SizedBox(height: 12),
                _ReviewsPanel(detail: detail),
                const SizedBox(height: 12),
                _SchedulePanel(
                  pets: pets,
                  selectedPetId: selectedPetId,
                  selectedDate: selectedDate,
                  selectedTime: selectedTime,
                  noteController: noteController,
                  isLoggedIn: isLoggedIn,
                  requiresPet: requiresPet,
                  isLoadingPets: isLoadingPets,
                  petsError: petsError,
                  onSelectDate: onSelectDate,
                  onSelectTime: onSelectTime,
                  onSelectPet: onSelectPet,
                  onManagePets: onManagePets,
                  onRetryPets: onRetryPets,
                ),
                const SizedBox(height: 12),
                _RelatedServicesPanel(
                  services: relatedServices,
                  isLoading: isLoadingRelated,
                  hasMore: hasMoreRelated,
                  error: relatedError,
                  onRetry: onRetryRelated,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.detail});

  final ServiceDetailDTO detail;

  @override
  Widget build(BuildContext context) {
    final imageUrl = detail.imageUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageUrl != null)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const _ServiceFallbackImage(),
          )
        else
          const _ServiceFallbackImage(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.06),
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                    icon: LucideIcons.sparkles,
                    text: _serviceTypeLabel(detail.serviceType),
                    color: const Color(0xFFFFE4E6),
                    textColor: const Color(0xFFE11D48),
                  ),
                  if (detail.active != null)
                    _Pill(
                      icon: detail.active!
                          ? LucideIcons.circle_check_big
                          : LucideIcons.circle_alert,
                      text: detail.active! ? 'Đang mở đặt lịch' : 'Tạm ngưng',
                      color: detail.active!
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                      textColor: detail.active!
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB91C1C),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _displayText(detail.name, 'Dịch vụ'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderPanel extends StatelessWidget {
  const _HeaderPanel({required this.detail});

  final ServiceDetailDTO detail;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            PriceFormatter.formatVnd(detail.basePrice),
            style: GoogleFonts.inter(
              color: const Color(0xFFE11D48),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (detail.categoryName?.isNotEmpty == true)
                _Pill(
                  icon: LucideIcons.tag,
                  text: detail.categoryName!,
                  color: const Color(0xFFFFF7ED),
                  textColor: const Color(0xFFC2410C),
                ),
              if (detail.durationMin != null)
                _Pill(
                  icon: LucideIcons.clock,
                  text: '${detail.durationMin} phút',
                  color: const Color(0xFFEFF6FF),
                  textColor: const Color(0xFF1D4ED8),
                ),
              if (detail.distanceKm != null)
                _Pill(
                  icon: LucideIcons.map_pin,
                  text: _formatDistance(detail.distanceKm!),
                  color: const Color(0xFFF0FDF4),
                  textColor: const Color(0xFF166534),
                ),
              if ((detail.rating ?? 0) > 0 || (detail.ratingCount ?? 0) > 0)
                _Pill(
                  icon: LucideIcons.star,
                  text:
                      '${_formatRating(detail.rating ?? 0)} (${detail.ratingCount ?? 0} đánh giá)',
                  color: const Color(0xFFFFF7ED),
                  textColor: const Color(0xFFC2410C),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickInfoPanel extends StatelessWidget {
  const _QuickInfoPanel({required this.detail});

  final ServiceDetailDTO detail;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _DetailRow(
        icon: LucideIcons.activity,
        label: 'Loại dịch vụ',
        value: _serviceTypeLabel(detail.serviceType),
      ),
    ];

    if (!_requiresPet(detail)) {
      rows.add(
        _DetailRow(
          icon: LucideIcons.tag,
          label: 'Nhóm dịch vụ',
          value: _displayText(detail.categoryName, 'Đang cập nhật'),
        ),
      );
    }

    if (detail.veterinaryServiceType?.isNotEmpty == true) {
      rows.add(
        _DetailRow(
          icon: Icons.medical_services_outlined,
          label: 'Dịch vụ thú y',
          value: _veterinaryTypeLabel(detail.veterinaryServiceType),
        ),
      );
    }

    if (detail.vaccineName?.isNotEmpty == true) {
      rows.add(
        _DetailRow(
          icon: Icons.vaccines_outlined,
          label: 'Vắc xin',
          value: detail.vaccineName!,
        ),
      );
    }

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(icon: LucideIcons.file_text, text: 'Thông tin dịch vụ'),
          const SizedBox(height: 12),
          ...rows.expand((row) sync* {
            yield row;
            if (row != rows.last) yield const SizedBox(height: 10);
          }),
        ],
      ),
    );
  }
}

class _ShopPanel extends StatelessWidget {
  const _ShopPanel({required this.detail});

  final ServiceDetailDTO detail;

  @override
  Widget build(BuildContext context) {
    void openShop() {
      if (detail.shopId == null) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShopDetailScreen(
            shopId: detail.shopId,
            shopName: detail.shopName,
            shopAvatarUrl: detail.shopImageUrl,
          ),
        ),
      );
    }

    final canOpenShop = detail.shopId != null;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(icon: LucideIcons.store, text: 'Cửa hàng cung cấp'),
          const SizedBox(height: 14),
          InkWell(
            onTap: canOpenShop ? openShop : null,
            borderRadius: BorderRadius.circular(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: detail.shopImageUrl != null
                        ? Image.network(
                            detail.shopImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const _ShopFallbackImage(),
                          )
                        : const _ShopFallbackImage(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayText(detail.shopName, 'Cửa hàng'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF111827),
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      if (detail.shopPhone?.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        _InlineInfo(
                          icon: LucideIcons.phone,
                          text: detail.shopPhone!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (canOpenShop) ...[
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      LucideIcons.chevron_right,
                      color: Color(0xFFCBD5E1),
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (detail.shopAddress?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _InlineInfo(icon: LucideIcons.map_pin, text: detail.shopAddress!),
          ],
        ],
      ),
    );
  }
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({
    required this.pets,
    required this.selectedPetId,
    required this.selectedDate,
    required this.selectedTime,
    required this.noteController,
    required this.isLoggedIn,
    required this.requiresPet,
    required this.isLoadingPets,
    required this.petsError,
    required this.onSelectDate,
    required this.onSelectTime,
    required this.onSelectPet,
    required this.onManagePets,
    required this.onRetryPets,
  });

  final List<PetDTO> pets;
  final int? selectedPetId;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final TextEditingController noteController;
  final bool isLoggedIn;
  final bool requiresPet;
  final bool isLoadingPets;
  final Object? petsError;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;
  final VoidCallback onSelectPet;
  final VoidCallback onManagePets;
  final VoidCallback onRetryPets;

  @override
  Widget build(BuildContext context) {
    final petItems = pets.where((pet) => pet.id != null).toList();
    final selectedValue = petItems.any((pet) => pet.id == selectedPetId)
        ? selectedPetId
        : petItems.isNotEmpty
            ? petItems.first.id
            : null;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(icon: LucideIcons.calendar_check, text: 'Chọn lịch hẹn'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  icon: LucideIcons.calendar,
                  label: 'Ngày',
                  value: _formatDate(selectedDate),
                  onTap: onSelectDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickerTile(
                  icon: LucideIcons.clock,
                  label: 'Giờ',
                  value: MaterialLocalizations.of(
                    context,
                  ).formatTimeOfDay(selectedTime, alwaysUse24HourFormat: true),
                  onTap: onSelectTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: _inputDecoration(
              icon: LucideIcons.message_circle,
              label: 'Ghi chú',
              hint: 'Ví dụ: Tiêm nhắc lại, bé hơi nhạy cảm...',
            ),
          ),
          if (requiresPet && isLoggedIn) ...[
            const SizedBox(height: 12),
            if (isLoadingPets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFE11D48)),
                      const SizedBox(height: 12),
                      Text(
                        'Đang tải thú cưng...',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (petsError != null)
              _PanelPrompt(
                icon: LucideIcons.circle_alert,
                title: 'Không thể tải thú cưng',
                message: petsError.toString().replaceFirst('Exception: ', ''),
                buttonText: 'Thử lại',
                onPressed: onRetryPets,
              )
            else if (petItems.isEmpty)
              _PanelPrompt(
                icon: Icons.pets,
                title: 'Bạn chưa có thú cưng',
                message: 'Hãy thêm thú cưng để tạo lịch hẹn cho dịch vụ này.',
                buttonText: 'Quản lý thú cưng',
                onPressed: onManagePets,
              )
            else
              _PetSelectTile(
                pet: _findPetById(petItems, selectedValue),
                onTap: onSelectPet,
              ),
          ],
        ],
      ),
    );
  }
}

class _RelatedServicesPanel extends StatelessWidget {
  const _RelatedServicesPanel({
    required this.services,
    required this.isLoading,
    required this.hasMore,
    required this.error,
    required this.onRetry,
  });

  final List<ServicePublicDTO> services;
  final bool isLoading;
  final bool hasMore;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final errorMessage = error?.toString().replaceFirst('Exception: ', '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.layers, size: 18, color: Color(0xFFE11D48)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Dịch vụ liên quan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (services.isEmpty && isLoading)
          const _RelatedServicesLoading()
        else if (services.isEmpty && error != null)
          _PanelPrompt(
            icon: LucideIcons.circle_alert,
            title: 'Không thể tải dịch vụ liên quan',
            message: errorMessage ?? 'Vui lòng thử lại sau.',
            buttonText: 'Thử lại',
            onPressed: onRetry,
          )
        else if (services.isEmpty)
          const _RelatedServicesEmpty()
        else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              const itemGap = 10.0;
              final itemWidth = (constraints.maxWidth - itemGap) / 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: itemGap,
                  mainAxisSpacing: itemGap,
                  childAspectRatio: 0.66,
                ),
                itemBuilder: (context, index) {
                  return ServiceCard(
                    service: services[index],
                    width: itemWidth,
                  );
                },
              );
            },
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFE11D48)),
              ),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _InlineRetry(
                message: errorMessage ?? 'Không thể tải thêm dịch vụ.',
                onRetry: onRetry,
              ),
            )
          else if (!hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Text(
                  'Đã hiển thị hết dịch vụ liên quan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _RelatedServicesLoading extends StatelessWidget {
  const _RelatedServicesLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFFE11D48)),
      ),
    );
  }
}

class _RelatedServicesEmpty extends StatelessWidget {
  const _RelatedServicesEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Chưa có dịch vụ liên quan.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InlineRetry extends StatelessWidget {
  const _InlineRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.circle_alert,
            color: Color(0xFFE11D48),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _inputDecoration(icon: icon, label: label),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PetSelectTile extends StatelessWidget {
  const _PetSelectTile({required this.pet, required this.onTap});

  final PetDTO? pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCE7F3)),
        ),
        child: Row(
          children: [
            _PetAvatar(pet: pet, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thú cưng',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pet?.name ?? 'Chọn thú cưng',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (pet != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      _petMeta(pet!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              LucideIcons.chevron_right,
              color: Color(0xFFE11D48),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PetPickerSheet extends StatelessWidget {
  const _PetPickerSheet({
    required this.pets,
    required this.selectedPetId,
    required this.onManagePets,
  });

  final List<PetDTO> pets;
  final int? selectedPetId;
  final VoidCallback onManagePets;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.pets, color: Color(0xFFE11D48)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chọn thú cưng',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF111827),
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Chọn hồ sơ phù hợp cho lịch hẹn thú y',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: pets.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final pet = pets[index];
                  final isSelected = pet.id == selectedPetId;
                  return _PetChoiceTile(
                    pet: pet,
                    isSelected: isSelected,
                    onTap: () => Navigator.pop(context, pet.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onManagePets,
                icon: const Icon(Icons.pets, size: 18),
                label: const Text('Quản lý thú cưng'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE11D48),
                  side: const BorderSide(color: Color(0xFFFDA4AF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetChoiceTile extends StatelessWidget {
  const _PetChoiceTile({
    required this.pet,
    required this.isSelected,
    required this.onTap,
  });

  final PetDTO pet;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? const Color(0xFFE11D48) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            _PetAvatar(pet: pet, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _petMeta(pet),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSelected
                  ? LucideIcons.circle_check_big
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFFE11D48)
                  : const Color(0xFFCBD5E1),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({required this.pet, required this.size});

  final PetDTO? pet;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ImageUrlUtil.buildPublicUrl(pet?.avatarUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.35),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _PetAvatarFallback(),
              )
            : const _PetAvatarFallback(),
      ),
    );
  }
}

class _PetAvatarFallback extends StatelessWidget {
  const _PetAvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFE4E6),
      child: const Icon(Icons.pets, color: Color(0xFFE11D48), size: 22),
    );
  }
}

class _PanelPrompt extends StatelessWidget {
  const _PanelPrompt({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFE11D48), size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 13,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE11D48),
              side: const BorderSide(color: Color(0xFFFDA4AF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

class _ReviewsPanel extends StatelessWidget {
  const _ReviewsPanel({required this.detail});

  static const int _previewLimit = 5;

  final ServiceDetailDTO detail;

  @override
  Widget build(BuildContext context) {
    final reviews = detail.reviews ?? const <ServiceDetailReviewDTO>[];
    final rating = detail.rating ?? _averageServiceRating(reviews);
    final total = detail.ratingCount ?? reviews.length;
    final previewReviews = reviews.take(_previewLimit).toList();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(icon: LucideIcons.star, text: 'Đánh giá khách hàng'),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _formatRating(rating),
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.star_rounded,
                color: Color(0xFFF59E0B),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đánh giá dịch vụ ($total)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (reviews.length > _previewLimit)
                TextButton(
                  onPressed: () => _showAllReviews(context, reviews),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(
                    'Tất cả',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            Text(
              'Chưa có đánh giá nào.',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            ...previewReviews.map(
              (review) => _ServiceReviewCard(review: review),
            ),
            if (reviews.length > _previewLimit)
              TextButton(
                onPressed: () => _showAllReviews(context, reviews),
                child: const Text('Xem tất cả đánh giá'),
              ),
          ],
        ],
      ),
    );
  }

  void _showAllReviews(
    BuildContext context,
    List<ServiceDetailReviewDTO> reviews,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.82,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Tất cả đánh giá (${reviews.length})',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF111827),
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      return _ServiceReviewCard(review: reviews[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiceReviewCard extends StatelessWidget {
  const _ServiceReviewCard({required this.review});

  final ServiceDetailReviewDTO review;

  @override
  Widget build(BuildContext context) {
    final user = review.user;
    final avatarUrl = user?.avatarUrl;
    final reviewerName = user?.fullName ?? user?.email ?? 'Khách hàng';
    final reviewDate = _formatReviewDate(review.date);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFE5E7EB),
                backgroundImage:
                    avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                        _reviewInitial(reviewerName),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _maskReviewerName(reviewerName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF111827),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < (review.star ?? 0).clamp(0, 5)
                              ? Icons.star
                              : Icons.star_border,
                          color: const Color(0xFFFBBF24),
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (reviewDate.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reviewDate,
              style: GoogleFonts.inter(
                color: const Color(0xFF9CA3AF),
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _displayText(review.content, 'Khách hàng chưa để lại nhận xét.'),
            style: GoogleFonts.inter(
              color: const Color(0xFF374151),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingBar extends StatelessWidget {
  const _BookingBar({
    required this.detail,
    required this.isBooking,
    required this.onSubmit,
  });

  final ServiceDetailDTO detail;
  final bool isBooking;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tạm tính',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    PriceFormatter.formatVnd(detail.basePrice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFE11D48),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: detail.active == false
                    ? null
                    : isBooking
                        ? null
                        : onSubmit,
                icon: isBooking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.calendar, size: 18),
                label: Text(isBooking ? 'Đang gửi...' : 'Đặt lịch'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFE11D48)),
            const SizedBox(height: 14),
            Text(
              'Đang tải chi tiết dịch vụ...',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is ServiceNotFoundException
        ? 'Không tìm thấy dịch vụ này'
        : 'Không thể tải chi tiết dịch vụ';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Chi tiết dịch vụ',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE4E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.circle_alert,
                  color: Color(0xFFE11D48),
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refresh_cw, size: 18),
                label: const Text('Thử lại'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFE11D48)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFFE11D48)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InlineInfo extends StatelessWidget {
  const _InlineInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceFallbackImage extends StatelessWidget {
  const _ServiceFallbackImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE4E6), Color(0xFFFFEDD5), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(LucideIcons.sparkles, color: Color(0xFFE11D48), size: 58),
      ),
    );
  }
}

class _ShopFallbackImage extends StatelessWidget {
  const _ShopFallbackImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF1F2),
      child: const Icon(LucideIcons.store, color: Color(0xFFE11D48)),
    );
  }
}

String _displayText(String? value, String fallback) {
  final text = value?.trim();
  return text == null || text.isEmpty ? fallback : text;
}

bool _requiresPet(ServiceDetailDTO detail) {
  return detail.serviceType?.trim().toUpperCase() == 'VETERINARY';
}

PetDTO? _findPetById(List<PetDTO> pets, int? id) {
  for (final pet in pets) {
    if (pet.id == id) return pet;
  }
  return null;
}

String _petMeta(PetDTO pet) {
  final parts = <String>[];
  if (pet.weightKg != null && pet.weightKg! > 0) {
    parts.add('${pet.weightKg!.toStringAsFixed(1)} kg');
  }
  if (pet.breedText?.trim().isNotEmpty == true) {
    parts.add(pet.breedText!.trim());
  }
  if (pet.gender?.trim().isNotEmpty == true) {
    parts.add(_genderLabel(pet.gender));
  }
  return parts.isEmpty ? 'Hồ sơ thú cưng' : parts.join(' • ');
}

String _genderLabel(String? value) {
  switch (value?.trim().toUpperCase()) {
    case 'MALE':
      return 'Đực';
    case 'FEMALE':
      return 'Cái';
    default:
      return _displayText(value, 'Chưa rõ giới tính');
  }
}

InputDecoration _inputDecoration({
  required IconData icon,
  required String label,
  String? hint,
}) {
  return InputDecoration(
    prefixIcon: Icon(icon, color: const Color(0xFFE11D48), size: 19),
    labelText: label,
    hintText: hint,
    labelStyle: GoogleFonts.inter(
      color: const Color(0xFF64748B),
      fontWeight: FontWeight.w700,
    ),
    hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFFFFBFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFFCE7F3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.3),
    ),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _formatDistance(double distanceKm) {
  if (distanceKm < 1) return '< 1 km';
  if (distanceKm >= 100) return '${distanceKm.round()} km';
  final value = distanceKm.toStringAsFixed(1);
  return '${value.endsWith('.0') ? value.substring(0, value.length - 2) : value} km';
}

double _averageServiceRating(List<ServiceDetailReviewDTO> reviews) {
  final stars = reviews
      .map((review) => review.star)
      .whereType<int>()
      .where((star) => star > 0)
      .toList();
  if (stars.isEmpty) return 0;
  return stars.reduce((sum, star) => sum + star) / stars.length;
}

String _formatRating(double rating) {
  return rating <= 0 ? '0.0' : rating.toStringAsFixed(1);
}

String _maskReviewerName(String? name) {
  final value = _displayText(name, 'Khách hàng');
  if (value.length <= 2) return value;
  return '${value[0]}${'*' * (value.length - 2)}${value[value.length - 1]}';
}

String _reviewInitial(String? name) {
  final value = _displayText(name, 'K');
  return value[0].toUpperCase();
}

String _formatReviewDate(String? raw) {
  final text = raw?.trim();
  if (text == null || text.isEmpty) return '';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;
  return '${parsed.day.toString().padLeft(2, '0')}/'
      '${parsed.month.toString().padLeft(2, '0')}/'
      '${parsed.year}';
}

String _serviceTypeLabel(String? value) {
  switch (value?.trim().toUpperCase()) {
    case 'GENERAL':
      return 'Dịch vụ tổng quát';
    case 'VETERINARY':
      return 'Dịch vụ thú y';
    default:
      return 'Dịch vụ';
  }
}

String _veterinaryTypeLabel(String? value) {
  switch (value?.trim().toUpperCase()) {
    case 'VACCINATION':
      return 'Tiêm phòng';
    case 'EXAMINATION':
      return 'Khám bệnh';
    case 'SURGERY':
      return 'Phẫu thuật';
    case 'DEWORMING':
      return 'Tẩy giun';
    default:
      return _displayText(value, 'Đang cập nhật');
  }
}
