import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:petpee_mobile/features/chat/providers/chat_provider.dart';
import 'package:petpee_mobile/features/chat/screens/chat_detail_screen.dart';
import 'package:petpee_mobile/apps/product/api/product_service.dart';
import 'package:petpee_mobile/common/user/dto/product_dto.dart';
import 'package:petpee_mobile/common/user/dto/shop_public_dto.dart';

class ShopDetailScreen extends StatefulWidget {
  const ShopDetailScreen({super.key});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  final ProductService _productService = ProductService();
  ShopPublicDTO? _shop;
  List<ProductDTO> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    try {
      // Default to shopId 1 for now (previous UI used hardcoded shop id elsewhere)
      const shopId = 1;
      final shop = await _productService.getShopDetail(shopId);
      final paging = await _productService.getAllMobile(shopId: shopId, size: 20);
      setState(() {
        _shop = shop;
        _products = paging.content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _shop = null;
        _products = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Banner and App Bar Controls
            _buildHeader(context),

            // 2. Shop Info (Profile, Actions)
            _buildShopInfo(context),

            const Divider(color: Color(0xFFF1F5F9), thickness: 1, height: 32),

            // 3. Stats Row
            _buildStatsRow(),

            const Divider(color: Color(0xFFF1F5F9), thickness: 1, height: 32),

            // 4. Address Section
            _buildAddressSection(),

            const SizedBox(height: 16),
            Container(
              height: 8,
              color: const Color(0xFFF8FAFC),
            ), // Thick separator
            const SizedBox(height: 16),

            // 5. Products Section
            _buildProductsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        // Banner Image
        Image.network(
          'https://picsum.photos/seed/catbanner123/800/400',
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        // App Bar overlay
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(
                  Icons.arrow_back,
                  () => Navigator.pop(context),
                ),
                _buildCircleButton(LucideIcons.share, () {}),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildShopInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Row containing spacing for profile pic and shop details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: 100,
              ), // Space for profile picture (80 width + 20 margin)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Title and Verified Icon
                    Row(
                      children: [
                        Text(
                          'Golden Paws Spa',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Status
                    const Text(
                      'Hoạt động 5 phút trước',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final chatProvider = context.read<ChatProvider>();
                              try {
                                final conversation =
                                    await chatProvider.openConversationForShop(
                                  '1',
                                );
                                if (!context.mounted) {
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatDetailScreen(
                                      conversationId: conversation.id,
                                      shopId: conversation.shopId,
                                      shopName: 'Golden Paws Spa',
                                      shopAvatarUrl:
                                          'https://picsum.photos/seed/shopprofile/200/200',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Không thể mở chat: $e'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              LucideIcons.messageSquare,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Chat ngay',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF60A5FA),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Theo dõi',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Profile Picture Positioned to overlap the banner
          Positioned(
            top: -24,
            left: 0,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4), // White border effect
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://picsum.photos/seed/shopprofile/200/200',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatColumn(
            'Đánh giá',
            _shop?.rating?.toStringAsFixed(1) ?? '—',
            subValue: ' (${_shop?.productCount ?? _products.length})',
          ),
          _buildStatColumn('Sản phẩm', '${_shop?.productCount ?? _products.length}'),
          _buildStatColumn('Giờ mở cửa', '09:00 - 19:00'),
          _buildStatColumn('Hotline', '0902 456 789'),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {String? subValue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            children: [
              TextSpan(text: value),
              if (subValue != null)
                TextSpan(
                  text: subValue,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.mapPin,
              color: Color(0xFF94A3B8),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ĐỊA CHỈ CHI TIẾT',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '45 Le Loi, District 1, Ho Chi Minh City',
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOÀN BỘ CỬA HÀNG',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_products.isEmpty)
            const SizedBox(
              height: 80,
              child: Center(child: Text('Không có sản phẩm')),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65, // Adjust based on your cell size
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final p = _products[index];
                return _ProductCard(product: _productToMap(p));
              },
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Map<String, dynamic> _productToMap(ProductDTO p) {
    final image = (p.imageUrls != null && p.imageUrls!.isNotEmpty)
        ? p.imageUrls!.first
        : 'https://picsum.photos/seed/product/200/200';
    final priceText = p.price != null ? '${p.price} VND' : '-';
    return {
      'name': p.name ?? '-',
      'price': priceText,
      'rating': p.reviewAvg ?? p.rating ?? 0.0,
      'reviews': p.totalReviews ?? p.reviewCount ?? 0,
      'image': image,
      'badge': p.categoryName ?? 'DỊCH VỤ',
    };
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                product['image'],
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Info Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      product['rating'].toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '(${product['reviews']} đánh giá)',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  product['price'],
                  style: const TextStyle(
                    color: Color(0xFFF43F5E), // Rose 500
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text(
                      'Thêm giỏ hàng',
                      style: TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFB7185),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
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
