import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:petpee_mobile/common/component/login_required_sheet.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:petpee_mobile/apps/checkout/page/checkout_screen.dart';
import 'package:petpee_mobile/apps/product/model/product_model.dart';
import 'package:petpee_mobile/common/component/product_card.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/common/store/app_state.dart';
import 'package:petpee_mobile/apps/shop/page/shop_detail_screen.dart';
import 'package:petpee_mobile/common/toast/app_toast.dart';
import 'package:petpee_mobile/features/chat/screens/chat_detail_screen.dart';
import 'package:petpee_mobile/apps/product/api/product_service.dart';
import 'package:petpee_mobile/common/user/dto/product_public_detail_dto.dart';
import 'package:petpee_mobile/common/user/dto/product_public_review_dto.dart';
import 'package:petpee_mobile/common/user/dto/shop_public_dto.dart';

class ProductDetailScreen extends StatefulWidget {
  final String? productId;
  const ProductDetailScreen({super.key, this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  static const int _reviewPreviewLimit = 5;
  final PageController _pageController = PageController();
  late Future<ProductDetailPageData> _pageDataFuture;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageDataFuture = _loadPageData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<ProductDetailPageData> _loadPageData() async {
    final productId = widget.productId;
    if (productId == null) {
      throw Exception('Product ID is required');
    }

    final detail = await _productService.getProductDetail(productId);
    final related = await _productService.getProductRelated(
      productId,
      size: 10,
    );
    final reviews = await _productService.getProductReviews(productId, size: 4);
    final shop = detail.shopId != null
        ? await _productService.getShopDetail(detail.shopId!)
        : null;

    final relatedProducts = related
        .map((dto) => ProductModel.fromDTO(dto))
        .toList();

    return ProductDetailPageData(
      detail: detail,
      shop: shop,
      relatedProducts: relatedProducts,
      topReviews: reviews,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: widget.productId == null
          ? _buildEmptyState()
          : FutureBuilder<ProductDetailPageData>(
              future: _pageDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _buildError(snapshot.error.toString());
                }
                final data = snapshot.requireData;
                // Log product viewed to recently viewed after frame is built
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _logProductViewed(data.detail);
                });
                return _buildContent(data);
              },
            ),
      bottomNavigationBar: FutureBuilder<ProductDetailPageData>(
        future: _pageDataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          return _buildBottomBar(snapshot.data!.detail, snapshot.data!.shop);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('Không có sản phẩm để hiển thị.'));
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lỗi khi tải sản phẩm',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  setState(() => _pageDataFuture = _loadPageData()),
              child: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ProductDetailPageData data) {
    final detail = data.detail;
    final shop = data.shop;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageCarousel(detail),
          _buildMainInfoSection(detail),
          _buildSectionDivider(),
          _buildShopSection(detail, shop),
          _buildSectionDivider(),
          _buildReviewSection(detail, data.topReviews),
          _buildSectionDivider(),
          _buildRelatedSection(data.relatedProducts),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMainInfoSection(ProductPublicDetailDTO detail) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadgeSection(detail.badgeLabels),
          const SizedBox(height: 10),
          Text(
            detail.name ?? 'Sản phẩm',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceSection(detail),
          const SizedBox(height: 16),
          _buildRatingRow(detail),
        ],
      ),
    );
  }

  Widget _buildShopSection(ProductPublicDetailDTO detail, ShopPublicDTO? shop) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(children: [_buildShopCard(detail, shop)]),
    );
  }

  Widget _buildReviewSection(
    ProductPublicDetailDTO detail,
    List<ProductPublicReviewDTO> reviews,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Đánh giá khách hàng'),
          const SizedBox(height: 12),
          _buildReviewSummary(detail, reviews),
        ],
      ),
    );
  }

  Widget _buildRelatedSection(List<ProductModel> products) {
    if (products.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: const Text(
          'Không có sản phẩm gợi ý.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: const Color(0xFFE5E7EB)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Có thể bạn cũng thích',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: const Color(0xFFE5E7EB)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.66,
            ),
            itemBuilder: (context, index) =>
                ProductCard(product: products[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(height: 10, color: const Color(0xFFF3F4F6));
  }

  Widget _buildImageCarousel(ProductPublicDetailDTO detail) {
    final images = detail.imageUrls.isNotEmpty
        ? detail.imageUrls
        : ['https://picsum.photos/seed/default-product/600/600'];

    return SizedBox(
      height: 420,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) =>
                setState(() => _currentImageIndex = index),
            itemBuilder: (context, index) {
              return Image.network(
                images[index],
                fit: BoxFit.cover,
                width: double.infinity,
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.32), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Row(
                  children: [
                    _buildOverlayIcon(
                      icon: LucideIcons.arrowLeft,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    _buildOverlayIcon(
                      icon: LucideIcons.share2,
                      onTap: () => showAppToast(
                        context,
                        message: 'Chia sẻ sản phẩm',
                        type: AppToastType.info,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildOverlayIcon(
                      icon: LucideIcons.moreVertical,
                      onTap: () => showAppToast(
                        context,
                        message: 'Thêm tuỳ chọn',
                        type: AppToastType.info,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${images.length}',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.28),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildBadgeSection(List<String> badges) {
    if (badges.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges
          .map(
            (badge) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Color(0xFF4338CA),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPriceSection(ProductPublicDetailDTO detail) {
    final hasDiscount =
        detail.originalPrice != null &&
        (detail.originalPrice ?? 0) > (detail.price ?? 0);
    return Row(
      children: [
        Text(
          detail.priceText,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 12),
        if (hasDiscount) ...[
          Text(
            detail.originalPriceText,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF94A3B8),
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '-${detail.discountPercent ?? 0}%',
              style: const TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingRow(ProductPublicDetailDTO detail) {
    final ratingValue = detail.rating ?? 0.0;
    final starCount = ratingValue.round().clamp(0, 5);
    return Row(
      children: [
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              index < starCount ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          ratingValue.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          detail.reviewSummary,
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        const Spacer(),
        Text(
          detail.soldText,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildShopCard(ProductPublicDetailDTO detail, ShopPublicDTO? shop) {
    final shopName = shop?.name ?? detail.shopName ?? 'Cửa hàng';
    final shopRating = shop?.rating ?? detail.shopRating;
    final shopProductCount = shop?.productCount ?? detail.shopProductCount;
    final isVerified =
        (shop?.badges.isNotEmpty ?? false) || detail.shopVerified == true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ShopDetailScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  backgroundImage: detail.shopLogoUrl != null
                      ? NetworkImage(detail.shopLogoUrl!) as ImageProvider
                      : null,
                  child: detail.shopLogoUrl == null
                      ? const Icon(Icons.store, color: Color(0xFF94A3B8))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shopName,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: const Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Online gần đây',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShopDetailScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFB5533)),
                    foregroundColor: const Color(0xFFFB5533),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    'Xem Shop',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildShopStat(
                    value: shopRating?.toStringAsFixed(1) ?? '0.0',
                    label: 'Điểm shop',
                  ),
                ),
                Expanded(
                  child: _buildShopStat(
                    value: '${shopProductCount ?? 0}',
                    label: 'Sản phẩm',
                  ),
                ),
                Expanded(
                  child: _buildShopStat(
                    value: isVerified ? '100%' : '--',
                    label: 'Phản hồi chat',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Các sản phẩm khác của Shop',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
              ],
            ),
            const SizedBox(height: 12),
            _buildRelatedProductsPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildShopStat({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProductsPreview() {
    return SizedBox(
      height: 265,
      child: FutureBuilder<ProductDetailPageData>(
        future: _pageDataFuture,
        builder: (context, snapshot) {
          final products = snapshot.data?.relatedProducts ?? <ProductModel>[];
          if (products.isEmpty) {
            return const SizedBox.shrink();
          }

          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailScreen(productId: product.id),
                      ),
                    );
                  },
                  child: _buildShopProductPreviewCard(product),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShopProductPreviewCard(ProductModel product) {
    final hasImage = product.image.isNotEmpty;

    return Container(
      width: 148,
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 118,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFF8FAFC),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: hasImage
                        ? Image.network(
                            product.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildShopProductImageFallback(),
                          )
                        : _buildShopProductImageFallback(),
                  ),
                ),
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      product.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 40,
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Wrap(
                        spacing: 3,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          Text(
                            '${product.reviews} đánh giá',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  product.price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopProductImageFallback() {
    return Container(
      color: const Color(0xFFF8FAFC),
      alignment: Alignment.center,
      child: const Icon(
        Icons.inventory_2_rounded,
        size: 32,
        color: Color(0xFFFB923C),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildReviewSummary(
    ProductPublicDetailDTO detail,
    List<ProductPublicReviewDTO> reviews,
  ) {
    if (reviews.isEmpty) {
      return const Text(
        'Chưa có đánh giá nào.',
        style: TextStyle(color: Color(0xFF64748B)),
      );
    }

    final previewReviews = reviews.take(_reviewPreviewLimit).toList();
    final summaryRating = detail.shopRating ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              summaryRating.toStringAsFixed(1),
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đánh giá sản phẩm (${reviews.length})',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
            TextButton(
              onPressed: _showAllReviews,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tất cả',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 4),
        ...previewReviews.map(
          (review) => _buildReviewCard(review, showImages: false),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _showAllReviews,
          child: const Text('Xem tất cả đánh giá'),
        ),
      ],
    );
  }

  Widget _buildReviewCard(
    ProductPublicReviewDTO review, {
    bool showImages = true,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _reviewInitial(review.authorName),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _maskReviewerName(review.authorName),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < (review.rating ?? 0).round().clamp(0, 5)
                              ? Icons.star
                              : Icons.star_border,
                          size: 14,
                          color: const Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                    if ((review.variant ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Phân loại: ${review.variant}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${review.likeCount ?? 0} hữu ích',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if ((review.createdAt ?? '').isNotEmpty) ...[
            Text(
              _formatReviewDate(review.createdAt),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            review.comment ?? 'Khách hàng chưa để lại nhận xét.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF374151),
              height: 1.45,
            ),
          ),
          if (showImages && review.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      review.images[index],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAllReviews() async {
    final productId = widget.productId;
    if (productId == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.82,
            child: FutureBuilder<List<ProductPublicReviewDTO>>(
              future: _productService.getProductReviews(productId, size: 100),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Không tải được tất cả đánh giá.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF475569),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final allReviews = snapshot.data ?? <ProductPublicReviewDTO>[];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Tất cả đánh giá (${allReviews.length})',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
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
                        itemCount: allReviews.length,
                        itemBuilder: (context, index) =>
                            _buildReviewCard(allReviews[index]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _maskReviewerName(String? name) {
    final value = (name ?? 'Khách hàng').trim();
    if (value.length <= 2) return value;
    return '${value[0]}${'*' * (value.length - 2)}${value[value.length - 1]}';
  }

  String _reviewInitial(String? name) {
    final value = (name ?? 'K').trim();
    return value.isEmpty ? 'K' : value[0].toUpperCase();
  }

  String _formatReviewDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }

  Widget _buildBottomBar(ProductPublicDetailDTO detail, ShopPublicDTO? shop) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 58,
              child: Row(
                children: [
                  Expanded(
                    child: _buildBottomNavAction(
                      icon: LucideIcons.messageCircle,
                      label: 'Chat ngay',
                      onTap: () =>
                          _onTapBottomAction('Chat ngay', detail, shop),
                    ),
                  ),
                  Expanded(
                    child: _buildBottomNavAction(
                      icon: LucideIcons.shoppingCart,
                      label: 'Thêm vào giỏ',
                      onTap: () =>
                          _onTapBottomAction('Thêm vào giỏ', detail, shop),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 58,
              child: ElevatedButton(
                onPressed: () => _onTapBottomAction('Mua ngay', detail, shop),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFA541C),
                  elevation: 0,
                  shape: const RoundedRectangleBorder(),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'Mua ngay',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
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

  Widget _buildBottomNavAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFF1F5F9)),
            right: BorderSide(color: Color(0xFFF1F5F9)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: const Color(0xFF14B8A6)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F766E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTapBottomAction(
    String action,
    ProductPublicDetailDTO detail,
    ShopPublicDTO? shop,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      _showAuthDialog(context);
      return;
    }

    if (action == 'Mua ngay') {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.prepareBuyNow(
        _buildCheckoutProduct(detail),
        _resolveShopName(detail, shop),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CheckoutScreen()),
      );
      return;
    }

    if (action == 'Chat ngay') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            conversationId: 'temp_conv', // Temporary ID until integrated with actual logic
            shopId: shop?.id?.toString() ?? detail.shopId?.toString() ?? '',
            shopName: shop?.name ?? detail.shopName ?? 'Cửa hàng',
            shopAvatarUrl: shop?.imageUrl ?? detail.shopLogoUrl,
          ),
        ),
      );
      return;
    }

    if (action == 'Thêm vào giỏ') {
      final appState = Provider.of<AppState>(context, listen: false);
      appState.addToCart(
        _buildCheckoutProduct(detail),
        _resolveShopName(detail, shop),
      );
    }

    showAppToast(
      context,
      message: '$action thành công',
      type: AppToastType.success,
    );
  }

  ProductModel _buildCheckoutProduct(ProductPublicDetailDTO detail) {
    return ProductModel(
      id: detail.id?.toString() ?? '',
      name: detail.name ?? 'Sản phẩm',
      price: detail.priceText,
      rating: detail.rating ?? detail.shopRating ?? 0,
      reviews: detail.reviewCount ?? 0,
      image: detail.imageUrls.isNotEmpty ? detail.imageUrls.first : '',
      type: 'product',
      category: detail.categoryName ?? 'Tất cả',
      description: detail.description ?? 'Chưa có thông tin mô tả chi tiết.',
    );
  }

  String _resolveShopName(
    ProductPublicDetailDTO detail, [
    ShopPublicDTO? shop,
  ]) {
    return shop?.name ?? detail.shopName ?? 'Cửa hàng';
  }

  void _showAuthDialog(BuildContext context) {
    showLoginRequiredSheet(context);
  }

  void _logProductViewed(ProductPublicDetailDTO detail) {
    // Log product to recently viewed (Hive storage)
    final appState = Provider.of<AppState>(context, listen: false);
    if (detail.id != null) {
      final product = ProductModel(
        id: detail.id.toString(),
        name: detail.name ?? 'Sản phẩm',
        price: detail.price?.toString() ?? '0',
        rating: detail.rating ?? 0.0,
        reviews: detail.reviewCount ?? 0,
        image: detail.imageUrls.isNotEmpty ? detail.imageUrls[0] : '',
        type: 'product',
        category: detail.categoryName ?? 'Khác',
      );
      appState.logProductViewed(product);
    }
  }
}

class ProductDetailPageData {
  final ProductPublicDetailDTO detail;
  final ShopPublicDTO? shop;
  final List<ProductModel> relatedProducts;
  final List<ProductPublicReviewDTO> topReviews;

  ProductDetailPageData({
    required this.detail,
    required this.shop,
    required this.relatedProducts,
    required this.topReviews,
  });
}
