import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../features/auth/services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _token;
  String? get token => _token;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final box = await Hive.openBox('auth_box');
    _token = box.get('access_token');
    final userJson = box.get('user_data');
    if (userJson != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userJson));
    }
    notifyListeners();
  }

  Future<void> _saveToken(String token, Map<String, dynamic>? userMap) async {
    final box = await Hive.openBox('auth_box');
    await box.put('access_token', token);
    _token = token;
    if (userMap != null) {
      _currentUser = UserModel.fromJson(userMap);
      await box.put('user_data', jsonEncode(userMap));
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _authService.login(email, password);
      final accessToken = response['accessToken'] ?? response['access_token']; // Fallback for safety
      if (accessToken != null) {
        await _saveToken(accessToken, response['user']);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? address,
    int? age,
    XFile? avatar,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        address: address,
        age: age,
        avatar: avatar,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final box = await Hive.openBox('auth_box');
    await box.delete('access_token');
    await box.delete('user_data');
    _token = null;
    _currentUser = null;
    notifyListeners();
  }
}
