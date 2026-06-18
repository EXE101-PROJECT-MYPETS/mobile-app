import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pawly_mobile/apps/home/page/map_screen.dart';
import 'package:pawly_mobile/apps/product/page/spa_service_screen.dart';
import 'package:pawly_mobile/features/chat/screens/chat_list_screen.dart';
import 'package:pawly_mobile/common/auth/store/auth_provider.dart';
import 'package:pawly_mobile/apps/search/page/search_screen.dart';
import 'package:pawly_mobile/common/component/common_bottom_nav.dart';
import 'package:pawly_mobile/common/component/product_card.dart';
import 'package:pawly_mobile/common/component/service_card.dart';
import 'package:pawly_mobile/common/navigation/main_tab_navigation.dart';
import 'package:pawly_mobile/common/store/app_state.dart';
import 'package:provider/provider.dart';

const Color _homeHeaderBackground = Color(0xFFD5F4FF);
const Color _homeContentBackground = Color(0xFFD5F4FF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _scrollController;
  bool _requestedServiceLocation = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNearbyServices();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= maxScroll - 200) {
      final appState = context.read<AppState>();
      if (!appState.isLoadingProducts && appState.hasMoreProducts) {
        appState.loadMoreProducts();
      }
    }
  }

  Future<void> _loadNearbyServices() async {
    if (_requestedServiceLocation || !mounted) return;
    _requestedServiceLocation = true;

    final appState = context.read<AppState>();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // On some platforms (especially web), isLocationServiceEnabled may be unreliable.
        // Continue to request the current position instead of falling back immediately.
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await appState.loadServices();
        await appState.loadVeterinaryServices();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await appState.loadServices(
        lat: position.latitude,
        lng: position.longitude,
        radiusKm: appState.serviceRadiusKm,
      );
      await appState.loadVeterinaryServices(
        lat: position.latitude,
        lng: position.longitude,
        radiusKm: appState.serviceRadiusKm,
        perShopLimit: 5,
        size: 20,
      );
    } catch (_) {
      await appState.loadServices();
      await appState.loadVeterinaryServices();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _homeContentBackground,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            floating: false,
            snap: false,
            elevation: 0,
            backgroundColor: _homeHeaderBackground,
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 66,
            titleSpacing: 0,
            title: _StickySearchHeader(),
          ),
          const SliverToBoxAdapter(child: _HeroSection()),
          const SliverToBoxAdapter(child: _QuickUtilitySection()),
          const SliverToBoxAdapter(child: _VaccinationReminderSection()),
          const SliverToBoxAdapter(child: _ServiceSection()),
          const SliverToBoxAdapter(child: _VeterinarySection()),
          const SliverToBoxAdapter(child: _FeedHeader()),
          Consumer<AppState>(
            builder: (context, state, child) {
              if (state.productsError != null && state.allProducts.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          state.productsError!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => state.loadProducts(),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state.allProducts.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('Không có sản phẩm nào')),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        ProductCard(product: state.allProducts[index]),
                    childCount: state.allProducts.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.66,
                  ),
                ),
              );
            },
          ),
          Consumer<AppState>(
            builder: (context, state, child) {
              if (state.isLoadingProducts && state.allProducts.isNotEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
          ),
        ],
      ),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 0,
        onTap: (index) =>
            MainTabNavigation.open(context, index, currentIndex: 0),
      ),
    );
  }
}

class _StickySearchHeader extends StatelessWidget {
  const _StickySearchHeader();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.token?.isNotEmpty ?? false;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF76C6E8).withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(
                        LucideIcons.search,
                        color: Color(0xFF9CA3AF),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Khăn lau, pate, cát vệ sinh...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFB6B77),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Color(0xFFF0F3F6)),
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          color: Color(0xFF6B7280),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (isLoggedIn) ...[
              const _TopIcon(icon: LucideIcons.bell, badge: '36'),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatListScreen(),
                    ),
                  );
                },
                child: const _TopIcon(
                  icon: LucideIcons.message_circle,
                  badge: '27',
                ),
              ),
            ] else ...[
              const SizedBox(width: 10),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  icon: const Icon(LucideIcons.log_in, size: 16),
                  label: const Text(
                    'Đăng nhập',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4F8B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _homeHeaderBackground,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageWidth = (constraints.maxWidth * 0.4).clamp(122.0, 168.0);

          return Container(
            constraints: const BoxConstraints(minHeight: 166),
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 0),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F8FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF78C8E8).withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hôm nay boss cần gì?',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1F2A44),
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            height: 1.16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tìm spa, thú y và cửa hàng thú cưng gần bạn',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF667085),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _HeroActionButton(
                          label: 'Tìm gần tôi',
                          icon: LucideIcons.map_pin,
                          backgroundColor: const Color(0xFFFF4F8B),
                          foregroundColor: Colors.white,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MapScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _HeroActionButton(
                          label: 'Đặt lịch nhanh',
                          icon: LucideIcons.activity,
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFFF4F8B),
                          borderColor: const Color(0xFFFFB6C9),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SpaServiceScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: imageWidth,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 16,
                        right: imageWidth * 0.28,
                        child: Icon(
                          Icons.favorite,
                          color: const Color(
                            0xFFFF6F9F,
                          ).withValues(alpha: 0.72),
                          size: 18,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 0,
                        child: Icon(
                          Icons.pets,
                          color: Colors.white.withValues(alpha: 0.56),
                          size: 30,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Image.asset(
                          'assets/pet_dog_cat_illustration.png',
                          width: imageWidth,
                          height: 146,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
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

class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon, required this.badge});

  final IconData icon;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF8AA0AE), size: 18),
        ),
        if (badge != null)
          Positioned(
            top: -5,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFFF9CB2)),
              ),
              child: Text(
                badge!,
                style: GoogleFonts.inter(
                  color: const Color(0xFFFF586D),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.borderColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 36,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border:
                  borderColor == null ? null : Border.all(color: borderColor!),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foregroundColor, size: 15),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: foregroundColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickUtilitySection extends StatelessWidget {
  const _QuickUtilitySection();

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        icon: LucideIcons.bath,
        title: 'Spa và grooming',
        subtitle: 'Tắm, cắt tỉa, vệ sinh',
        color: const Color(0xFFFF4F8B),
        background: const Color(0xFFFFF0F6),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SpaServiceScreen()),
          );
        },
      ),
      (
        icon: LucideIcons.stethoscope,
        title: 'Thú y',
        subtitle: 'Khám bệnh, tiêm phòng',
        color: const Color(0xFF4AA6FF),
        background: const Color(0xFFEFF7FF),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapScreen()),
          );
        },
      ),
      (
        icon: LucideIcons.shopping_bag,
        title: 'Pet Shop',
        subtitle: 'Thức ăn, phụ kiện',
        color: const Color(0xFF34C77B),
        background: const Color(0xFFEFFBF5),
        onTap: () {
          Navigator.pushNamed(context, '/products');
        },
      ),
      (
        icon: LucideIcons.calendar_days,
        title: 'Lịch của boss',
        subtitle: 'Quản lý lịch chăm sóc',
        color: const Color(0xFF8D6BFF),
        background: const Color(0xFFF4F0FF),
        onTap: () {
          Navigator.pushNamed(context, '/pets');
        },
      ),
    ];

    return Container(
      color: _homeHeaderBackground,
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Text(
              'Tiện ích nhanh',
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _QuickUtilityTile(item: items[0])),
              const SizedBox(width: 8),
              Expanded(child: _QuickUtilityTile(item: items[1])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _QuickUtilityTile(item: items[2])),
              const SizedBox(width: 8),
              Expanded(child: _QuickUtilityTile(item: items[3])),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickUtilityTile extends StatelessWidget {
  const _QuickUtilityTile({required this.item});

  final ({
    IconData icon,
    String title,
    String subtitle,
    Color color,
    Color background,
    VoidCallback onTap,
  }) item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7EC8E8).withValues(alpha: 0.1),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF263244),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7A8796),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderActionButton extends StatelessWidget {
  const _ReminderActionButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF746E),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          'Xem lịch chăm sóc',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _ReminderPetAvatar extends StatelessWidget {
  const _ReminderPetAvatar();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 74,
          height: 74,
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/pet_dog_cat_illustration.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
        Positioned(
          right: -1,
          bottom: 4,
          child: Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              LucideIcons.bell,
              size: 13,
              color: Color(0xFFFF4F8B),
            ),
          ),
        ),
      ],
    );
  }
}

class _VaccinationReminderSection extends StatelessWidget {
  const _VaccinationReminderSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _homeHeaderBackground,
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF4DD), Color(0xFFE9F8FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8ECDE7).withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const _ReminderPetAvatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nhắc lịch cho boss',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1F2937),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Milo sắp đến lịch tiêm phòng',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF697586),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        size: 13,
                        color: Color(0xFF8B98A7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Ngày dự kiến: 25/06/2026',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF7A8796),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  _ReminderActionButton(
                    onTap: () => Navigator.pushNamed(context, '/pets'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 58,
              height: 74,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 4,
                    left: 2,
                    child: Container(
                      width: 34,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F4FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        LucideIcons.cross,
                        color: Color(0xFF4AA6FF),
                        size: 18,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 4,
                    child: Transform.rotate(
                      angle: 0.36,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.syringe,
                          color: Color(0xFF3A9DF5),
                          size: 28,
                        ),
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

class _FeedHeader extends StatelessWidget {
  const _FeedHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _homeContentBackground,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        children: [
          Text(
            'Các sản phẩm dành cho bạn',
            style: GoogleFonts.inter(
              color: const Color(0xFF1F2937),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          InkWell(
            onTap: onViewAll,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Xem tất cả',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF3A9DF5),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    LucideIcons.chevron_right,
                    color: Color(0xFF3A9DF5),
                    size: 13,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceStateCard extends StatelessWidget {
  const _ServiceStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFE11D48) : const Color(0xFFB6DDF2);

    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7EC8E8).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: isError ? color : const Color(0xFF5A6573),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF98A4B3),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
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

class _ServiceSection extends StatelessWidget {
  const _ServiceSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _homeContentBackground,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Dịch vụ spa nổi bật gần bạn',
            onViewAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SpaServiceScreen(),
                ),
              );
            },
          ),
          Consumer<AppState>(
            builder: (context, state, child) {
              final services = state.allServices;

              if (state.isLoadingServices && services.isEmpty) {
                return const SizedBox(
                  height: 188,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state.servicesError != null && services.isEmpty) {
                return _ServiceStateCard(
                  icon: LucideIcons.circle_alert,
                  title: 'Không tải được dịch vụ',
                  subtitle: state.servicesError ?? 'Vui lòng thử lại sau.',
                  isError: true,
                );
              }

              if (services.isEmpty) {
                return const _ServiceStateCard(
                  icon: LucideIcons.store,
                  title: 'Chưa có dịch vụ nào',
                  subtitle: 'Các spa uy tín sẽ hiển thị tại đây',
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  const horizontalPadding = 12.0;
                  const itemGap = 12.0;
                  final availableWidth =
                      constraints.maxWidth - (horizontalPadding * 2) - itemGap;
                  final itemWidth = (availableWidth / 2).clamp(194.0, 204.0);

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
                        padding: const EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
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
              );
            },
          ),
        ],
      ),
    );
  }
}

class _VeterinarySection extends StatelessWidget {
  const _VeterinarySection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _homeContentBackground,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Dịch vụ thú y gần bạn',
            onViewAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              );
            },
          ),
          Consumer<AppState>(
            builder: (context, state, child) {
              try {
                final vetList = state.veterinaryServices;

                if (state.isLoadingVeterinary && vetList.isEmpty) {
                  return const SizedBox(
                    height: 188,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state.veterinaryError != null && vetList.isEmpty) {
                  return _ServiceStateCard(
                    icon: LucideIcons.circle_alert,
                    title: 'Không tải được dịch vụ thú y',
                    subtitle: state.veterinaryError ?? 'Vui lòng thử lại sau.',
                    isError: true,
                  );
                }

                if (vetList.isEmpty) {
                  return const _ServiceStateCard(
                    icon: LucideIcons.building_2,
                    title: 'Chưa có dịch vụ nào',
                    subtitle: 'Các phòng khám uy tín sẽ hiển thị tại đây',
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    const horizontalPadding = 12.0;
                    const itemGap = 12.0;
                    final availableWidth = constraints.maxWidth -
                        (horizontalPadding * 2) -
                        itemGap;
                    final itemWidth = (availableWidth / 2).clamp(194.0, 204.0);

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
                          padding: const EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          itemCount: vetList.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: itemGap),
                          itemBuilder: (context, index) {
                            return ServiceCard(
                              service: vetList[index],
                              width: itemWidth,
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              } catch (e, st) {
                // Show error details in UI to help debugging on web
                return SizedBox(
                  height: 220,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Text(
                          'Lỗi khi render dịch vụ thú y:\n$e\n\n${st.toString()}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
