import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/apps/home/page/home_screen.dart';
import 'package:petpee_mobile/apps/home/page/notifications_screen.dart';
import 'package:petpee_mobile/apps/profile/page/profile_screen.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/common/component/common_bottom_nav.dart';
import 'package:petpee_mobile/common/component/login_required_sheet.dart';
import 'package:petpee_mobile/common/store/app_state.dart';
import 'package:petpee_mobile/common/user/dto/service_public_dto.dart';
import 'package:petpee_mobile/common/utils/external_url_launcher.dart';
import 'package:petpee_mobile/common/utils/price_formatter.dart';
import 'package:petpee_mobile/apps/profile/page/add_pet_screen.dart';
import 'package:petpee_mobile/features/chat/screens/pet_ai_selection_screen.dart';
import 'package:provider/provider.dart';
import 'package:petpee_mobile/apps/cart/model/cart_item_model.dart';
import 'package:petpee_mobile/apps/checkout/page/checkout_screen.dart';
import 'package:petpee_mobile/apps/cart/page/cart_screen.dart';
import 'spa_booking_confirmation_screen.dart';

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
  int _selectedPackage = 0;
  int _selectedTime = 1;
  int? _selectedPetId;

  // Lịch thực tế
  DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedPackage = _initialPackageIndex();
    if (widget.service == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final appState = context.read<AppState>();
        await appState.loadMyPets();
        if (!mounted) return;
        if (appState.myPets.isNotEmpty) {
          setState(() {
            _selectedPetId ??= widget.petId ?? appState.myPets.first.id;
          });
        }
      });
    }
  }

  int _initialPackageIndex() {
    final serviceType = widget.serviceType?.trim().toUpperCase();
    final keyword = widget.prefillKeyword?.trim().toLowerCase() ?? '';
    if (serviceType == 'VET' || keyword.contains('khám')) return 2;
    if (keyword.contains('tắm')) return 1;
    if (serviceType == 'GROOMING' ||
        keyword.contains('groom') ||
        keyword.contains('lông')) {
      return 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.service != null) {
      return _buildServiceLanding(context);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Đặt lịch Dịch vụ Spa',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionTitle(title: 'Thông Tin Spa'),
                  _buildShopLocation(),
                  const SizedBox(height: 12),
                  if (_hasAiPrefill) ...[
                    _buildAiPrefillCard(),
                    const SizedBox(height: 4),
                  ],

                  const _SectionTitle(title: 'Chọn Gói Dịch Vụ'),
                  _buildServicePackages(),
                  const SizedBox(height: 20),

                  const _SectionTitle(title: 'Chọn Ngày'),
                  _buildCalendar(),
                  const SizedBox(height: 20),

                  const _SectionTitle(title: 'Chọn Khung Giờ'),
                  _buildTimeSlots(),
                  const SizedBox(height: 20),

                  const _SectionTitle(title: 'Chọn Thú Cưng Của Bạn'),
                  _buildPetSelection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildBottomBookButton(),
          ),
        ],
      ),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PetAiSelectionScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          } else if (index == 3) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
              (route) => false,
            );
          } else if (index == 4) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  bool get _hasAiPrefill =>
      widget.petId != null ||
      (widget.prefillKeyword?.trim().isNotEmpty ?? false) ||
      (widget.serviceType?.trim().isNotEmpty ?? false) ||
      (widget.preferredDateText?.trim().isNotEmpty ?? false);

  Widget _buildServiceLanding(BuildContext context) {
    final service = widget.service!;
    final shopName = service.shopName?.trim() ?? 'Thông tin shop';
    final shopAddress = service.shopAddress?.trim();
    final distanceText = service.distanceKm != null
        ? '${service.distanceKm!.toStringAsFixed(1)} km'
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
                    icon: const Icon(LucideIcons.mapPin, size: 18),
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
                    Text(
                      PriceFormatter.formatVnd(service.basePrice ?? 0),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFE11D48),
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
                final selectedItems = List<CartItem>.from(appState.selectedCartItems);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(selectedItems: selectedItems),
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

  Widget _buildAiPrefillCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                'Gợi ý từ PetPee AI',
                style: GoogleFonts.inter(
                  color: const Color(0xFF2E251F),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.petId != null)
            _buildPrefillLine('Thú cưng', 'ID ${widget.petId}'),
          if (widget.prefillKeyword?.trim().isNotEmpty ?? false)
            _buildPrefillLine('Từ khóa', widget.prefillKeyword!.trim()),
          if (widget.serviceType?.trim().isNotEmpty ?? false)
            _buildPrefillLine('Nhóm dịch vụ', widget.serviceType!.trim()),
          if (widget.preferredDateText?.trim().isNotEmpty ?? false)
            _buildPrefillLine(
              'Thời gian gợi ý',
              widget.preferredDateText!.trim(),
            ),
        ],
      ),
    );
  }

  Widget _buildPrefillLine(String label, String value) {
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

  Widget _buildServicePackages() {
    final packages = [
      {
        'icon': LucideIcons.scissors,
        'name': 'Cắt tỉa lông',
        'price': '\$45 | 90m',
      },
      {'icon': LucideIcons.bath, 'name': 'Tắm & Sấy', 'price': '\$30 | 45m'},
      {
        'icon': LucideIcons.mousePointer2,
        'name': 'Cắt móng',
        'price': '\$20 | 30m',
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(packages.length, (index) {
          bool isSelected = _selectedPackage == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedPackage = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 105,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFF0F3) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFB7185)
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    packages[index]['icon'] as IconData,
                    color: Colors.black87,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    packages[index]['name'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    packages[index]['price'] as String,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCalendar() {
    final daysOfWeek = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

    // Tính toán số ngày trong tháng và ngày bắt đầu
    int daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    int firstWeekday = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    ).weekday;
    // Dart's weekday: 1 = Monday, 7 = Sunday. We want Sunday = 0, Monday = 1,...
    int emptySlots = firstWeekday == 7 ? 0 : firstWeekday;

    String monthName = 'Tháng ${_currentMonth.month} ${_currentMonth.year}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.black54),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month - 1,
                      1,
                    );
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                monthName,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.black54),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1,
                      1,
                    );
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysOfWeek
                .map(
                  (day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: daysInMonth + emptySlots,
            itemBuilder: (context, index) {
              if (index < emptySlots) {
                return const SizedBox.shrink(); // Ô trống
              }
              int dayNumber = index - emptySlots + 1;
              DateTime date = DateTime(
                _currentMonth.year,
                _currentMonth.month,
                dayNumber,
              );

              bool isSelected =
                  _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;

              bool isToday =
                  DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;

              return Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE91E63)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday && !isSelected
                          ? Border.all(color: const Color(0xFFE91E63), width: 1)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      dayNumber.toString(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots() {
    final times = ['10:00 AM', '11:30 AM', '1:00 PM', '3:30 PM'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(times.length, (index) {
          bool isSelected = _selectedTime == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedTime = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE91E63) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFE91E63)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                times[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPetSelection() {
    final appState = context.watch<AppState>();
    final pets = appState.myPets;

    if (appState.isLoadingPets && pets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (pets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPetScreen(),
                    ),
                  );
                  if (result == true && mounted) {
                    await context.read<AppState>().loadMyPets();
                  }
                },
                icon: const Icon(LucideIcons.plus, size: 18),
                label: const Text('Thêm thú cưng'),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(pets.length, (index) {
                final pet = pets[index];
                final isSelected = _selectedPetId == pet.id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPetId = pet.id),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFE91E63)
                                  : Colors.transparent,
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(
                                pet.avatarUrl ?? 'https://picsum.photos/seed/pet${pet.id ?? index}/200',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pet.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color(0xFFE91E63)
                                : Colors.black87,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddPetScreen(),
                  ),
                );
                if (result == true && mounted) {
                  await context.read<AppState>().loadMyPets();
                }
              },
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Thêm thú cưng'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBookButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE91E63),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: () {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          if (authProvider.currentUser == null) {
            _showAuthDialog(context);
          } else if (widget.service != null) {
            final appState = context.read<AppState>();
            appState.prepareBuyNowService(widget.service!);
            final selectedItems = List<CartItem>.from(appState.selectedCartItems);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutScreen(selectedItems: selectedItems),
              ),
            );
          } else {
            final appState = context.read<AppState>();
            final selectedPetIndex = appState.myPets.indexWhere(
              (pet) => pet.id == _selectedPetId,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SpaBookingConfirmationScreen(
                  selectedPackage: _selectedPackage,
                  selectedTime: _selectedTime,
                  selectedPet: selectedPetIndex >= 0 ? selectedPetIndex : 0,
                  selectedDate: _selectedDate,
                ),
              ),
            );
          }
        },
        child: const Text(
          'Đặt Lịch Ngay',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showAuthDialog(BuildContext context) {
    showLoginRequiredSheet(context);
  }

  Widget _buildShopLocation() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: NetworkImage('https://picsum.photos/seed/shop1/100'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sunny Spa - CS1',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.mapPin,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    const Expanded(
                      child: Text(
                        '123 Đường Cầu Giấy, Q. Cầu Giấy, Hà Nội',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.navigation,
                      size: 12,
                      color: Colors.pink,
                    ),
                    const SizedBox(width: 4),
                    const Text(
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.pink.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.map, color: Colors.pink, size: 20),
          ),
        ],
      ),
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
