import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'login_screen.dart'; // To reuse CustomTextField

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyOtp = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();

  int _step = 1;
  bool _isLoading = false;

  void _sendOtp() async {
    if (_formKeyEmail.currentState!.validate()) {
      setState(() => _isLoading = true);
      // Giả lập call API gửi OTP
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _isLoading = false;
        _step = 2;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mã OTP đã được gửi vào email của bạn')),
        );
      }
    }
  }

  void _verifyOtp() async {
    if (_formKeyOtp.currentState!.validate()) {
      if (_otpController.text == '123456') { // Mock OTP valid
        setState(() => _step = 3);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mã OTP không hợp lệ'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _changePassword() async {
    if (_formKeyPassword.currentState!.validate()) {
      setState(() => _isLoading = true);
      // Giả lập gọi API đổi mật khẩu
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi mật khẩu thành công!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Quay lại đăng nhập
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quên Mật Khẩu',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _step == 1
                  ? 'Nhập email để nhận mã OTP khôi phục.'
                  : _step == 2
                      ? 'Nhập mã OTP 6 số (Mock: 123456)'
                      : 'Nhập mật khẩu mới của bạn.',
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),

            // STEP 1: Nhập Email
            if (_step >= 1)
              Form(
                key: _formKeyEmail,
                child: CustomTextField(
                  label: 'Email',
                  hintText: 'Nhập email của bạn',
                  prefixIcon: LucideIcons.mail,
                  controller: _emailController,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Vui lòng nhập email';
                    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(val)) {
                      return 'Email không đúng định dạng';
                    }
                    return null;
                  },
                ),
              ),

            if (_step == 1) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Gửi OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],

            // STEP 2: Nhập OTP
            if (_step >= 2) ...[
              const SizedBox(height: 24),
              Form(
                key: _formKeyOtp,
                child: CustomTextField(
                  label: 'Mã OTP',
                  hintText: 'Nhập mã 6 chữ số',
                  prefixIcon: LucideIcons.key,
                  controller: _otpController,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Vui lòng nhập mã OTP';
                    return null;
                  },
                ),
              ),
            ],

            if (_step == 2) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Xác nhận OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],

            // STEP 3: Mật khẩu mới
            if (_step == 3) ...[
              const SizedBox(height: 24),
              Form(
                key: _formKeyPassword,
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Mật khẩu mới',
                      hintText: 'Nhập mật khẩu',
                      prefixIcon: LucideIcons.lock,
                      isPassword: true,
                      controller: _newPasswordController,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Bắt buộc';
                        if (val.length < 6) return 'Tối thiểu 6 ký tự';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      label: 'Xác nhận mật khẩu mới',
                      hintText: 'Nhập lại',
                      prefixIcon: LucideIcons.lock,
                      isPassword: true,
                      controller: _confirmPasswordController,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Bắt buộc';
                        if (val != _newPasswordController.text) return 'Không khớp';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đổi mật khẩu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
