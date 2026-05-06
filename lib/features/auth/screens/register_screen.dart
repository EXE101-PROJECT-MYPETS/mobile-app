import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _agreeTerms = false;
  XFile? _avatar;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _avatar = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(LucideIcons.image),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.camera),
                title: const Text('Chụp ảnh mới'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreeTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đồng ý với điều khoản'), backgroundColor: Colors.red),
        );
        return;
      }

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          age: int.tryParse(_ageController.text.trim()),
          avatar: _avatar,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đăng ký thành công!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context); // Quay về màn đăng nhập
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Hàng 1: Họ tên & Email
                        Row(
                          children: [
                            Expanded(
                              child: _CustomTextField(
                                label: 'Họ và tên',
                                hintText: 'Nguyễn Văn A',
                                prefixIcon: LucideIcons.user,
                                isRequired: true,
                                controller: _fullNameController,
                                validator: (val) => (val == null || val.isEmpty) ? 'Bắt buộc' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CustomTextField(
                                label: 'Email',
                                hintText: 'sonledz22cm@gr',
                                prefixIcon: LucideIcons.mail,
                                isRequired: true,
                                controller: _emailController,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Bắt buộc';
                                  if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(val)) {
                                    return 'Sai định dạng';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Hàng 2: Số điện thoại
                        _CustomTextField(
                          label: 'Số điện thoại',
                          hintText: '0900000000',
                          prefixIcon: LucideIcons.phone,
                          isRequired: true,
                          keyboardType: TextInputType.phone,
                          controller: _phoneController,
                          validator: (val) => (val == null || val.isEmpty) ? 'Bắt buộc' : null,
                        ),
                        const SizedBox(height: 16),

                        // Hàng 3: Địa chỉ & Tuổi
                        Row(
                          children: [
                            Expanded(
                              child: _CustomTextField(
                                label: 'Địa chỉ',
                                hintText: 'Ví dụ: 123 Nguyễn...',
                                prefixIcon: LucideIcons.mapPin,
                                controller: _addressController,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CustomTextField(
                                label: 'Tuổi',
                                hintText: 'Ví dụ: 20',
                                prefixIcon: LucideIcons.calendar,
                                keyboardType: TextInputType.number,
                                controller: _ageController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Hàng 4: Ảnh đại diện
                        _AvatarPicker(
                          avatar: _avatar,
                          onPickImage: _showImageSourceActionSheet,
                        ),
                        const SizedBox(height: 16),

                        // Hàng 5: Mật khẩu & Xác nhận
                        Row(
                          children: [
                            Expanded(
                              child: _CustomTextField(
                                label: 'Mật khẩu',
                                hintText: '****',
                                prefixIcon: LucideIcons.lock,
                                isPassword: true,
                                isRequired: true,
                                controller: _passwordController,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Bắt buộc';
                                  if (val.length < 6) return '>= 6 ký tự';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _CustomTextField(
                                label: 'Xác nhận',
                                hintText: 'Nhập lại',
                                prefixIcon: LucideIcons.lock,
                                isPassword: true,
                                isRequired: true,
                                controller: _confirmPasswordController,
                                validator: (val) {
                                  if (val == null || val.isEmpty) return 'Bắt buộc';
                                  if (val != _passwordController.text) return 'Không khớp';
                                  return null;
                                },
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
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            return SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A90E2),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                  elevation: 0,
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('Tạo tài khoản', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ),
                            );
                          },
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

class _CustomTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final bool isRequired;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const _CustomTextField({
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.isRequired = false,
    this.keyboardType,
    this.controller,
    this.validator,
  });

  @override
  State<_CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<_CustomTextField> {
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: widget.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            children: widget.isRequired ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : [],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: _isObscured,
          keyboardType: widget.keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(widget.prefixIcon, color: const Color(0xFFFB7185).withOpacity(0.7), size: 16),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _isObscured ? LucideIcons.eyeOff : LucideIcons.eye,
                      color: const Color(0xFF94A3B8),
                      size: 16,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            isDense: true,
            errorStyle: const TextStyle(color: Colors.red, fontSize: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0288D1), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final XFile? avatar;
  final VoidCallback onPickImage;

  const _AvatarPicker({this.avatar, required this.onPickImage});

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
        GestureDetector(
          onTap: onPickImage,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (avatar != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      File(avatar!.path),
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                ] else ...[
                  const Icon(LucideIcons.userCircle, color: Color(0xFF94A3B8), size: 24),
                ],
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
                Expanded(
                  child: Text(
                    avatar != null ? avatar!.name : 'Sẽ dùng ảnh mặc định',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}