import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/apps/home/page/map_screen.dart';
import 'package:petpee_mobile/features/chat/screens/chat_list_screen.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/apps/search/page/search_screen.dart';
import 'package:petpee_mobile/common/component/common_bottom_nav.dart';
import 'package:petpee_mobile/common/component/product_card.dart';
import 'package:petpee_mobile/common/component/service_card.dart';
import 'package:petpee_mobile/common/navigation/main_tab_navigation.dart';
import 'package:petpee_mobile/common/store/app_state.dart';
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
          const SliverToBoxAdapter(child: _BenefitSection()),
          const SliverToBoxAdapter(child: _PromoTicker()),
          const SliverToBoxAdapter(child: _QuickShortcutGrid()),
          const SliverToBoxAdapter(child: _ServiceSection()),
          const SliverToBoxAdapter(child: _VeterinarySection()),
          const SliverToBoxAdapter(child: _FeedHeader()),
          Consumer<AppState>(
            builder: (context, state, child) {
              if (state.productsError != null &&
                  state.allProducts.length == 0) {
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

              if (state.allProducts.length == 0) {
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
      floatingActionButton: const _FloatingGiftButton(),
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
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MapScreen()),
                  );
                },
                child: const _TopIcon(icon: LucideIcons.map, badge: null),
              ),
              const SizedBox(width: 8),
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
                  icon: LucideIcons.messageCircle,
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
                  icon: Icon(LucideIcons.logIn, size: 16),
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

class _BenefitSection extends StatelessWidget {
  const _BenefitSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _homeHeaderBackground,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: const _BenefitBar(),
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

class _BenefitBar extends StatelessWidget {
  const _BenefitBar();

  @override
  Widget build(BuildContext context) {
    final items = [
      (LucideIcons.wallet, 'Ví PetPee', 'Giảm 90.000đ cho đơn đầu'),
      (LucideIcons.coins, 'Điểm danh', 'Nhận xu thưởng mỗi ngày'),
      (LucideIcons.badgePercent, 'Trả sau', 'Mở ưu đãi voucher 150.000đ'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          item.$1,
                          color: const Color(0xFFFF5F57),
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF384252),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              item.$3,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF8B98A7),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
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
            )
            .toList(),
      ),
    );
  }
}

class _PromoTicker extends StatelessWidget {
  const _PromoTicker();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _homeHeaderBackground,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _PromoCard(
                  title: 'Tự do sắm đồ cho boss',
                  subtitle: 'Giảm đến 50% cho khách mới',
                  color: Color(0xFFFFF1E8),
                ),
                SizedBox(width: 10),
                _PromoCard(
                  title: 'Spa tại nhà 0đ ship',
                  subtitle: 'Đặt lịch nhanh trong 30 giây',
                  color: Color(0xFFFFF6DA),
                ),
                SizedBox(width: 10),
                _PromoCard(
                  title: 'Deal thú y cuối tuần',
                  subtitle: 'Voucher tiêm phòng và khám tổng quát',
                  color: Color(0xFFE9F7FF),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 18,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 268,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF2E3440),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF697586),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.badgeDollarSign,
              color: Color(0xFFFF6B57),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickShortcutGrid extends StatelessWidget {
  const _QuickShortcutGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      (LucideIcons.utensilsCrossed, 'Pet Food'),
      (LucideIcons.crown, 'VIP'),
      (LucideIcons.badgeDollarSign, 'Deal 1.000d'),
      (LucideIcons.ticket, 'Xử lý đơn'),
      (LucideIcons.gift, 'Voucher'),
    ];

    return Container(
      color: _homeHeaderBackground,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items
            .map(
              (item) => SizedBox(
                width: 68,
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF76C6E8,
                            ).withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        item.$1,
                        color: const Color(0xFFFF5A4E),
                        size: 21,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF334155),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
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

class _ServiceSection extends StatelessWidget {
  const _ServiceSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _homeContentBackground,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  'Dịch vụ spa nổi bật gần bạn',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Consumer<AppState>(
            builder: (context, state, child) {
              final services = state.allServices;

              if (state.isLoadingServices && services.length == 0) {
                return const SizedBox(
                  height: 188,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (state.servicesError != null && services.length == 0) {
                return SizedBox(
                  height: 188,
                  child: Center(
                    child: Text(
                      state.servicesError ?? 'Lỗi tải dịch vụ',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (services.length == 0) {
                return const SizedBox(
                  height: 188,
                  child: Center(child: Text('Chưa có dịch vụ nào')),
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
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  'Dịch vụ thú y gần bạn',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1F2937),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Consumer<AppState>(
            builder: (context, state, child) {
              try {
                final vetList = state.veterinaryServices;

                if (state.isLoadingVeterinary && vetList.length == 0) {
                  return const SizedBox(
                    height: 188,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state.veterinaryError != null && vetList.length == 0) {
                  return SizedBox(
                    height: 188,
                    child: Center(
                      child: Text(
                        state.veterinaryError ?? 'Lỗi tải dịch vụ thú y',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (vetList.length == 0) {
                  return const SizedBox(
                    height: 188,
                    child: Center(child: Text('Chưa có dịch vụ thú y')),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    const horizontalPadding = 12.0;
                    const itemGap = 12.0;
                    final availableWidth =
                        constraints.maxWidth -
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

class _FloatingGiftButton extends StatelessWidget {
  const _FloatingGiftButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFC54D), Color(0xFFFF8A34)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9A3D).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Center(
            child: Icon(LucideIcons.gift, color: Colors.white, size: 28),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFFFF314D),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '1',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
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
