class ApiConfig {
  // Thay đổi IP này thành IP của máy tính bạn trong mạng LAN (IPv4)
  // Nếu dùng máy ảo Android (Emulator), dùng 10.0.2.2
  // Nếu dùng máy thật, dùng IPv4 LAN của máy chạy backend
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.16.104:8080/api',
  );

  static const String authUrl = '$baseUrl/auth';
  static const String registerUrl = '$authUrl/register';
  static const String registerEmailVerificationUrl =
      '$registerUrl/email-verification';
  static const String registerEmailSendCodeUrl =
      '$registerEmailVerificationUrl/send-code';
  static const String registerEmailVerifyCodeUrl =
      '$registerEmailVerificationUrl/verify-code';
  static const String customerLoginUrl = '$authUrl/customer/login';
  static const String customerGoogleLoginUrl = '$authUrl/customer/google-login';
  static const String customerFacebookLoginUrl =
      '$authUrl/customer/facebook-login';
  static const String shopLoginUrl = '$authUrl/shop/login';
  static const String currentUserProfileUrl = '$baseUrl/users/me';
  static const String currentUserAddressUrl = '$baseUrl/users/me/address';

  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '959472405909-jcckrg23puil1dtti4pkgrplms1tsq2l.apps.googleusercontent.com',
  );

  // Product endpoints (Public)
  static const String productPublicUrl = '$baseUrl/public/products';
  static const String productMobileUrl = '$productPublicUrl/mobile';
  static const String shopPublicUrl = '$baseUrl/public/shops';
  static const String shopMarkersUrl = '$shopPublicUrl/markers';

  // Shipping endpoints
  static const String ghtkOrdersFeeUrl = '$baseUrl/ghtk/orders/fee';

  // Order endpoints
  static const String ordersUrl = '$baseUrl/orders';

  // Chat endpoints
  static const String chatUrl = '$baseUrl/customer/conversations';
  static const String chatConversationsUrl = chatUrl;

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
