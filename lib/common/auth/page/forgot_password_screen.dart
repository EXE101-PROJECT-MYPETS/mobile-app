import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pawly_mobile/common/auth/api/auth_service.dart';
import 'package:pawly_mobile/common/auth/model/auth_dto.dart';
import 'package:pawly_mobile/common/component/auth_text_field.dart';
import 'package:pawly_mobile/common/toast/app_toast.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyOtp = GlobalKey<FormState>();
  final _formKeyPassword = GlobalKey<FormState>();

  int _step = 1;
  bool _isLoading = false;
  int _otpCountdownSeconds = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startOtpCountdown(int seconds) {
    setState(() => _otpCountdownSeconds = seconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _otpCountdownSeconds--;
          if (_otpCountdownSeconds <= 0) {
            timer.cancel();
          }
        });
      }
    });
  }

  void _sendOtp() async {
    if (_formKeyEmail.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await _authService.forgotPassword(
          ForgotPasswordRequest(email: _emailController.text.trim()),
        );
        setState(() {
          _isLoading = false;
          _step = 2;
        });
        _startOtpCountdown(response.expiresInSeconds);
        if (mounted) {
          showAppToast(
            context,
            message: response.message,
            type: AppToastType.success,
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          showAppToast(
            context,
            message: e.toString().replaceAll('Exception: ', ''),
            type: AppToastType.error,
          );
        }
      }
    }
  }

  void _verifyOtp() async {
    if (_formKeyOtp.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.verifyOtpForgotPassword(
          VerifyOtpForgotPasswordRequest(
            email: _emailController.text.trim(),
            otp: _otpController.text.trim(),
          ),
        );
        setState(() {
          _isLoading = false;
          _step = 3;
        });
        if (mounted) {
          showAppToast(
            context,
            message: 'Mã OTP hợp lệ. Vui lòng nhập mật khẩu mới.',
            type: AppToastType.success,
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          showAppToast(
            context,
            message: e.toString().replaceAll('Exception: ', ''),
            type: AppToastType.error,
          );
        }
      }
    }
  }

  void _changePassword() async {
    if (_formKeyPassword.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.resetPassword(
          ResetPasswordRequest(
            email: _emailController.text.trim(),
            otp: _otpController.text.trim(),
            newPassword: _newPasswordController.text,
          ),
        );
        setState(() => _isLoading = false);
        if (mounted) {
          _showSuccessDialog();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          showAppToast(
            context,
            message: e.toString().replaceAll('Exception: ', ''),
            type: AppToastType.error,
          );
        }
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1F4E0),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: Color(0xFF10B981),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Đổi Mật Khẩu Thành Công',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Mật khẩu của bạn đã được cập nhật.\nVui lòng đăng nhập lại với mật khẩu mới.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Quay Lại Đăng Nhập',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Color(0xFF1E293B)),
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
                  ? 'Nhập email để nhận mã OTP khôi phục mật khẩu.'
                  : _step == 2
                  ? 'Nhập mã OTP được gửi đến email của bạn'
                  : 'Tạo mật khẩu mới cho tài khoản của bạn',
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
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
                  enabled: _step == 1,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!RegExp(
                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                    ).hasMatch(val)) {
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
                      : const Text(
                          'Gửi OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                    if (val == null || val.isEmpty) {
                      return 'Vui lòng nhập mã OTP';
                    }
                    if (val.length != 6) {
                      return 'Mã OTP phải là 6 chữ số';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (_otpCountdownSeconds > 0)
                Text(
                  'Mã OTP sẽ hết hạn trong: $_otpCountdownSeconds giây',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFDC2626),
                  ),
                ),
            ],

            if (_step == 2) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Xác nhận OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                      hintText: 'Nhập mật khẩu ít nhất 6 ký tự',
                      prefixIcon: LucideIcons.lock,
                      isPassword: true,
                      controller: _newPasswordController,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        if (val.length < 6) return 'Tối thiểu 6 ký tự';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      label: 'Xác nhận mật khẩu mới',
                      hintText: 'Nhập lại mật khẩu',
                      prefixIcon: LucideIcons.lock,
                      isPassword: true,
                      controller: _confirmPasswordController,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Vui lòng xác nhận mật khẩu';
                        }
                        if (val != _newPasswordController.text) {
                          return 'Mật khẩu không khớp';
                        }
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
                      : const Text(
                          'Đổi Mật Khẩu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
