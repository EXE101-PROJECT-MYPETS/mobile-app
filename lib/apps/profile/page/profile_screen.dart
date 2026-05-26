import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/apps/home/page/home_screen.dart';
import 'package:petpee_mobile/apps/home/page/notifications_screen.dart';
import 'package:petpee_mobile/apps/product/page/spa_service_screen.dart';
import 'package:petpee_mobile/common/component/common_bottom_nav.dart';
import 'package:petpee_mobile/features/chat/screens/pet_ai_selection_screen.dart';
import 'settings_screen.dart';
import 'orders_screen.dart';
import 'favorite_products_screen.dart';
import 'recently_viewed_screen.dart';
import 'package:petpee_mobile/apps/cart/page/cart_screen.dart';
import 'my_pets_screen.dart';
import 'edit_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/common/config/api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _requestedProfile = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    if (_requestedProfile || !mounted) return;
    _requestedProfile = true;

    final authProvider = context.read<AuthProvider>();
    if (!_isLoggedIn(authProvider)) return;

    try {
      await authProvider.loadCurrentUserProfile();
    } catch (_) {
      // Giữ dữ liệu đang có trong Hive/login response nếu refresh profile lỗi.
    }
  }

  bool _isLoggedIn(AuthProvider authProvider) {
    return authProvider.currentUser != null &&
        (authProvider.token?.trim().isNotEmpty ?? false);
  }

  void _openLoginRequiredScreen(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _ProfileLoginRequiredScreen(title: title, message: message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Tài khoản',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.settings, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.messageCircle, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Thông tin User
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                String avatarUrl = 'https://picsum.photos/seed/user/200';
                if (user?.avatarUrlPreview != null &&
                    user!.avatarUrlPreview!.isNotEmpty) {
                  if (user.avatarUrlPreview!.startsWith('http')) {
                    avatarUrl = user.avatarUrlPreview!;
                  } else {
                    avatarUrl =
                        '${ApiConfig.baseUrl.replaceAll('/api', '')}/${user.avatarUrlPreview!}';
                  }
                }

                return GestureDetector(
                  onTap: () {
                    if (!_isLoggedIn(authProvider)) {
                      _openLoginRequiredScreen(
                        context,
                        title: 'Thông tin cá nhân',
                        message: 'Vui lòng đăng nhập để sửa thông tin cá nhân',
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: user?.avatarUrlPreview != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: user?.avatarUrlPreview == null
                              ? const Icon(
                                  LucideIcons.user,
                                  size: 30,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Khách',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.black38),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Đơn mua
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      LucideIcons.fileText,
                      color: Colors.blue,
                    ),
                    title: const Text(
                      'Đơn mua',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    trailing: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xem lịch sử mua hàng',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrdersScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildOrderStatus(LucideIcons.wallet, 'Chờ xác nhận'),
                        _buildOrderStatus(
                          LucideIcons.packageSearch,
                          'Đang xử lý',
                        ),
                        _buildOrderStatus(LucideIcons.truck, 'Đang giao'),
                        _buildOrderStatus(LucideIcons.star, 'Đánh giá'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Tiện ích chung
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildListTileItem(
                    LucideIcons.shoppingCart,
                    'Giỏ hàng',
                    Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildListTileItem(
                    LucideIcons.heart,
                    'Đã thích',
                    Colors.red,
                    onTap: () {
                      final authProvider = context.read<AuthProvider>();
                      if (!_isLoggedIn(authProvider)) {
                        _openLoginRequiredScreen(
                          context,
                          title: 'Đã thích',
                          message:
                              'Vui lòng đăng nhập để xem danh sách đã thích',
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FavoriteProductsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildListTileItem(
                    LucideIcons.clock,
                    'Đã xem gần đây',
                    Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecentlyViewedScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildListTileItem(
                    Icons.pets,
                    'Thú cưng của tôi',
                    Colors.pink,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyPetsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 48),
                  _buildListTileItem(
                    LucideIcons.star,
                    'Đánh giá của tôi',
                    Colors.amber,
                    onTap: () {
                      final authProvider = context.read<AuthProvider>();
                      if (!_isLoggedIn(authProvider)) {
                        _openLoginRequiredScreen(
                          context,
                          title: 'Đánh giá của tôi',
                          message: 'Vui lòng đăng nhập để xem đánh giá của bạn',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 4,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PetAiSelectionScreen(),
              ),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartScreen()),
            );
          } else if (index == 3) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  Widget _buildOrderStatus(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.black87, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
        ),
      ],
    );
  }

  // Hỗ trợ nhận IconData linh hoạt (Material Icon hoặc LucideIcon)
  Widget _buildListTileItem(
    IconData icon,
    String title,
    Color color, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(
        Icons.chevron_right,
        size: 16,
        color: Colors.black54,
      ),
      onTap: onTap ?? () {},
    );
  }
}

class _ProfileLoginRequiredScreen extends StatelessWidget {
  const _ProfileLoginRequiredScreen({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE9DC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.alertCircle,
                  color: Color(0xFFE76F51),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF2E251F),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đăng nhập để PetPee tải hồ sơ và đồng bộ thông tin tài khoản của bạn.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF7B685B),
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    icon: const Icon(LucideIcons.logIn, size: 18),
                    label: const Text('Đăng nhập'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      textStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
