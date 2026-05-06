import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/models/product_model.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/providers/auth_provider.dart';
import '../../shop/screens/shop_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String? productId; // Bắt buộc cho logic sau này, tạm để nullable để code cũ không chết
  const ProductDetailScreen({super.key, this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  String _selectedSize = '2kg';
  final List<String> _sizes = ['500g', '1kg', '2kg', '5kg'];
  ProductModel? product;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.productId != null) {
        final state = context.read<AppState>();
        final p = state.getProductById(widget.productId!);
        if (p != null) {
          state.logProductViewed(p);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.productId != null) {
      product = context.watch<AppState>().getProductById(widget.productId!);
    }
    
    // Fallback if product not found or not passed
    final displayProduct = product ?? ProductModel(
      id: '0',
      name: 'Túi Hạt Thức Ăn Mèo Cao Cấp (2kg)',
      price: '250.000đ',
      rating: 4.8,
      reviews: 120,
      image: 'https://picsum.photos/seed/catfood/600/600',
      type: 'product',
      category: 'Khác',
      description: 'Sản phẩm hạt thức ăn cao cấp dành cho mèo với đầy đủ dưỡng chất...'
    );

    return Scaffold(
      backgroundColor: Colors.white,
      // 1. Custom Gradient AppBar
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Product Image
            _buildProductImage(displayProduct.image, displayProduct.id),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3. Product Title
                  Text(
                    displayProduct.name,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 4. Price
                  Text(
                    displayProduct.price,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. Rating & Sales
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < displayProduct.rating.floor() ? Icons.star : Icons.star_half,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${displayProduct.reviews} Đánh giá)',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Đã bán 500+',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Shop Section
                  _buildShopSection(context),

                  // 6. Expandable Sections
                  _buildExpandableSection('Mô tả sản phẩm', displayProduct.description),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _buildExpandableSection('Đánh giá', 'Xem tất cả ${displayProduct.reviews} đánh giá từ khách hàng...'),
                ],
              ),
            ),
          ],
        ),
      ),
      // 7. Bottom Action Bar
      bottomNavigationBar: _buildBottomActionBar(displayProduct),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD946EF), Color(0xFF8B5CF6)], // Pink to Purple gradient
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Chi tiết sản phẩm',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            if (widget.productId != null)
              Consumer<AppState>(
                builder: (context, state, child) {
                  final isLiked = state.isLiked(widget.productId!);
                  return IconButton(
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.redAccent : Colors.white,
                    ),
                    onPressed: () {
                      state.toggleLike(widget.productId!);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl, String productId) {
    return Container(
      width: double.infinity,
      height: 350,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Hero(
          tag: 'product_image_$productId',
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection(String title, String content) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(
            content,
            style: const TextStyle(color: Color(0xFF64748B), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildShopSection(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ShopDetailScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage('https://picsum.photos/seed/shopprofile/200/200'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Golden Paws Spa',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.green, size: 14),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Xem ngay cửa hàng >',
                    style: TextStyle(
                      color: Color(0xFFFB7185),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  Widget _buildBottomActionBar(ProductModel displayProduct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _handleActionClick(context, 'Thêm vào giỏ', displayProduct),
              icon: const Icon(LucideIcons.shoppingCart, size: 20),
              label: const Text('Thêm vào giỏ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF472B6), // Pink
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _handleActionClick(context, 'Mua ngay', displayProduct),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF818CF8), // Purple/Indigo
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                elevation: 0,
              ),
              child: const Text('Mua ngay'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleActionClick(BuildContext context, String actionText, ProductModel displayProduct) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      _showAuthDialog(context);
    } else {
      _showSelectionSheet(context, actionText, displayProduct);
    }
  }

  void _showAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Yêu cầu đăng nhập', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Bạn chưa đăng nhập để sử dụng. Hãy đăng nhập/đăng ký.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB7185),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Đăng ký/Đăng nhập', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSelectionSheet(BuildContext context, String actionText, ProductModel displayProduct) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Image & Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Image.network(displayProduct.image),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayProduct.price,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFB7185),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kho: 1200 sản phẩm',
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Size Selection
                  const Text('Kích cỡ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: _sizes.map((size) {
                      bool isSelected = _selectedSize == size;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => _selectedSize = size);
                          setState(() => _selectedSize = size);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFB7185) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFB7185) : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            size,
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Quantity Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Số lượng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_quantity > 1) {
                                  setModalState(() => _quantity--);
                                  setState(() => _quantity--);
                                }
                              },
                              icon: const Icon(Icons.remove, size: 18),
                            ),
                            Text(
                              _quantity.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              onPressed: () {
                                setModalState(() => _quantity++);
                                setState(() => _quantity++);
                              },
                              icon: const Icon(Icons.add, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AppState>().addToCart(displayProduct, 'Doggo Planet', _quantity);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã thêm $_quantity x ${displayProduct.name} vào giỏ hàng')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFB7185),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        elevation: 0,
                      ),
                      child: Text(
                        actionText,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}