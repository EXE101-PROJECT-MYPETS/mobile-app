import 'dart:math' as math;

import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/apps/home/page/home_screen.dart';
import 'package:petpee_mobile/common/auth/page/forgot_password_screen.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/common/component/auth_text_field.dart';
import 'package:petpee_mobile/common/config/api_config.dart';
import 'package:petpee_mobile/common/toast/app_toast.dart';
import 'package:provider/provider.dart';

class PetpeesApp extends StatelessWidget {
  const PetpeesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Petpee Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4F8B),
          primary: const Color(0xFFFF4F8B),
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  String? _socialLoginProvider;

  String? get _googleServerClientId {
    final clientId = ApiConfig.googleWebClientId.trim();
    return clientId.isEmpty ? null : clientId;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin(AuthProvider authProvider) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
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

  Future<void> _handleGoogleSignIn(AuthProvider authProvider) async {
    if (_socialLoginProvider != null) {
      return;
    }

    setState(() {
      _socialLoginProvider = 'google';
    });

    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: _googleServerClientId,
      );
      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return;
      }

      final authentication = await googleUser.authentication;
      final idToken = authentication.idToken;

      if (idToken == null) {
        if (!mounted) return;
        showAppToast(
          context,
          message:
              'Không thể lấy token từ Google. Vui lòng kiểm tra GOOGLE_WEB_CLIENT_ID.',
          type: AppToastType.error,
        );
        return;
      }

      await authProvider.googleLogin(idToken);

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      showAppToast(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _socialLoginProvider = null;
        });
      }
    }
  }

  Future<void> _handleFacebookSignIn(AuthProvider authProvider) async {
    if (_socialLoginProvider != null) {
      return;
    }

    setState(() {
      _socialLoginProvider = 'facebook';
    });

    try {
      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
        loginTracking: LoginTracking.enabled,
      );

      if (result.status == LoginStatus.cancelled) {
        return;
      }

      if (result.status == LoginStatus.operationInProgress) {
        if (!mounted) {
          return;
        }

        showAppToast(
          context,
          message: 'Đăng nhập Facebook đang được xử lý',
          type: AppToastType.info,
        );
        return;
      }

      if (result.status != LoginStatus.success) {
        throw Exception(result.message ?? 'Đăng nhập Facebook thất bại');
      }

      final accessToken = result.accessToken?.tokenString;
      if (accessToken == null || accessToken.isEmpty) {
        if (!mounted) {
          return;
        }

        showAppToast(
          context,
          message: 'Không thể lấy token từ Facebook',
          type: AppToastType.error,
        );
        return;
      }

      await authProvider.facebookLogin(accessToken);

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      showAppToast(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _socialLoginProvider = null;
        });
      }
    }
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
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _LoginHero(),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Đăng nhập',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF1F2937),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 24),
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
                                    if (!RegExp(
                                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                    ).hasMatch(email)) {
                                      return 'Email không đúng định dạng';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                CustomTextField(
                                  controller: _passwordController,
                                  label: 'Mật khẩu',
                                  hintText: 'Nhập mật khẩu',
                                  prefixIcon: LucideIcons.lock,
                                  isPassword: true,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) {
                                    final authProvider = context
                                        .read<AuthProvider>();
                                    if (!authProvider.isLoading) {
                                      _submitLogin(authProvider);
                                    }
                                  },
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
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                        side: const BorderSide(
                                          color: Color(0xFFD8DEE7),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        activeColor: const Color(0xFFFF4F8B),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Ghi nhớ đăng nhập',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF5E6876),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFFFF4F8B,
                                        ),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        minimumSize: Size.zero,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 0,
                                          vertical: 6,
                                        ),
                                      ),
                                      child: Text(
                                        'Quên mật khẩu?',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, child) {
                                    return SizedBox(
                                      height: 42,
                                      child: ElevatedButton(
                                        onPressed: authProvider.isLoading
                                            ? null
                                            : () => _submitLogin(authProvider),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0A94E8,
                                          ),
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: const Color(
                                            0xFF9ECBE8,
                                          ),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: authProvider.isLoading
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(
                                                'Đăng nhập',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 18),
                                const _DividerLabel(label: 'hoặc'),
                                const SizedBox(height: 16),
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, child) {
                                    final socialEnabled =
                                        !authProvider.isLoading &&
                                        _socialLoginProvider == null;
                                    final googleLoading =
                                        _socialLoginProvider == 'google';
                                    final facebookLoading =
                                        _socialLoginProvider == 'facebook';

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _SocialButton(
                                          providerName: 'Google',
                                          label: 'Đăng nhập với Google',
                                          brandIcon: const _GoogleMark(),
                                          enabled: socialEnabled,
                                          isLoading: googleLoading,
                                          onPressed: () =>
                                              _handleGoogleSignIn(authProvider),
                                        ),
                                        const SizedBox(height: 8),
                                        _SocialButton(
                                          providerName: 'Facebook',
                                          label: 'Đăng nhập với Facebook',
                                          icon: Icons.facebook,
                                          iconColor: const Color(0xFF1877F2),
                                          enabled: socialEnabled,
                                          isLoading: facebookLoading,
                                          onPressed: () =>
                                              _handleFacebookSignIn(
                                                authProvider,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        _SocialButton(
                                          providerName: 'Apple',
                                          label: 'Đăng nhập với Apple',
                                          icon: Icons.apple,
                                          iconColor: Colors.black,
                                          enabled: socialEnabled,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const Spacer(),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 20,
                                    bottom: 10,
                                  ),
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/register',
                                      ),
                                      child: RichText(
                                        text: TextSpan(
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF8D99A8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          children: const [
                                            TextSpan(
                                              text: 'Chưa có tài khoản? ',
                                            ),
                                            TextSpan(
                                              text: 'Đăng ký',
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _LoginHeroPainter()),
          Positioned(
            left: -6,
            top: MediaQuery.paddingOf(context).top - 2,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              color: Color(0xFFFF4F8B),
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
                  'PETPEE',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFF4F8B),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sàn thú cưng',
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

class _LoginHeroPainter extends CustomPainter {
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

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE8ECF1), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF9AA4B2),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE8ECF1), height: 1)),
      ],
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.19;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    Paint arcPaint(Color color) {
      return Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.square;
    }

    double radians(double degrees) => degrees * math.pi / 180;

    canvas.drawArc(rect, radians(-38), radians(74), false, arcPaint(_blue));
    canvas.drawArc(rect, radians(-145), radians(105), false, arcPaint(_red));
    canvas.drawArc(rect, radians(145), radians(72), false, arcPaint(_yellow));
    canvas.drawArc(rect, radians(42), radians(103), false, arcPaint(_green));

    final barPaint = arcPaint(_blue)..strokeCap = StrokeCap.square;
    final centerY = size.height * 0.51;
    canvas.drawLine(
      Offset(size.width * 0.53, centerY),
      Offset(size.width * 0.92, centerY),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.providerName,
    required this.label,
    this.icon,
    this.iconColor = Colors.black,
    this.brandIcon,
    this.onPressed,
    this.enabled = true,
    this.isLoading = false,
  });

  final String providerName;
  final String label;
  final IconData? icon;
  final Color iconColor;
  final Widget? brandIcon;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: OutlinedButton(
        onPressed: enabled && !isLoading
            ? onPressed ??
                  () {
                    showAppToast(
                      context,
                      message: '$providerName chưa được cấu hình',
                      type: AppToastType.info,
                    );
                  }
            : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2F3744),
          side: const BorderSide(color: Color(0xFFE4E8EF)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF4F8B),
                        ),
                      )
                    : brandIcon ?? Icon(icon, color: iconColor, size: 20),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF2F3744),
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
