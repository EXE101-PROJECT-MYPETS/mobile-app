import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../chat/screens/chat_detail_screen.dart';

class ShopDetailScreen extends StatelessWidget {
  const ShopDetailScreen({super.key});

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
            Container(height: 8, color: const Color(0xFFF8FAFC)), // Thick separator
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
                _buildCircleButton(Icons.arrow_back, () => Navigator.pop(context)),
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
              const SizedBox(width: 100), // Space for profile picture (80 width + 20 margin)
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
                        const Icon(Icons.verified, color: Colors.green, size: 18),
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChatDetailScreen(
                                    conversationId: 'temp_1',
                                    shopId: '1',
                                    shopName: 'Golden Paws Spa',
                                    shopAvatarUrl: 'https://picsum.photos/seed/shopprofile/200/200',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(LucideIcons.messageSquare, size: 16, color: Colors.white),
                            label: const Text('Chat ngay', style: TextStyle(fontSize: 13, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Theo dõi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
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
          _buildStatColumn('Đánh giá', '4.6', subValue: ' (210)'),
          _buildStatColumn('Sản phẩm', '8'),
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
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: value),
              if (subValue != null)
                TextSpan(
                  text: subValue,
                  style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.normal),
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
            child: const Icon(LucideIcons.mapPin, color: Color(0xFF94A3B8), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ĐỊA CHỈ CHI TIẾT',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '45 Le Loi, District 1, Ho Chi Minh City',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductsSection() {
    final List<Map<String, dynamic>> products = [
      {
        'name': 'Gói spa cao cấp cho chó',
        'price': '349,000 VND',
        'rating': 4.7,
        'reviews': 98,
        'image': 'https://picsum.photos/seed/spa_dog/400/300',
        'badge': 'DỊCH VỤ'
      },
      {
        'name': 'Lấy cao răng thú y',
        'price': '150,000 VND',
        'rating': 4.7,
        'reviews': 89,
        'image': 'https://picsum.photos/seed/spa_cat/400/300',
        'badge': 'THÚ Y'
      },
    ];

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
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _ProductCard(product: products[index]);
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '(${product['reviews']} đánh giá)',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
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
                    label: const Text('Thêm giỏ hàng', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFB7185),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
