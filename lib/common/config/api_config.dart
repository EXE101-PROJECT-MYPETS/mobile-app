class ApiConfig {
  // Thay đổi IP này thành IP của máy tính bạn trong mạng LAN (IPv4)
  // Nếu dùng máy ảo Android (Emulator), dùng 10.0.2.2
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.26:8080/api',
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
  static const String shopMarkersUrl = '$shopPublicUrl/markers';

  // Shipping endpoints
  static const String ghtkOrdersFeeUrl = '$baseUrl/ghtk/orders/fee';

  // Order endpoints
  static const String ordersUrl = '$baseUrl/orders';
}

