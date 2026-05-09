import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:petpee_mobile/common/auth/model/auth_dto.dart';
import 'package:petpee_mobile/common/config/api_config.dart';

class AuthService {
  Future<EmailVerificationResponse> sendRegisterVerificationCode(
    RegisterEmailVerificationSendRequest request,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.registerEmailSendCodeUrl),
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    final body = _decodeResponse(response);
    if (_isSuccess(response.statusCode)) {
      return UserLoginResponse.fromJson(body);
    }

    throw Exception(_extractErrorMessage(body, 'Đăng nhập thất bại'));
  }

  Future<UserLoginResponse> register(RegisterRequest registerRequest) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.registerUrl),
    );

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
}
