import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  static const Duration requestTimeout = Duration(seconds: 15);

  static const String _androidEmulatorBaseUrl = 'http://10.0.2.2:8080/api';
  static const String _iosSimulatorBaseUrl = 'http://localhost:8080/api';
  static const List<String> _physicalDeviceBaseUrls = [
    'http://192.168.1.11:8080/api',
    'http://192.168.165.224:8080/api',
    'http://192.168.165.224:8080/api',
  ];

  static String _baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static Future<void> initialize() async {
    final configuredBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );
    if (configuredBaseUrl.isNotEmpty) {
      _baseUrl = configuredBaseUrl;
      return;
    }

    if (kIsWeb) {
      _baseUrl = _physicalDeviceBaseUrls.first;
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      _baseUrl = androidInfo.isPhysicalDevice
          ? await _resolvePhysicalDeviceBaseUrl()
          : _androidEmulatorBaseUrl;
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await DeviceInfoPlugin().iosInfo;
      _baseUrl = iosInfo.isPhysicalDevice
          ? await _resolvePhysicalDeviceBaseUrl()
          : _iosSimulatorBaseUrl;
      return;
    }

    _baseUrl = await _resolvePhysicalDeviceBaseUrl();
  }

  // Thay đổi IP này thành IP của máy tính bạn trong mạng LAN (IPv4).
  // Nếu dùng máy ảo Android (emulator), dùng 10.0.2.2.
  static String get baseUrl => _baseUrl;

  static Future<String> _resolvePhysicalDeviceBaseUrl() async {
    for (final candidateBaseUrl in _physicalDeviceBaseUrls) {
      if (await _isReachable(candidateBaseUrl)) {
        return candidateBaseUrl;
      }
    }

    return _physicalDeviceBaseUrls.first;
  }

  static Future<bool> _isReachable(String baseUrl) async {
    final uri = Uri.parse('$baseUrl/public/products/mobile?size=1');
    final client = http.Client();
    try {
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 3));
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  static String get authUrl => '$baseUrl/auth';
  static String get registerUrl => '$authUrl/register';
  static String get registerEmailVerificationUrl =>
      '$registerUrl/email-verification';
  static String get registerEmailSendCodeUrl =>
      '$registerEmailVerificationUrl/send-code';
  static String get registerEmailVerifyCodeUrl =>
      '$registerEmailVerificationUrl/verify-code';
  static String get customerLoginUrl => '$authUrl/customer/login';
  static String get customerGoogleLoginUrl => '$authUrl/customer/google-login';
  static String get customerFacebookLoginUrl =>
      '$authUrl/customer/facebook-login';
  static String get shopLoginUrl => '$authUrl/shop/login';
  static String get currentUserProfileUrl => '$baseUrl/users/me';
  static String get currentUserAddressUrl => '$baseUrl/users/me/address';

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '959472405909-jcckrg23puil1dtti4pkgrplms1tsq2l.apps.googleusercontent.com',
  );

  // Product endpoints (Public)
  static String get productPublicUrl => '$baseUrl/public/products';
  static String get productMobileUrl => '$productPublicUrl/mobile';
  static String get shopPublicUrl => '$baseUrl/public/shops';
  static String get nearbyShopsUrl => '$shopPublicUrl/nearby';
  static String get shopMarkersUrl => '$shopPublicUrl/markers';
  static String shopServicesUrl(int shopId) =>
      '$shopPublicUrl/$shopId/services';
  static String serviceDetailUrl(int id) => '$baseUrl/services/$id';
  static String shopBookingsUrl(int shopId) =>
      '$baseUrl/shops/$shopId/bookings';

  // Shipping endpoints
  static String get ghtkOrdersFeeUrl => '$baseUrl/ghtk/orders/fee';

  // Order endpoints
  static String get ordersUrl => '$baseUrl/orders';
  static String get checkoutUrl => '$baseUrl/v1/checkout';

  // Chat endpoints
  static String get chatUrl => '$baseUrl/customer/conversations';
  static String get chatConversationsUrl => chatUrl;
  static String get aiPetHealthUrl => '$baseUrl/ai/pet-health';
  static String get aiPetHealthConversationsUrl =>
      '$aiPetHealthUrl/conversations';
  static String get aiPetHealthGetOrCreateConversationUrl =>
      '$aiPetHealthConversationsUrl/get-or-create';
  static String get aiPetHealthChatUrl => '$aiPetHealthUrl/chat';

  static String get chatWebSocketUrl {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    final authority = uri.hasPort ? '${uri.host}:${uri.port}' : uri.host;
    return '$scheme://$authority/ws';
  }

  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;

    // Remove /api from baseUrl since images are usually hosted at /uploads directly
    final base = baseUrl.replaceAll('/api', '');
    if (url.startsWith('/')) {
      return '$base$url';
    }
    return '$base/$url';
  }
}
