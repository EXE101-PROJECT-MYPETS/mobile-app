import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pawly_mobile/apps/product/api/product_service.dart';
import 'package:pawly_mobile/apps/product/page/product_detail_screen.dart';
import 'package:pawly_mobile/apps/service/api/service_service.dart';
import 'package:pawly_mobile/common/component/service_card.dart';
import 'package:pawly_mobile/common/user/dto/product_dto.dart';
import 'package:pawly_mobile/common/user/dto/service_public_dto.dart';
import 'package:pawly_mobile/common/utils/category_badge_style.dart';
import 'package:pawly_mobile/common/utils/price_formatter.dart';
import 'package:pawly_mobile/features/chat/screens/chat_detail_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  const ShopDetailScreen({
    super.key,
    this.shopId,
    this.shopName,
    this.shopAvatarUrl,
  });

  final int? shopId;
  final String? shopName;
  final String? shopAvatarUrl;

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  final ServicePublicService _servicePublicService = ServicePublicService();
  final ProductService _productService = ProductService();

  Future<List<ServicePublicDTO>>? _servicesFuture;
  Future<List<ProductDTO>>? _productsFuture;

  int get _effectiveShopId => widget.shopId ?? 1;

  String get _effectiveShopName {
    final value = widget.shopName?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return 'Cửa hàng';
  }

  String get _effectiveShopAvatarUrl {
    final value = widget.shopAvatarUrl?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return 'https://picsum.photos/seed/shop-avatar-v2/200/200';
  }

  @override
  void initState() {
    super.initState();
    _ensureFutures();
  }

  void _ensureFutures() {
    _servicesFuture ??= _loadShopServices();
    _productsFuture ??= _loadShopProducts();
  }

  Future<List<ServicePublicDTO>> _loadShopServices() async {
    final response = await _servicePublicService.getAllForScroll(
      shopId: _effectiveShopId,
      size: 10,
    );
    return response.content;
  }

  Future<List<ProductDTO>> _loadShopProducts() async {
    final response = await _productService.getAllMobile(
      shopId: _effectiveShopId,
      size: 10,
    );
    return response.content;
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          conversationId: 'temp_$_effectiveShopId',
          shopId: _effectiveShopId.toString(),
          shopName: _effectiveShopName,
          shopAvatarUrl: _effectiveShopAvatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensureFutures();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FA),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ShopHeroHeader(
              shopName: _effectiveShopName,
              shopAvatarUrl: _effectiveShopAvatarUrl,
              onBack: () => Navigator.pop(context),
              onChat: _openChat,
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -6),
              child: Column(
                children: [
                  const _ShopTabBar(),
                  const SizedBox(height: 8),
                  _ServiceSection(servicesFuture: _servicesFuture!),
                  _ProductSection(productsFuture: _productsFuture!),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShopHeroHeader extends StatelessWidget {
  const _ShopHeroHeader({
    required this.shopName,
    required this.shopAvatarUrl,
    required this.onBack,
    required this.onChat,
  });

  final String shopName;
  final String shopAvatarUrl;
  final VoidCallback onBack;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 186,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4A4B97),
                  Color(0xFF7251D6),
                  Color(0xFFF09BB3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Image.network(
            'https://picsum.photos/seed/shop-header-market/1200/700',
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.24),
            colorBlendMode: BlendMode.darken,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.10),
                  Colors.black.withValues(alpha: 0.22),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _HeaderIconButton(
                        icon: LucideIcons.arrow_left,
                        onTap: onBack,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 10),
                              Icon(
                                LucideIcons.search,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tìm kiếm sản phẩm trong Shop',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withValues(alpha: 0.76),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          image: DecorationImage(
                            image: NetworkImage(shopAvatarUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      shopName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    LucideIcons.chevron_right,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '4.5',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Icon(
                                    LucideIcons.star,
                                    size: 12,
                                    color: Color(0xFFFFC857),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _OutlineHeroButton(
                        icon: LucideIcons.message_circle,
                        label: 'Chat',
                        onTap: onChat,
                      ),
                    ],
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: Colors.white, size: 17),
      ),
    );
  }
}

class _OutlineHeroButton extends StatelessWidget {
  const _OutlineHeroButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 98,
      height: 30,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 13),
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.88)),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
    );
  }
}

class _ShopTabBar extends StatelessWidget {
  const _ShopTabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        children: [
          _TabItem(label: 'Shop', active: true),
          _TabItem(label: 'Sản phẩm', badge: 'New'),
          _TabItem(label: 'Danh mục hàng'),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, this.active = false, this.badge});

  final String label;
  final bool active;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active
                        ? const Color(0xFFFF5A4E)
                        : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: active ? 64 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5A4E),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 4,
                right: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5A4E),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
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

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.title,
    required this.actionLabel,
    required this.child,
  });

  final String title;
  final String actionLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1E293B),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  actionLabel,
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFF5A4E),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  LucideIcons.chevron_right,
                  size: 14,
                  color: Color(0xFFFF5A4E),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ServiceSection extends StatelessWidget {
  const _ServiceSection({required this.servicesFuture});

  final Future<List<ServicePublicDTO>> servicesFuture;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: 'Dịch vụ',
      actionLabel: 'Xem thêm',
      child: FutureBuilder<List<ServicePublicDTO>>(
        future: servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 282,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Không thể tải dịch vụ',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFEF4444),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          final services = snapshot.data ?? const <ServicePublicDTO>[];
          if (services.isEmpty) {
            return SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Chưa có dịch vụ nào',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          return SizedBox(
            height: 282,
            child: _HorizontalDragList(
              padding: const EdgeInsets.only(right: 8),
              itemCount: services.length,
              separatorWidth: 12,
              itemBuilder: (context, index) {
                return ServiceCard(
                  service: services[index],
                  showLocation: false,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({required this.productsFuture});

  final Future<List<ProductDTO>> productsFuture;

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      title: 'Sản phẩm',
      actionLabel: 'Xem thêm',
      child: FutureBuilder<List<ProductDTO>>(
        future: productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 328,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Không thể tải sản phẩm',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFEF4444),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          final products = snapshot.data ?? const <ProductDTO>[];
          if (products.isEmpty) {
            return SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Chưa có sản phẩm nào',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          return SizedBox(
            height: 328,
            child: _HorizontalDragList(
              padding: const EdgeInsets.only(right: 8),
              itemCount: products.length,
              separatorWidth: 12,
              itemBuilder: (context, index) {
                return SizedBox(
                  width: 200,
                  child: _MarketplaceProductCard(product: products[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _HorizontalDragList extends StatelessWidget {
  const _HorizontalDragList({
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorWidth,
    this.padding = EdgeInsets.zero,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double separatorWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
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
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (context, index) => SizedBox(width: separatorWidth),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

class _MarketplaceProductCard extends StatelessWidget {
  const _MarketplaceProductCard({required this.product});

  final ProductDTO product;

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        product.imageUrls?.isNotEmpty == true ? product.imageUrls!.first : null;

    final displayName = product.name?.trim().isNotEmpty == true
        ? product.name!.trim()
        : 'Sản phẩm';

    final categoryLabel = product.categoryName?.trim().isNotEmpty == true
        ? product.categoryName!.trim()
        : null;

    final unitLabel =
        product.unit?.trim().isNotEmpty == true ? product.unit!.trim() : null;

    final ratingValue = product.rating ?? product.reviewAvg ?? 0;
    final reviewLabel =
        '${product.totalReviews ?? product.reviewCount ?? 0} đánh giá';

    return GestureDetector(
      onTap: () {
        final productId = product.id;
        if (productId == null) {
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ProductDetailScreen(productId: productId.toString()),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EDF7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null)
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const _ProductImageFallback(),
                      )
                    else
                      const _ProductImageFallback(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (categoryLabel != null) ...[
                      _ProductChip(label: categoryLabel),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF334155),
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        Text(
                          PriceFormatter.formatVnd(product.price ?? 0),
                          style: GoogleFonts.inter(
                            color: const Color(0xFFF45A45),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (unitLabel != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              unitLabel,
                              style: GoogleFonts.inter(
                                color: const Color(0xFFFF5A4E),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.star,
                          size: 11,
                          color: Color(0xFFFFC857),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          ratingValue.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF475569),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            reviewLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductChip extends StatelessWidget {
  const _ProductChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final badgeStyle = resolveCategoryBadgeStyle(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: badgeStyle.backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: badgeStyle.textColor,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
      child: Center(
        child: Icon(LucideIcons.image, size: 36, color: Color(0xFF94A3B8)),
      ),
    );
  }
}
