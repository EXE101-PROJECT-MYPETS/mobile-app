class ApiConfig {
  // Thay đổi IP này thành IP của máy tính bạn trong mạng LAN (IPv4)
  // Nếu dùng máy ảo Android (Emulator), dùng 10.0.2.2
  static const String baseUrl = 'http://192.168.1.201:8080/api';
  
  static const String authUrl = '$baseUrl/auth';
  static const String registerUrl = '$authUrl/register';
  static const String customerLoginUrl = '$authUrl/customer/login';
  static const String shopLoginUrl = '$authUrl/shop/login';
}
