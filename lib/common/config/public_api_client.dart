import 'dart:convert';
import 'package:http/http.dart' as http;

/// Public HTTP client without authentication for unauthenticated endpoints
/// Útil cho public API endpoints như /api/public/products
class PublicApiClient {
  PublicApiClient._();
  static final PublicApiClient instance = PublicApiClient._();

  final http.Client _client = http.Client();

  Map<String, String> _buildHeaders([Map<String, String>? extra]) {
    final headers = <String, String>{
      'content-type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    if (extra != null) headers.addAll(extra);
    return headers;
  }

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

  Future<http.Response> delete(Uri url, {Map<String, String>? headers}) {
    return _client.delete(url, headers: _buildHeaders(headers));
  }
}
