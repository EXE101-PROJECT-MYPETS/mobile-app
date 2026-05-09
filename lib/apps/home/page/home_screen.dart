import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/apps/home/page/notifications_screen.dart';
import 'package:petpee_mobile/apps/product/page/product_list_screen.dart';
import 'package:petpee_mobile/apps/product/page/spa_service_screen.dart';
import 'package:petpee_mobile/apps/profile/page/profile_screen.dart';
import 'package:petpee_mobile/common/component/common_bottom_nav.dart';
import 'package:petpee_mobile/common/component/product_card.dart';
import 'package:petpee_mobile/common/store/app_state.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(_onScroll);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFF),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          const SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            floating: false,
            snap: false,
            elevation: 0,
            backgroundColor: Color(0xFFC9F0FF),
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 66,
            titleSpacing: 0,
            title: _StickySearchHeader(),
          ),
          const SliverToBoxAdapter(child: _BenefitSection()),
          const SliverToBoxAdapter(child: _PromoTicker()),
          const SliverToBoxAdapter(child: _QuickShortcutGrid()),
          SliverToBoxAdapter(
            child: Consumer<AppState>(
              builder: (context, state, child) {
                if (state.isLoadingProducts && state.allProducts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state.productsError != null && state.allProducts.isEmpty) {
                  return Padding(
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
                  );
                }

                final featured = state.similarProducts.isNotEmpty
                    ? state.similarProducts
                    : state.allProducts.take(1).toList();

                return _FeatureTiles(products: featured);
              },
            ),
          ),
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
                    child: Center(
                      child: Text('Không có sản phẩm nào'),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ProductCard(product: state.allProducts[index]),
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
        onTap: (index) {
          if (index == 1) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const ProductListScreen()),
              (route) => false,
            );
          } else if (index == 2) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SpaServiceScreen()),
              (route) => false,
            );
          } else if (index == 3) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
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
}

class _StickySearchHeader extends StatelessWidget {
  const _StickySearchHeader();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Row(
          children: [
            Expanded(
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
            const SizedBox(width: 10),
            const _TopIcon(icon: LucideIcons.bell, badge: '36'),
            const SizedBox(width: 8),
            const _TopIcon(icon: LucideIcons.messageCircle, badge: '27'),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC9F0FF), Color(0xFFEAFBFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: const _BenefitBar(),
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon, required this.badge});

  final IconData icon;
  final String badge;

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
              badge,
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
                        child: Icon(item.$1, color: const Color(0xFFFF5F57), size: 15),
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
      color: const Color(0xFFD5F4FF),
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
      color: const Color(0xFFD5F4FF),
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
                            color: const Color(0xFF76C6E8).withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(item.$1, color: const Color(0xFFFF5A4E), size: 21),
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

class _FeatureTiles extends StatelessWidget {
  const _FeatureTiles({required this.products});

  final List<dynamic> products;

  @override
  Widget build(BuildContext context) {
    final firstProduct = products.isNotEmpty ? products.first : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              height: 210,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF0F0), Color(0xFFFFD5E2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'FREESHIP 0Đ',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFF5A3D),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                      'Combo hot cho boss',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFEF4444),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                      'Gói chăm sóc, đồ chơi và phụ kiện đang được đặt nhiều nhất hôm nay.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF7C4A57),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 210,
              child: firstProduct != null
                  ? ProductCard(product: firstProduct)
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      child: Row(
        children: [
          Text(
            'Dành cho bạn',
            style: GoogleFonts.inter(
              color: const Color(0xFF1F2937),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            'Xem thêm',
            style: GoogleFonts.inter(
              color: const Color(0xFFFF5A4E),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
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

