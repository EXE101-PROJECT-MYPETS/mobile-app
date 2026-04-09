import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _agreeTerms = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header dùng chung
            const _CommonHeader(title: 'Đăng ký'),

            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Hàng 1: Họ tên & Email
                      Row(
                        children: [
                          const Expanded(
                            child: _CustomTextField(
                              label: 'Họ và tên',
                              hintText: 'Nguyễn Văn A',
                              prefixIcon: LucideIcons.user,
                              isRequired: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: _CustomTextField(
                              label: 'Email',
                              hintText: 'sonledz22cm@gr',
                              prefixIcon: LucideIcons.mail,
                              isRequired: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Hàng 2: Số điện thoại
                      const _CustomTextField(
                        label: 'Số điện thoại',
                        hintText: '0900000000',
                        prefixIcon: LucideIcons.phone,
                        isRequired: true,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Hàng 3: Địa chỉ & Tuổi
                      Row(
                        children: [
                          const Expanded(
                            child: _CustomTextField(
                              label: 'Địa chỉ',
                              hintText: 'Ví dụ: 123 Nguyễn',
                              prefixIcon: LucideIcons.mapPin,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: _CustomTextField(
                              label: 'Tuổi',
                              hintText: 'Ví dụ: 20',
                              prefixIcon: LucideIcons.calendar,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Hàng 4: Ảnh đại diện
                      const _AvatarPicker(),
                      const SizedBox(height: 16),

                      // Hàng 5: Mật khẩu & Xác nhận
                      Row(
                        children: [
                          const Expanded(
                            child: _CustomTextField(
                              label: 'Mật khẩu',
                              hintText: '****',
                              prefixIcon: LucideIcons.lock,
                              isPassword: true,
                              isRequired: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: _CustomTextField(
                              label: 'Xác nhận mật khẩu',
                              hintText: 'Nhập lại mật khẩu',
                              prefixIcon: LucideIcons.lock,
                              isPassword: true,
                              isRequired: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Điều khoản
                      Row(
                        children: [
                          Checkbox(
                            value: _agreeTerms,
                            onChanged: (v) => setState(() => _agreeTerms = v!),
                            activeColor: const Color(0xFF4A90E2),
                          ),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                children: [
                                  TextSpan(text: 'Tôi đồng ý với '),
                                  TextSpan(
                                    text: 'điều khoản và chính sách bảo mật.',
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Nút Tạo tài khoản
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            elevation: 0,
                          ),
                          child: const Text('Tạo tài khoản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Social Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Hoặc đăng ký bằng: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          const SizedBox(width: 12),
                          const Icon(Icons.g_mobiledata, color: Colors.red, size: 32),
                          const SizedBox(width: 16),
                          const Icon(Icons.facebook, color: Color(0xFF1877F2), size: 28),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Quay lại Đăng nhập
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                              children: [
                                TextSpan(text: 'Đã có tài khoản? '),
                                TextSpan(
                                  text: 'Đăng nhập',
                                  style: TextStyle(color: Color(0xFF0288D1), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

// --- CÁC WIDGET HỖ TRỢ (Private) ---

class _CommonHeader extends StatelessWidget {
  final String title;
  const _CommonHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFF472B6), Color(0xFFFB7185)]),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'PetPee',
            style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final bool isRequired;
  final TextInputType? keyboardType;

  const _CustomTextField({
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.isRequired = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            children: isRequired ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : [],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(prefixIcon, color: const Color(0xFFFB7185).withOpacity(0.7), size: 16),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ảnh đại diện',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.image, color: Color(0xFFFB7185), size: 18),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Text('Chọn tệp', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Chưa có tệp nào được chọn',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}