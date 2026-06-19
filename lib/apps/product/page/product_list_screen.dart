import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:pawly_mobile/common/store/app_state.dart';
import 'package:pawly_mobile/common/component/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  int _selectedCategoryIndex = 0;
  final List<String> _categories = [
    'Tất cả',
    'Chó',
    'Mèo',
    'Spa',
    'Thú y',
    'Cát vệ sinh',
    'Sữa tắm',
    'Đồ chơi',
    'Thức ăn',
    'Nhà cho mèo',
    'Nhà cho chó',
  ];
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      final appState = context.read<AppState>();
      if (!appState.isLoadingProducts && appState.hasMoreProducts) {
        appState.loadMoreProducts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    var allProducts = appState.allProducts;

    // Filter products based on selected category
    var products = _selectedCategoryIndex == 0
        ? allProducts
        : allProducts
            .where(
              (p) =>
                  p.category == _categories[_selectedCategoryIndex] ||
                  (p.type == 'spa' &&
                      _categories[_selectedCategoryIndex] == 'Spa') ||
                  (p.type == 'thu_y' &&
                      _categories[_selectedCategoryIndex] == 'Thú y'),
            )
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F7), // Nền hồng nhạt rất nhẹ
      appBar: const _ProductListHeader(),
      body: Column(
        children: [
          // 1. Bộ lọc danh mục (Tất cả, Chó, Mèo...)
          _buildCategoryFilter(),

          // 2. Lưới sản phẩm (2 cột)
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72, // Tỉ lệ khung hình thẻ sản phẩm
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return ProductCard(product: products[index]);
              },
            ),
          ),
          if (appState.isLoadingProducts && allProducts.isNotEmpty)
            const SizedBox(
              height: 68,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // Widget xây dựng thanh chọn danh mục nằm ngang
  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFB7185)
                    : const Color(0xFFFFE4E9),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFFB7185),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Header chứa Logo, Thanh tìm kiếm và Giỏ hàng
class _ProductListHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const _ProductListHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        bottom: 10,
      ),
      color: Colors.white,
      child: Row(
        children: [
          // Logo Pawly
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PAWLYS',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFB7185),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Text(
                'Pet Marketplace',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Thanh tìm kiếm
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  SizedBox(width: 10),
                  Icon(LucideIcons.search, color: Colors.grey, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Tìm sản phẩm, spa, gói dịch vụ...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Icon Giỏ hàng với Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                LucideIcons.shopping_cart,
                color: Colors.grey,
                size: 24,
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(color: Colors.white, fontSize: 8),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
