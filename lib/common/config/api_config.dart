class ApiConfig {
  // Thay đổi IP này thành IP của máy tính bạn trong mạng LAN (IPv4)
  // Nếu dùng máy ảo Android (Emulator), dùng 10.0.2.2
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.16.107:8080/api',
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
  static const String shopLoginUrl = '$authUrl/shop/login';
  static const String currentUserAddressUrl = '$baseUrl/users/me/address';

  // Product endpoints (Public)
  static const String productPublicUrl = '$baseUrl/public/products';
  static const String productMobileUrl = '$productPublicUrl/mobile';
  static const String shopPublicUrl = '$baseUrl/public/shops';

  // Shipping endpoints
  static const String ghtkOrdersFeeUrl = '$baseUrl/ghtk/orders/fee';

  // Order endpoints
  static const String ordersUrl = '$baseUrl/orders';

  // Chat endpoints
  static const String chatUrl = '$baseUrl/customer/conversations';
  static const String chatConversationsUrl = chatUrl;

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
