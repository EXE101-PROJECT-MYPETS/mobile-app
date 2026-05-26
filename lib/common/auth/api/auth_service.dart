import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:petpee_mobile/common/auth/model/auth_dto.dart';
import 'package:petpee_mobile/common/config/api_config.dart';
import 'package:petpee_mobile/common/user/model/user_model.dart';

class AuthService {
  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  Future<EmailVerificationResponse> sendRegisterVerificationCode(
    RegisterEmailVerificationSendRequest request,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.registerEmailSendCodeUrl),
      headers: _jsonHeaders,
      body: jsonEncode(request.toJson()),
    );

    final body = _decodeResponse(response);
    if (_isSuccess(response.statusCode)) {
      return EmailVerificationResponse.fromJson(body);
    }

    throw Exception(_extractErrorMessage(body, 'Gửi mã xác thực thất bại'));
  }

  Future<EmailVerificationResponse> verifyRegisterVerificationCode(
    RegisterEmailVerificationVerifyRequest request,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.registerEmailVerifyCodeUrl),
      headers: _jsonHeaders,
      body: jsonEncode(request.toJson()),
    );

    final body = _decodeResponse(response);
    if (_isSuccess(response.statusCode)) {
      return EmailVerificationResponse.fromJson(body);
    }

    throw Exception(_extractErrorMessage(body, 'Xác thực mã thất bại'));
  }

  Future<UserLoginResponse> login(AuthenticationRequest request) async {
    final response = await http.post(
      Uri.parse(ApiConfig.customerLoginUrl),
      headers: _jsonHeaders,
      body: jsonEncode(request.toJson()),
    );

    final body = _decodeResponse(response);
    if (_isSuccess(response.statusCode)) {
      return UserLoginResponse.fromJson(body);
    }

    throw Exception(_extractErrorMessage(body, 'Đăng nhập thất bại'));
  }

  Future<UserLoginResponse> refreshToken(String refreshToken) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.authUrl}/refreshToken'),
      headers: _jsonHeaders,
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    final body = _decodeResponse(response);
    if (_isSuccess(response.statusCode)) {
      return UserLoginResponse.fromJson(body);
    }

    throw Exception(
      _extractErrorMessage(body, 'Làm mới phiên đăng nhập thất bại'),
    );
  }

  Future<UserLoginResponse> register(RegisterRequest registerRequest) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.registerUrl),
    );
    request.headers['ngrok-skip-browser-warning'] = 'true';

    request.fields.addAll(registerRequest.toMultipartFields());

    final avatarUrlPreview = registerRequest.avatarUrlPreview;
    if (avatarUrlPreview != null) {
      final mimeType = avatarUrlPreview.mimeType ?? 'image/jpeg';
      final type = mimeType.split('/')[0];
      final subtype = mimeType.split('/').length > 1
          ? mimeType.split('/')[1]
          : 'jpeg';

      request.files.add(
        await http.MultipartFile.fromPath(
          'avatarUrlPreview',
          avatarUrlPreview.path,
          contentType: MediaType(type, subtype),
        ),
      );
    }

    final response = await request.send();
    final responseBytes = await response.stream.toBytes();
    final responseData = utf8.decode(responseBytes);
    final body = _decodeTextResponse(responseData);

    if (_isSuccess(response.statusCode)) {
      return UserLoginResponse.fromJson(body);
    }

    throw Exception(_extractErrorMessage(body, 'Đăng ký thất bại'));
  }

  Future<UserModel> getCurrentUserProfile({required String accessToken}) async {
    final response = await http.get(
      Uri.parse(ApiConfig.currentUserProfileUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'ngrok-skip-browser-warning': 'true',
      },
    );

    final body = _decodeResponse(response);
    if (_isSuccess(response.statusCode)) {
      return UserModel.fromJson(body);
    }

    throw Exception(_extractErrorMessage(body, 'Tải hồ sơ thất bại'));
  }

  Future<UserModel> updateCurrentUserProfile({
    required UpdateProfileRequest updateRequest,
    required String accessToken,
  }) async {
    final request = http.MultipartRequest(
      'PATCH',
      Uri.parse(ApiConfig.currentUserProfileUrl),
    );

    request.headers.addAll({
      'Authorization': 'Bearer $accessToken',
      'Bypass-Tunnel-Reminder': 'true',
    });
    request.fields.addAll(updateRequest.toMultipartFields());

    final avatarUrlPreview = updateRequest.avatarUrlPreview;
    if (avatarUrlPreview != null) {
      final mimeType = avatarUrlPreview.mimeType ?? 'image/jpeg';
      final type = mimeType.split('/')[0];
      final subtype = mimeType.split('/').length > 1
          ? mimeType.split('/')[1]
          : 'jpeg';

      request.files.add(
        await http.MultipartFile.fromPath(
          'avatarUrlPreview',
          avatarUrlPreview.path,
          contentType: MediaType(type, subtype),
        ),
      );
    }

    final response = await request.send();
    final responseBytes = await response.stream.toBytes();
    final responseData = utf8.decode(responseBytes);
    final body = _decodeTextResponse(responseData);

    if (_isSuccess(response.statusCode)) {
      return UserModel.fromJson(body);
    }

    throw Exception(_extractErrorMessage(body, 'Cập nhật hồ sơ thất bại'));
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> _decodeResponse(http.Response response) {
    return _decodeTextResponse(utf8.decode(response.bodyBytes));
  }

  Map<String, dynamic> _decodeTextResponse(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(responseBody);
    } catch (_) {
      return {'message': responseBody.trim()};
    }

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return const <String, dynamic>{};
  }

  String _extractErrorMessage(
    Map<String, dynamic> body,
    String fallbackMessage,
  ) {
    return (body['message'] as String?) ??
        (body['error'] as String?) ??
        fallbackMessage;
  }

  // ── Forgot Password Flow ────────────────────────────────────────────

  Future<ForgotPasswordResponse> forgotPassword(
    ForgotPasswordRequest request,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.authUrl}/customer/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final body = _decodeResponse(response);
    if (_isSuccess(response.statusCode)) {
      return ForgotPasswordResponse.fromJson(body);
    }

    throw Exception(_extractErrorMessage(body, 'Gửi mã OTP thất bại'));
  }

  Future<void> verifyOtpForgotPassword(
    VerifyOtpForgotPasswordRequest request,
  ) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.authUrl}/customer/verify-otp-forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final body = _decodeResponse(response);
    if (!_isSuccess(response.statusCode)) {
      throw Exception(_extractErrorMessage(body, 'Xác thực OTP thất bại'));
    }
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.authUrl}/customer/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final body = _decodeResponse(response);
    if (!_isSuccess(response.statusCode)) {
      throw Exception(_extractErrorMessage(body, 'Đặt lại mật khẩu thất bại'));
    }
  }

  // ── Google Sign-In ────────────────────────────────────────────

  Future<UserLoginResponse> googleLogin(GoogleLoginRequest request) async {
    final response = await http.post(
      Uri.parse(ApiConfig.customerGoogleLoginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final body = _decodeResponse(response);
    if (_isSuccess(response.statusCode)) {
      return UserLoginResponse.fromJson(body);
    }

    throw Exception(_extractErrorMessage(body, 'Đăng nhập Google thất bại'));
  }

  Future<UserLoginResponse> facebookLogin(FacebookLoginRequest request) async {
    final response = await http.post(
      Uri.parse(ApiConfig.customerFacebookLoginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final body = _decodeResponse(response);
    if (_isSuccess(response.statusCode)) {
      return UserLoginResponse.fromJson(body);
    }

    throw Exception(_extractErrorMessage(body, 'Đăng nhập Facebook thất bại'));
  }
}
