import 'dart:convert';
import 'package:http/http.dart' as http;

/// Singleton HTTP client tự động inject:
/// - `Authorization: Bearer <token>`
/// - `X-Shop-Id: <shopId>`
/// vào mọi request, tương tự Axios interceptor bên web.
///
/// Cách dùng:
/// ```dart
/// // Gọi một lần sau login hoặc khi khởi động app
/// ApiClient.instance.configure(token: '...', shopId: 1);
///
/// // Trong service dùng như http bình thường
/// final response = await ApiClient.instance.get(uri);
/// ```
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;
  int? _shopId;
  int? _customerId;

  final http.Client _client = http.Client();

  /// Cập nhật token, shopId, và customerId (gọi sau login / load từ Hive).
  void configure({String? token, int? shopId, int? customerId}) {
    _token = token;
    _shopId = shopId;
    _customerId = customerId;
  }

  /// Xoá thông tin xác thực (gọi khi logout).
  void clear() {
    _token = null;
    _shopId = null;
    _customerId = null;
  }

  // ─── Headers builder ──────────────────────────────────────────────────────

  Map<String, String> _buildHeaders([Map<String, String>? extra]) {
    final headers = <String, String>{
      'content-type': 'application/json',
      if (_token != null) 'authorization': 'Bearer $_token',
      'X-Shop-Id': (_shopId ?? 1).toString(), // Default to 1 for guests
      if (_customerId != null) 'X-Customer-Id': _customerId.toString(),
    };
    if (extra != null) headers.addAll(extra);
    print('🚀 [ApiClient] Sending Headers: $headers');
    return headers;
  }

  // ─── HTTP methods ─────────────────────────────────────────────────────────

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _client.get(url, headers: _buildHeaders(headers));
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _client.post(
      url,
      headers: _buildHeaders(headers),
      body: body,
      encoding: encoding,
    );
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _client.put(
      url,
      headers: _buildHeaders(headers),
      body: body,
      encoding: encoding,
    );
  }

  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _client.patch(
      url,
      headers: _buildHeaders(headers),
      body: body,
      encoding: encoding,
    );
  }

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _client.delete(
      url,
      headers: _buildHeaders(headers),
      body: body,
      encoding: encoding,
    );
  }
}
