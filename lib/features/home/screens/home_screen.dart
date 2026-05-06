import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/product_card.dart';
import '../../profile/screens/profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // 1. Header & Search Bar
      appBar: const _HomeHeader(),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Banner Carousel
            const _BannerSection(),

            // 3. Quick Actions (Hàng quốc tế, Giao nhanh...)
            const _QuickActionsSection(),

            // 4. Danh mục (DANH MỤC)
            const _SectionTitle(title: 'DANH MỤC'),
            const _CategoriesSection(),

            // 5. Dịch vụ nổi bật (DỊCH VỤ SPA & THÚ Y NỔI BẬT)
            const _SectionTitle(title: 'DỊCH VỤ SPA & THÚ Y NỔI BẬT'),
            const _FeaturedServicesSection(),

            // 5.5 Bản đồ Spa gần đây
            const _SectionTitle(title: 'SPA GẦN BẠN'),
            const _NearbySpaMapSection(),

            // 6. Sản phẩm tương tự (Hiển thị nếu có lịch sử xem)
            Consumer<AppState>(
              builder: (context, state, child) {
                final similar = state.similarProducts;
                if (similar.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionTitle(title: 'SẢN PHẨM TƯƠNG TỰ'),
                    _ProductsGridSection(products: similar),
                  ],
                );
              },
            ),

            // 7. Tất cả sản phẩm
            const _SectionTitle(title: 'TẤT CẢ SẢN PHẨM'),
            Consumer<AppState>(
              builder: (context, state, child) {
                return _ProductsGridSection(products: state.allProducts);
              },
            ),

            const SizedBox(height: 100), // Khoảng trống cuối trang
          ],
        ),
      ),

      // 6. Floating Action Button (Nút mèo hồng)
      floatingActionButton: _buildFloatingChatButton(),

      // 7. Bottom Navigation Bar
      bottomNavigationBar: const _BottomNavBar(),
    );
  }

  Widget _buildFloatingChatButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC1D6),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.pink.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: const Center(
        child: Icon(LucideIcons.cat, color: Colors.white, size: 30),
      ),
    );
  }
}

// --- WIDGETS THÀNH PHẦN ---

// Header chứa Logo, Icon và Thanh tìm kiếm
class _HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 16, right: 16, bottom: 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFF472B6), Color(0xFFFB7185)]),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PETPEE', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  const Text('Cửa hàng cho thú cưng', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
              const Spacer(),
              Consumer<AuthProvider>(
                builder: (context, auth, child) {
                  if (auth.currentUser == null) {
                    return ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFB7185),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        minimumSize: Size.zero,
                        elevation: 0,
                      ),
                      child: const Text('Đăng nhập', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    );
                  }
                  
                  final userInitial = auth.currentUser?.fullName.isNotEmpty == true 
                      ? auth.currentUser!.fullName.substring(0, 1).toUpperCase() 
                      : 'U';
                      
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/notifications'),
                        child: _buildIconButton(LucideIcons.bell, badge: '3'),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/cart'),
                        child: _buildIconButton(LucideIcons.shoppingCart, badge: '2'),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 15, 
                        backgroundColor: Colors.white24,
                        backgroundImage: auth.currentUser?.avatarUrlPreview != null
                            ? NetworkImage(auth.currentUser!.avatarUrlPreview!)
                            : null,
                        child: auth.currentUser?.avatarUrlPreview == null ? Text(userInitial, style: const TextStyle(color: Colors.white, fontSize: 12)) : null,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Thanh tìm kiếm
          Container(
            height: 40,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Expanded(
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm sản phẩm...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFFB7185), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(LucideIcons.search, color: Colors.white, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {String? badge}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        if (badge != null)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(140);
}

// Banner quảng cáo
class _BannerSection extends StatelessWidget {
  const _BannerSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: NetworkImage('https://picsum.photos/seed/pet/800/400'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PETPEES MALL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('Đồng hành cùng nàng', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Voucher Độc và ưu đãi cho pet owner mới', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: index == 0 ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(color: index == 0 ? Colors.pink : Colors.grey[300], borderRadius: BorderRadius.circular(3)),
            )),
          ),
        ],
      ),
    );
  }
}

// Các nút chức năng nhanh
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'icon': LucideIcons.globe, 'label': 'Hàng\nQuốc Tế'},
      {'icon': LucideIcons.zap, 'label': 'Giao Nhanh'},
      {'icon': LucideIcons.clock, 'label': 'Giờ Vàng\nGiá Sốc'},
      {'icon': LucideIcons.ticket, 'label': 'Mã Giảm\nGiá'},
      {'icon': LucideIcons.heart, 'label': 'Khách hàng\nthân thiết'},
      {'icon': LucideIcons.percent, 'label': 'Mã giảm giá'},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.pink[50], shape: BoxShape.circle),
                  child: Icon(actions[index]['icon'] as IconData, color: Colors.pink[400], size: 24),
                ),
                const SizedBox(height: 6),
                Text(actions[index]['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Danh mục sản phẩm
class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection();

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'img': 'https://picsum.photos/seed/cat1/100', 'label': 'Tất cả'},
      {'img': 'https://picsum.photos/seed/cat2/100', 'label': 'Dịch vụ Spa'},
      {'img': 'https://picsum.photos/seed/cat3/100', 'label': 'Thú y'},
      {'img': 'https://picsum.photos/seed/cat4/100', 'label': 'Chó'},
      {'img': 'https://picsum.photos/seed/cat5/100', 'label': 'Mèo'},
      {'img': 'https://picsum.photos/seed/cat6/100', 'label': 'Cát vệ sinh'},
      {'img': 'https://picsum.photos/seed/cat7/100', 'label': 'Sữa tắm'},
      {'img': 'https://picsum.photos/seed/cat8/100', 'label': 'Đồ chơi'},
      {'img': 'https://picsum.photos/seed/cat9/100', 'label': 'Thức ăn'},
      {'img': 'https://picsum.photos/seed/cat10/100', 'label': 'Nhà cho mèo'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 16, crossAxisSpacing: 10, childAspectRatio: 0.6),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            if (categories[index]['label'] == 'Tất cả') {
              Navigator.pushNamed(context, '/products');
            }
          },
          child: Column(
            children: [
              CircleAvatar(radius: 28, backgroundColor: Colors.grey[100], backgroundImage: NetworkImage(categories[index]['img']!)),
              const SizedBox(height: 6),
              Text(categories[index]['label']!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      },
    );
  }
}

// Dịch vụ nổi bật
class _FeaturedServicesSection extends StatelessWidget {
  const _FeaturedServicesSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network('https://picsum.photos/seed/service$index/200/150', height: 120, width: double.infinity, fit: BoxFit.cover),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gói spa cơ bản cho mèo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 2),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4)),
                        child: Text('Spa', style: TextStyle(color: Colors.green[700], fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      const Text('188.000 VND', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 13)),
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

// Grid sản phẩm tái sử dụng
class _ProductsGridSection extends StatelessWidget {
  final List<dynamic> products;
  const _ProductsGridSection({required this.products});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return ProductCard(product: products[index]);
      },
    );
  }
}

// Tiêu đề các mục
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
    );
  }
}

// Thanh điều hướng dưới cùng
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.pink,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
      },
      selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      items: const [
        BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.utensils), label: 'Dịch vụ'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.store), label: 'Cửa hàng'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.ticket), label: 'Ưu đãi'),
        BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Tài khoản'),
      ],
    );
  }
}

// Helper mở rộng cho Gradient
extension on Color {
  Decoration get gradient => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [this, Colors.transparent],
    ),
  );
}

// --- BẢN ĐỒ SPA GẦN ĐÂY ---
class _NearbySpaMapSection extends StatefulWidget {
  const _NearbySpaMapSection();

  @override
  State<_NearbySpaMapSection> createState() => _NearbySpaMapSectionState();
}

class _NearbySpaMapSectionState extends State<_NearbySpaMapSection> {
  bool _isLoadingLocation = false;
  bool _locationGranted = false;

  void _requestLocation() async {
    setState(() => _isLoadingLocation = true);
    // Giả lập thời gian load xin quyền vị trí
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
        _locationGranted = true; // Cấp quyền thành công
      });
      // Hiện Snackbar thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã cập nhật vị trí của bạn!'),
          backgroundColor: Colors.pink.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_locationGranted) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: const NetworkImage('https://picsum.photos/seed/map_blur/800/400'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken), // Làm tối làm mờ
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.mapPin, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              const Text('Khám phá Spa quanh bạn', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isLoadingLocation ? null : _requestLocation,
                icon: _isLoadingLocation 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.pink, strokeWidth: 2))
                    : const Icon(LucideIcons.navigation, size: 18),
                label: Text(_isLoadingLocation ? 'Đang định vị...' : 'Bật Vị Trí'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.pink,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Giao diện khi ĐÃ CẤP QUYỀN
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          // Giao diện nền Bản đồ giả lập
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              'https://picsum.photos/seed/map_clear/800/400', // Tượng trưng cho bản đồ Mapbox/Google Map
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          
          // Các Pin marker trên bản đồ
          Positioned(top: 50, left: 80, child: _buildMapPin('PetPee Quận 1')),
          Positioned(top: 120, right: 60, child: _buildMapPin('Sunny Spa', isHighlight: true)),

          // Cửa sổ cuộn nổi bật (Bottom sheet in card)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                ],
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                children: [
                  _buildNearbyShopCard('Sunny Spa (Gần nhất)', '1.2 km', 'https://picsum.photos/seed/shop1/100', true),
                  _buildNearbyShopCard('PetPee Quận 1', '3.5 km', 'https://picsum.photos/seed/shop2/100', false),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMapPin(String name, {bool isHighlight = false}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isHighlight ? Colors.pink : Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
          ),
          child: Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isHighlight ? Colors.white : Colors.black)),
        ),
        Icon(LucideIcons.mapPin, color: isHighlight ? Colors.pink : Colors.red, size: 24),
      ],
    );
  }

  Widget _buildNearbyShopCard(String name, String distance, String imgUrl, bool isSelected) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.pink.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? Colors.pink.shade200 : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imgUrl, width: 60, height: 60, fit: BoxFit.cover)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.navigation, color: Colors.grey, size: 12),
                    const SizedBox(width: 4),
                    Text(distance, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}