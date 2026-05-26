import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:petpee_mobile/common/auth/api/auth_service.dart';
import 'package:petpee_mobile/common/auth/model/auth_dto.dart';
import 'package:petpee_mobile/common/config/api_client.dart';
import 'package:petpee_mobile/common/user/model/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _token;
  String? get token => _token;

  String? _refreshToken;
  String? get refreshToken => _refreshToken;

  String? _role;
  String? get role => _role;

  int? _currentShopId;
  int? get currentShopId => _currentShopId;

  List<AuthShopDTO> _shops = [];
  List<AuthShopDTO> get shops => List.unmodifiable(_shops);

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  AuthProvider() {
    _loadToken();
  }

  void _loadToken() {
    final box = Hive.box('auth_box');
    _token = box.get('access_token');
    _refreshToken = box.get('refresh_token');
    _role = box.get('role');
    _currentShopId = box.get('current_shop_id');
    final userJson = box.get('user_data');
    if (userJson != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userJson));
    }
    final shopsJson = box.get('shops');
    if (shopsJson != null) {
      final decodedShops = jsonDecode(shopsJson) as List<dynamic>;
      _shops = decodedShops
          .map((shop) => AuthShopDTO.fromJson(shop as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
    // Sync ApiClient ngay lập tức (lúc này đã có currentShopId nếu đã login)
    ApiClient.instance.configure(
      token: _token,
      shopId: _currentShopId,
      customerId: _currentUser?.id,
    );
  }

  Future<void> _saveAuthentication(UserLoginResponse response) async {
    final box = await Hive.openBox('auth_box');
    await box.put('access_token', response.accessToken);
    await box.put('refresh_token', response.refreshToken);
    await box.put('role', response.role);
    if (response.currentShopId != null) {
      await box.put('current_shop_id', response.currentShopId);
    } else {
      await box.delete('current_shop_id');
    }
    await box.put('user_data', jsonEncode(response.user.toJson()));
    await box.put(
      'shops',
      jsonEncode(response.shops.map((shop) => shop.toJson()).toList()),
    );

    _token = response.accessToken;
    _refreshToken = response.refreshToken;
    _role = response.role;
    _currentShopId = response.currentShopId;
    _currentUser = response.user;
    _shops = response.shops;
    // Sync ApiClient sau mỗi lần login / token thay đổi
    ApiClient.instance.configure(
      token: _token,
      shopId: _currentShopId,
      customerId: response.user.id,
    );
    notifyListeners();
  }

  Future<void> _saveCurrentUser(UserModel user) async {
    final box = await Hive.openBox('auth_box');
    await box.put('user_data', jsonEncode(user.toJson()));

    _currentUser = user;
    ApiClient.instance.configure(
      token: _token,
      shopId: _currentShopId,
      customerId: user.id,
    );
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _authService.login(
        AuthenticationRequest(email: email, password: password),
      );
      await _saveAuthentication(response);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserLoginResponse> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
    required String province,
    required String district,
    required String ward,
    required String hamlet,
    int? age,
    XFile? avatar,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      return await _authService.register(
        RegisterRequest(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          address: address,
          province: province,
          district: district,
          ward: ward,
          hamlet: hamlet,
          age: age,
          avatarUrlPreview: avatar,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel> updateProfile({
    required String email,
    required String fullName,
    required String phone,
    int? age,
    XFile? avatar,
  }) async {
    final accessToken = _token;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Cần đăng nhập để cập nhật thông tin cá nhân');
    }

    final previousEmail = _currentUser?.email;

    try {
      _isLoading = true;
      notifyListeners();

      final updatedUser = await _authService.updateCurrentUserProfile(
        accessToken: accessToken,
        updateRequest: UpdateProfileRequest(
          email: email,
          fullName: fullName,
          phone: phone,
          age: age,
          avatarUrlPreview: avatar,
        ),
      );
      await _saveCurrentUser(updatedUser);

      final emailChanged =
          previousEmail != null &&
          previousEmail.toLowerCase() != updatedUser.email.toLowerCase();
      if (emailChanged && _refreshToken != null && _refreshToken!.isNotEmpty) {
        await refreshSession();
      }

      return _currentUser ?? updatedUser;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserModel> loadCurrentUserProfile() async {
    final accessToken = _token;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Cần đăng nhập để tải thông tin cá nhân');
    }

    try {
      _isLoading = true;
      notifyListeners();

      final user = await _authService.getCurrentUserProfile(
        accessToken: accessToken,
      );
      await _saveCurrentUser(user);
      return user;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<EmailVerificationResponse> sendRegisterVerificationCode(
    String email,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      return await _authService.sendRegisterVerificationCode(
        RegisterEmailVerificationSendRequest(email: email),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<EmailVerificationResponse> verifyRegisterVerificationCode({
    required String email,
    required String code,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      return await _authService.verifyRegisterVerificationCode(
        RegisterEmailVerificationVerifyRequest(email: email, code: code),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshSession() async {
    final refreshToken = _refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      throw Exception('Không có refresh token để làm mới phiên đăng nhập');
    }

    final response = await _authService.refreshToken(refreshToken);
    await _saveAuthentication(response);
  }

  Future<void> logout() async {
    final box = await Hive.openBox('auth_box');
    await box.delete('access_token');
    await box.delete('refresh_token');
    await box.delete('role');
    await box.delete('current_shop_id');
    await box.delete('user_data');
    await box.delete('shops');
    _token = null;
    _refreshToken = null;
    _role = null;
    _currentShopId = null;
    _currentUser = null;
    _shops = [];
    // Xoá token & shopId khỏi ApiClient
    ApiClient.instance.clear();
    notifyListeners();
  }

  /// Debug helper to inspect JWT token content.
  void debugPrintTokenInfo() {
    print('\n=== AUTH TOKEN DEBUG INFO ===');
    print('Token exists: ${_token != null}');
    print('Refresh token exists: ${_refreshToken != null}');
    print('Current Shop ID: $_currentShopId');
    print('Current User ID: ${_currentUser?.id}');
    print('Role: $_role');

    if (_token != null) {
      try {
        final parts = _token!.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = payload.padRight(
            payload.length + (4 - payload.length % 4) % 4,
            '=',
          );
          final decoded = utf8.decode(base64Url.decode(normalized));
          final claims = jsonDecode(decoded) as Map<String, dynamic>;

          print('JWT Claims:');
          claims.forEach((key, value) {
            print('  $key: $value');
          });
        }
      } catch (e) {
        print('Error decoding token: $e');
      }
    }

    print('==============================\n');
  }

  Future<void> googleLogin(String idToken) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _authService.googleLogin(
        GoogleLoginRequest(idToken: idToken),
      );
      await _saveAuthentication(response);
    } catch (e) {
      debugPrint('Google login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> facebookLogin(String accessToken) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _authService.facebookLogin(
        FacebookLoginRequest(accessToken: accessToken),
      );
      await _saveAuthentication(response);
    } catch (e) {
      debugPrint('Facebook login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
