import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/common/auth/page/login_screen.dart';
import 'profile_addresses_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
            _SettingsLoginRequiredScreen(title: title, message: message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 50 background for depth
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 80,
        leading: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFFB7185),
            size: 16,
          ),
          label: const Text(
            '',
            style: TextStyle(color: Color(0xFFFB7185), fontSize: 14),
          ),
        ),
        title: Text(
          'Thiết lập tài khoản',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  LucideIcons.messageCircle,
                  color: Color(0xFFFB7185),
                ),
                onPressed: () {},
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE91E63),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              _buildSectionHeader('Tài khoản của tôi'),
              _buildMenuCard([
                _buildMenuItem(
                  'Tài khoản & Bảo mật',
                  LucideIcons.shieldCheck,
                  onTap: () {
                    final authProvider = context.read<AuthProvider>();
                    if (!_isLoggedIn(authProvider)) {
                      _openLoginRequiredScreen(
                        context,
                        title: 'Tài khoản & Bảo mật',
                        message:
                            'Vui lòng đăng nhập để xem tài khoản và bảo mật',
                      );
                      return;
                    }
                  },
                ),
                const Divider(height: 1, indent: 48),
                _buildMenuItem(
                  'Địa chỉ',
                  LucideIcons.mapPin,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileAddressesScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 48),
                _buildMenuItem(
                  'Tài khoản / Thẻ ngân hàng',
                  LucideIcons.creditCard,
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionHeader('Cài đặt'),
              _buildMenuCard([
                _buildMenuItem('Cài đặt Chat', LucideIcons.messageSquare),
                const Divider(height: 1, indent: 48),
                _buildMenuItem('Cài đặt Thông báo', LucideIcons.bell),
                const Divider(height: 1, indent: 48),
                _buildMenuItem('Cài đặt riêng tư', LucideIcons.lock),
                const Divider(height: 1, indent: 48),
                _buildMenuItem('Người dùng đã bị chặn', LucideIcons.userX),
                const Divider(height: 1, indent: 48),
                _buildMenuItem(
                  'Ngôn ngữ / Language',
                  LucideIcons.globe,
                  subtitle: 'Tiếng Việt',
                ),
              ]),

              const SizedBox(height: 16),
              _buildSectionHeader('Hỗ trợ'),
              _buildMenuCard([
                _buildMenuItem('Trung tâm hỗ trợ', LucideIcons.helpCircle),
                const Divider(height: 1, indent: 48),
                _buildMenuItem('Tiêu chuẩn cộng đồng', LucideIcons.users),
                const Divider(height: 1, indent: 48),
                _buildMenuItem('Điều khoản Petpees', LucideIcons.fileText),
                const Divider(height: 1, indent: 48),
                _buildMenuItem('Giới thiệu', LucideIcons.info),
                const Divider(height: 1, indent: 48),
                _buildMenuItem(
                  'Yêu cầu hủy tài khoản',
                  LucideIcons.trash2,
                  isDestructive: true,
                ),
              ]),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFE91E63),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.pink.shade100, width: 2),
                    ),
                  ),
                  onPressed: () async {
                    await Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    ).logout();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text(
                    'Đăng xuất',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon, {
    String? subtitle,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red.shade400 : const Color(0xFFFB7185),
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red.shade600 : Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.black26,
        size: 20,
      ),
      onTap: onTap ?? () {},
    );
  }
}

class _SettingsLoginRequiredScreen extends StatelessWidget {
  const _SettingsLoginRequiredScreen({
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
