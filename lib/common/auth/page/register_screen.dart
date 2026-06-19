import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pawly_mobile/common/address/vietnam_address_service.dart';
import 'package:pawly_mobile/common/auth/store/auth_provider.dart';
import 'package:pawly_mobile/common/component/auth_text_field.dart';
import 'package:pawly_mobile/common/toast/app_toast.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const int _resendCooldownSeconds = 60;

  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _provinceController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _ageController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _step = 1;
  int? _provinceCode;
  int? _districtCode;
  bool _agreeTerms = false;
  bool _isEmailVerified = false;
  int _resendCooldown = 0;
  Timer? _resendCooldownTimer;
  XFile? _avatar;
  final ImagePicker _picker = ImagePicker();
  final VietnamAddressService _addressService = VietnamAddressService();

  @override
  void dispose() {
    _resendCooldownTimer?.cancel();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _ageController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendCooldownTimer?.cancel();
    setState(() {
      _resendCooldown = _resendCooldownSeconds;
    });

    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() {
          _resendCooldown = 0;
        });
        return;
      }

      setState(() {
        _resendCooldown -= 1;
      });
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _avatar = image;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      showAppToast(
        context,
        message: 'Không thể mở: $e',
        type: AppToastType.error,
      );
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    LucideIcons.image,
                    color: Color(0xFFFF4F8B),
                  ),
                  title: const Text('Chọn từ thư viện'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    LucideIcons.camera,
                    color: Color(0xFFFF4F8B),
                  ),
                  title: const Text('Chụp ảnh mới'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _goToOtpStep() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.sendRegisterVerificationCode(
        _emailController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _step = 2;
        _isEmailVerified = false;
      });

      _startResendCooldown();
      _showOtpSentToast();
    } catch (e) {
      if (!mounted) {
        return;
      }

      showAppToast(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        type: AppToastType.error,
      );
    }
  }

  void _showOtpSentToast() {
    showAppToast(
      context,
      message: 'Mã xác nhận đã được gửi tới ${_emailController.text.trim()}',
      type: AppToastType.success,
    );
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.sendRegisterVerificationCode(
        _emailController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      _startResendCooldown();
      _showOtpSentToast();
    } catch (e) {
      if (!mounted) {
        return;
      }

      showAppToast(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        type: AppToastType.error,
      );
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.verifyRegisterVerificationCode(
        email: _emailController.text.trim(),
        code: _otpController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _step = 3;
        _isEmailVerified = true;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      showAppToast(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        type: AppToastType.error,
      );
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeTerms) {
      showAppToast(
        context,
        message: 'Vui lòng đồng ý với điều khoản',
        type: AppToastType.warning,
      );
      return;
    }

    if (!_isEmailVerified) {
      showAppToast(
        context,
        message: 'Vui lòng xác thực email trước khi tạo tài khoản',
        type: AppToastType.warning,
      );
      return;
    }

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        province: _provinceController.text.trim(),
        district: _districtController.text.trim(),
        ward: _wardController.text.trim(),
        hamlet: _addressController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        avatar: _avatar,
      );

      if (!mounted) {
        return;
      }

      showAppToast(
        context,
        message: 'Đăng ký thành công!',
        type: AppToastType.success,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      showAppToast(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        type: AppToastType.error,
      );
    }
  }

  void _handleBack() {
    if (_step > 1) {
      setState(() {
        _step -= 1;
      });
      return;
    }

    Navigator.maybePop(context);
  }

  String? _requiredField(String? value, String fieldName) {
    if ((value ?? '').trim().isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    return null;
  }

  Future<void> _selectProvince() async {
    final selected = await _showAddressSelectionSheet(
      title: 'Chọn tỉnh/thành phố',
      loader: _addressService.fetchProvinces,
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _provinceCode = selected.code;
      _districtCode = null;
      _provinceController.text = selected.name;
      _districtController.clear();
      _wardController.clear();
    });
  }

  Future<void> _selectDistrict() async {
    final provinceCode = _provinceCode;
    if (provinceCode == null) {
      showAppToast(
        context,
        message: 'Vui lòng chọn tỉnh/thành phố trước',
        type: AppToastType.warning,
      );
      return;
    }

    final selected = await _showAddressSelectionSheet(
      title: 'Chọn quận/huyện',
      loader: () => _addressService.fetchDistricts(provinceCode),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _districtCode = selected.code;
      _districtController.text = selected.name;
      _wardController.clear();
    });
  }

  Future<void> _selectWard() async {
    final districtCode = _districtCode;
    if (districtCode == null) {
      showAppToast(
        context,
        message: 'Vui lòng chọn quận/huyện trước',
        type: AppToastType.warning,
      );
      return;
    }

    final selected = await _showAddressSelectionSheet(
      title: 'Chọn phường/xã',
      loader: () => _addressService.fetchWards(districtCode),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _wardController.text = selected.name;
    });
  }

  Future<VietnamAddressUnit?> _showAddressSelectionSheet({
    required String title,
    required Future<List<VietnamAddressUnit>> Function() loader,
  }) {
    return showModalBottomSheet<VietnamAddressUnit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return _AddressSelectionSheet(title: title, loader: loader);
      },
    );
  }

  List<Widget> _buildStepFields(BuildContext context) {
    return [
      Text(
        'Đăng ký',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: const Color(0xFF1F2937),
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      _StepCaption(step: _step),
      const SizedBox(height: 18),
      if (_step == 1) ..._buildProfileStep(),
      if (_step == 2) ..._buildOtpStep(),
      if (_step == 3) ..._buildPasswordStep(),
      Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 10),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  color: const Color(0xFF8D99A8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                children: const [
                  TextSpan(text: 'Đã có tài khoản? '),
                  TextSpan(
                    text: 'Đăng nhập',
                    style: TextStyle(
                      color: Color(0xFFFF4F8B),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildProfileStep() {
    return [
      _AvatarPicker(avatar: _avatar, onPickImage: _showImageSourceActionSheet),
      const SizedBox(height: 24),
      CustomTextField(
        controller: _fullNameController,
        label: 'Họ và tên',
        hintText: 'Nhập họ và tên',
        prefixIcon: LucideIcons.user,
        textInputAction: TextInputAction.next,
        validator: (value) {
          return _requiredField(value, 'họ và tên');
        },
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _emailController,
        label: 'Email',
        hintText: 'Nhập email',
        prefixIcon: LucideIcons.mail,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        validator: (value) {
          final email = value?.trim() ?? '';
          if (email.isEmpty) {
            return 'Vui lòng nhập email';
          }
          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
            return 'Email không đúng định dạng';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: CustomTextField(
              controller: _phoneController,
              label: 'Số điện thoại',
              hintText: 'Nhập số điện thoại',
              prefixIcon: LucideIcons.phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: (value) {
                return _requiredField(value, 'số điện thoại');
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: CustomTextField(
              controller: _ageController,
              label: 'Tuổi',
              hintText: 'Tuổi',
              prefixIcon: LucideIcons.calendar,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _addressController,
        label: 'Số nhà và tên đường',
        hintText: 'Nhập số nhà và tên đường',
        prefixIcon: LucideIcons.map_pin,
        textInputAction: TextInputAction.next,
        validator: (value) {
          return _requiredField(value, 'số nhà và tên đường');
        },
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _provinceController,
        label: 'Tỉnh/thành phố',
        hintText: 'Chọn tỉnh/thành phố',
        prefixIcon: LucideIcons.map,
        suffixIcon: LucideIcons.chevron_down,
        readOnly: true,
        onTap: _selectProvince,
        textInputAction: TextInputAction.next,
        validator: (value) {
          return _requiredField(value, 'tỉnh/thành phố');
        },
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _districtController,
        label: 'Quận/huyện',
        hintText: 'Chọn quận/huyện',
        prefixIcon: LucideIcons.building_2,
        suffixIcon: LucideIcons.chevron_down,
        readOnly: true,
        onTap: _selectDistrict,
        textInputAction: TextInputAction.next,
        validator: (value) {
          return _requiredField(value, 'quận/huyện');
        },
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _wardController,
        label: 'Phường/xã',
        hintText: 'Chọn phường/xã',
        prefixIcon: LucideIcons.map_pin,
        suffixIcon: LucideIcons.chevron_down,
        readOnly: true,
        onTap: _selectWard,
        textInputAction: TextInputAction.done,
        validator: (value) {
          return _requiredField(value, 'phường/xã');
        },
      ),
      const SizedBox(height: 24),
      Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return _PrimaryActionButton(
            label: 'Bước tiếp theo',
            isLoading: authProvider.isLoading,
            onPressed: _goToOtpStep,
          );
        },
      ),
    ];
  }

  List<Widget> _buildOtpStep() {
    return [
      _EmailVerificationNote(email: _emailController.text.trim()),
      const SizedBox(height: 18),
      CustomTextField(
        controller: _otpController,
        label: 'Mã xác nhận',
        hintText: 'Nhập mã 6 số',
        prefixIcon: LucideIcons.key,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _verifyOtp(),
        validator: (value) {
          final code = value?.trim() ?? '';
          if (code.isEmpty) {
            return 'Vui lòng nhập mã xác nhận';
          }
          if (code.length != 6) {
            return 'Mã xác nhận gồm 6 số';
          }
          return null;
        },
      ),
      const SizedBox(height: 24),
      Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return _PrimaryActionButton(
            label: 'Xác nhận mã',
            isLoading: authProvider.isLoading,
            onPressed: _verifyOtp,
          );
        },
      ),
      const SizedBox(height: 10),
      Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final canResend = !authProvider.isLoading && _resendCooldown == 0;

          return TextButton(
            onPressed: canResend ? _resendOtp : null,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFFF4F8B),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _resendCooldown > 0
                  ? 'Gửi lại mã ($_resendCooldown s)'
                  : 'Gửi lại mã',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildPasswordStep() {
    return [
      CustomTextField(
        controller: _passwordController,
        label: 'Mật khẩu',
        hintText: 'Nhập mật khẩu',
        prefixIcon: LucideIcons.lock,
        isPassword: true,
        textInputAction: TextInputAction.next,
        validator: (value) {
          final password = value ?? '';
          if (password.isEmpty) {
            return 'Vui lòng nhập mật khẩu';
          }
          if (password.length < 6) {
            return 'Mật khẩu phải có ít nhất 6 ký tự';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _confirmPasswordController,
        label: 'Xác nhận mật khẩu',
        hintText: 'Nhập lại mật khẩu',
        prefixIcon: LucideIcons.lock,
        isPassword: true,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) {
          final authProvider = context.read<AuthProvider>();
          if (!authProvider.isLoading) {
            _handleRegister();
          }
        },
        validator: (value) {
          if ((value ?? '').isEmpty) {
            return 'Vui lòng xác nhận mật khẩu';
          }
          if (value != _passwordController.text) {
            return 'Mật khẩu không khớp';
          }
          return null;
        },
      ),
      const SizedBox(height: 14),
      _TermsRow(
        value: _agreeTerms,
        onChanged: (value) {
          setState(() {
            _agreeTerms = value ?? false;
          });
        },
      ),
      const SizedBox(height: 24),
      Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return _PrimaryActionButton(
            label: 'Tạo tài khoản',
            isLoading: authProvider.isLoading,
            onPressed: () {
              _handleRegister();
            },
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RegisterHero(onBack: _handleBack),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildStepFields(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StepCaption extends StatelessWidget {
  const _StepCaption({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final label = switch (step) {
      1 => 'Bước 1/3: Thông tin cá nhân',
      2 => 'Bước 2/3: Xác nhận email',
      3 => 'Bước 3/3: Tạo mật khẩu',
      _ => 'Bước 1/3',
    };

    return Text(
      label,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: const Color(0xFF8D99A8),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EmailVerificationNote extends StatelessWidget {
  const _EmailVerificationNote({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.mail_check,
            color: Color(0xFFFF4F8B),
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nhập mã xác nhận đã gửi tới $email',
              style: GoogleFonts.inter(
                color: const Color(0xFF344054),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressSelectionSheet extends StatefulWidget {
  const _AddressSelectionSheet({required this.title, required this.loader});

  final String title;
  final Future<List<VietnamAddressUnit>> Function() loader;

  @override
  State<_AddressSelectionSheet> createState() => _AddressSelectionSheetState();
}

class _AddressSelectionSheetState extends State<_AddressSelectionSheet> {
  final _searchController = TextEditingController();
  late Future<List<VietnamAddressUnit>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {
      _query = _searchController.text.trim().toLowerCase();
    });
  }

  void _reload() {
    setState(() {
      _future = widget.loader();
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.78;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E7EE),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F2937),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF667085),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFF9AA4B2),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    color: Color(0xFFFF4F8B),
                    size: 18,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E7EE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E7EE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF6D9B),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<VietnamAddressUnit>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF4F8B),
                        strokeWidth: 2.4,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _AddressSheetMessage(
                      icon: Icons.cloud_off_rounded,
                      message: 'Không tải được danh sách địa chỉ',
                      actionLabel: 'Thử lại',
                      onAction: _reload,
                    );
                  }

                  final units = snapshot.data ?? [];
                  final visibleUnits = _query.isEmpty
                      ? units
                      : units
                          .where(
                            (unit) => unit.name.toLowerCase().contains(_query),
                          )
                          .toList();

                  if (visibleUnits.isEmpty) {
                    return const _AddressSheetMessage(
                      icon: LucideIcons.search,
                      message: 'Không tìm thấy địa chỉ phù hợp',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: visibleUnits.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFF1F4F8)),
                    itemBuilder: (context, index) {
                      final unit = visibleUnits[index];
                      return ListTile(
                        onTap: () => Navigator.pop(context, unit),
                        minLeadingWidth: 34,
                        leading: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF4F8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.map_pin,
                            color: Color(0xFFFF4F8B),
                            size: 17,
                          ),
                        ),
                        title: Text(
                          unit.name,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF1F2937),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFB7C0CC),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressSheetMessage extends StatelessWidget {
  const _AddressSheetMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF929AA5), size: 32),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF667085),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF4F8B),
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
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

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0A94E8),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9ECBE8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

class _RegisterHero extends StatelessWidget {
  const _RegisterHero({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _RegisterHeroPainter()),
          Positioned(
            left: -6,
            top: MediaQuery.paddingOf(context).top - 2,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: const Color(0xFFFF4F8B),
              iconSize: 32,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 48, height: 48),
              splashRadius: 24,
            ),
          ),
          Positioned(
            left: 28,
            top: MediaQuery.paddingOf(context).top + 38,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAWLY',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFF4F8B),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pet Marketplace',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF7A8391),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD7E5), Color(0xFFFFF4F8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    final bgPath = Path()
      ..lineTo(0, size.height * 0.79)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 1.04,
        size.width,
        size.height * 0.66,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(bgPath, bgPaint);

    final curvePaint = Paint()
      ..color = const Color(0xFFFF7DA7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final curvePath = Path()
      ..moveTo(0, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.54,
        size.height * 1.02,
        size.width,
        size.height * 0.66,
      );
    canvas.drawPath(curvePath, curvePaint);

    _drawDogOutline(canvas, size);
    _drawPaw(canvas, Offset(size.width * 0.27, size.height * 0.19), 8);
    _drawPaw(canvas, Offset(size.width * 0.52, size.height * 0.54), 11);
    _drawPaw(canvas, Offset(size.width * 0.94, size.height * 0.30), 10);
  }

  void _drawDogOutline(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.60, size.height * 0.45)
      ..quadraticBezierTo(
        size.width * 0.64,
        size.height * 0.32,
        size.width * 0.71,
        size.height * 0.28,
      )
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.20,
        size.width * 0.82,
        size.height * 0.30,
      )
      ..quadraticBezierTo(
        size.width * 0.90,
        size.height * 0.40,
        size.width * 0.90,
        size.height * 0.58,
      )
      ..quadraticBezierTo(
        size.width * 0.82,
        size.height * 0.55,
        size.width * 0.76,
        size.height * 0.43,
      )
      ..quadraticBezierTo(
        size.width * 0.73,
        size.height * 0.54,
        size.width * 0.78,
        size.height * 0.63,
      );

    canvas.drawPath(path, paint);
  }

  void _drawPaw(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFFFFB9CF).withValues(alpha: 0.3);

    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, radius * 0.35),
        width: radius * 1.2,
        height: radius * 0.95,
      ),
      paint,
    );
    canvas.drawCircle(
      center.translate(-radius * 0.72, -radius * 0.2),
      radius * 0.35,
      paint,
    );
    canvas.drawCircle(
      center.translate(-radius * 0.22, -radius * 0.65),
      radius * 0.35,
      paint,
    );
    canvas.drawCircle(
      center.translate(radius * 0.32, -radius * 0.6),
      radius * 0.35,
      paint,
    );
    canvas.drawCircle(
      center.translate(radius * 0.76, -radius * 0.12),
      radius * 0.35,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.avatar, required this.onPickImage});

  final XFile? avatar;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onPickImage,
        customBorder: const CircleBorder(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  padding: const EdgeInsets.all(1.4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E7EE),
                      width: 1.4,
                    ),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipOval(
                      child: avatar != null
                          ? Image.file(File(avatar!.path), fit: BoxFit.cover)
                          : Container(
                              color: const Color(0xFFFAFBFC),
                              child: const Icon(
                                LucideIcons.user,
                                color: Colors.black,
                                size: 42,
                              ),
                            ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 6,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE2E7EE),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      color: Colors.black,
                      size: 17,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              avatar != null ? 'Đổi ảnh đại diện' : 'Thêm ảnh đại diện',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            side: const BorderSide(color: Color(0xFFD8DEE7)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            activeColor: const Color(0xFFFF4F8B),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                color: const Color(0xFF5E6876),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              children: const [
                TextSpan(text: 'Tôi đồng ý với '),
                TextSpan(
                  text: 'điều khoản và chính sách bảo mật',
                  style: TextStyle(
                    color: Color(0xFFFF4F8B),
                    fontWeight: FontWeight.w800,
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
