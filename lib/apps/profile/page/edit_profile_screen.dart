import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/common/config/api_config.dart';
import 'package:petpee_mobile/common/toast/app_toast.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _emailController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _ageController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  XFile? _newAvatar;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _emailController = TextEditingController(text: user?.email ?? '');
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _ageController = TextEditingController(text: user?.age?.toString() ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image == null || !mounted) return;

      setState(() {
        _newAvatar = image;
      });
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: 'Không thể mở ảnh: ${_formatError(e)}',
        type: AppToastType.error,
      );
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    final authProvider = context.read<AuthProvider>();
    final ageText = _ageController.text.trim();
    final passwordChanged = _hasPasswordInput;

    try {
      await authProvider.updateProfile(
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _emptyToNull(_addressController.text),
        age: ageText.isEmpty ? null : int.parse(ageText),
        currentPassword: passwordChanged
            ? _currentPasswordController.text
            : null,
        newPassword: passwordChanged ? _newPasswordController.text : null,
        avatar: _newAvatar,
      );

      if (!mounted) return;
      showAppToast(
        context,
        message: 'Cập nhật thông tin cá nhân thành công',
        type: AppToastType.success,
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      showAppToast(context, message: _formatError(e), type: AppToastType.error);
    }
  }

  bool get _hasPasswordInput {
    return _currentPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _formatError(Object error) {
    return error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final avatarUrl = ApiConfig.formatImageUrl(user?.avatarUrlPreview);
    final isLoading = authProvider.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Sửa thông tin cá nhân',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildAvatar(avatarUrl)),
              const SizedBox(height: 28),
              _buildSectionTitle('Thông tin cá nhân'),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Email',
                controller: _emailController,
                icon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Họ và tên',
                controller: _fullNameController,
                icon: LucideIcons.user,
                textInputAction: TextInputAction.next,
                validator: (value) => _validateRequired(value, 'Họ và tên'),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Số điện thoại',
                controller: _phoneController,
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (value) => _validateRequired(value, 'Số điện thoại'),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Tuổi',
                controller: _ageController,
                icon: LucideIcons.calendar,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: _validateAge,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Địa chỉ',
                controller: _addressController,
                icon: LucideIcons.mapPin,
                keyboardType: TextInputType.streetAddress,
                textInputAction: TextInputAction.next,
                maxLines: 2,
              ),
              const SizedBox(height: 28),
              _buildSectionTitle('Đổi mật khẩu'),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Mật khẩu hiện tại',
                controller: _currentPasswordController,
                icon: LucideIcons.lock,
                obscureText: _obscureCurrentPassword,
                textInputAction: TextInputAction.next,
                validator: _validateCurrentPassword,
                suffixIcon: _buildPasswordToggle(
                  isObscured: _obscureCurrentPassword,
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Mật khẩu mới',
                controller: _newPasswordController,
                icon: LucideIcons.keyRound,
                obscureText: _obscureNewPassword,
                textInputAction: TextInputAction.next,
                validator: _validateNewPassword,
                suffixIcon: _buildPasswordToggle(
                  isObscured: _obscureNewPassword,
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                label: 'Nhập lại mật khẩu mới',
                controller: _confirmPasswordController,
                icon: LucideIcons.shieldCheck,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                validator: _validateConfirmPassword,
                suffixIcon: _buildPasswordToggle(
                  isObscured: _obscureConfirmPassword,
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    disabledBackgroundColor: const Color(0xFF93C5FD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Lưu thay đổi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

  Widget _buildAvatar(String avatarUrl) {
    final hasNetworkAvatar = _newAvatar == null && avatarUrl.isNotEmpty;

    return GestureDetector(
      onTap: _showImageSourceActionSheet,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _newAvatar != null
                ? FileImage(File(_newAvatar!.path)) as ImageProvider
                : (hasNetworkAvatar ? NetworkImage(avatarUrl) : null),
            child: _newAvatar == null && !hasNetworkAvatar
                ? const Icon(LucideIcons.user, size: 50, color: Colors.grey)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF0288D1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.camera,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          obscureText: obscureText,
          maxLines: obscureText ? 1 : maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
              borderSide: const BorderSide(
                color: Color(0xFF0288D1),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordToggle({
    required bool isObscured,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: isObscured ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
      onPressed: onPressed,
      icon: Icon(
        isObscured ? LucideIcons.eye : LucideIcons.eyeOff,
        color: const Color(0xFF64748B),
        size: 18,
      ),
    );
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label không được để trống';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final requiredMessage = _validateRequired(value, 'Email');
    if (requiredMessage != null) return requiredMessage;

    final email = value!.trim();
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValid) return 'Email không đúng định dạng';
    return null;
  }

  String? _validateAge(String? value) {
    final ageText = value?.trim() ?? '';
    if (ageText.isEmpty) return null;

    final age = int.tryParse(ageText);
    if (age == null) return 'Tuổi phải là số';
    if (age < 0 || age > 150) return 'Tuổi phải từ 0 đến 150';
    return null;
  }

  String? _validateCurrentPassword(String? value) {
    if (!_hasPasswordInput) return null;
    if (value == null || value.isEmpty) {
      return 'Mật khẩu hiện tại không được để trống';
    }
    if (value.length < 6 || value.length > 32) {
      return 'Mật khẩu hiện tại phải có từ 6 đến 32 ký tự';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (!_hasPasswordInput) return null;
    if (value == null || value.isEmpty) {
      return 'Mật khẩu mới không được để trống';
    }
    if (value.length < 6 || value.length > 32) {
      return 'Mật khẩu mới phải có từ 6 đến 32 ký tự';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_hasPasswordInput) return null;
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập lại mật khẩu mới';
    }
    if (value != _newPasswordController.text) {
      return 'Mật khẩu mới không khớp';
    }
    return null;
  }
}
