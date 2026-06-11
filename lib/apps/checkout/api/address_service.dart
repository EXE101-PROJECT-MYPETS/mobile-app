import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pawly_mobile/apps/checkout/model/address_model.dart';
import 'package:pawly_mobile/common/config/api_config.dart';

class AddressService {
  Future<List<AddressModel>> getCurrentUserAddresses(String accessToken) async {
    final response = await http.get(
      Uri.parse(ApiConfig.currentUserAddressUrl),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response.body, 'Khong the tai dia chi giao hang'),
      );
    }

    final body = utf8.decode(response.bodyBytes);
    if (body.trim().isEmpty) return [];

    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw Exception('Du lieu dia chi khong hop le');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(AddressModel.fromApi)
        .toList();
  }

  Future<AddressModel> getCurrentUserAddressDetail({
    required String accessToken,
    required String id,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.currentUserAddressUrl}/$id'),
      headers: _headers(accessToken),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response.body, 'Không thể tải địa chỉ'),
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Dữ liệu địa chỉ không hợp lệ');
    }
    return AddressModel.fromApi(decoded);
  }

  Future<AddressModel> createCurrentUserAddress({
    required String accessToken,
    required AddressModel address,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.currentUserAddressUrl),
      headers: _headers(accessToken),
      body: jsonEncode(address.toApiJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response.body, 'Không thể tạo địa chỉ'),
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Dữ liệu địa chỉ không hợp lệ');
    }
    return AddressModel.fromApi(decoded);
  }

  Future<AddressModel> updateCurrentUserAddress({
    required String accessToken,
    required AddressModel address,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.currentUserAddressUrl}/${address.id}'),
      headers: _headers(accessToken),
      body: jsonEncode(address.toApiJson()),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response.body, 'Không thể cập nhật địa chỉ'),
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Dữ liệu địa chỉ không hợp lệ');
    }
    return AddressModel.fromApi(decoded);
  }

  Future<void> deleteCurrentUserAddress({
    required String accessToken,
    required String id,
  }) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.currentUserAddressUrl}/$id'),
      headers: _headers(accessToken),
    );

    if (response.statusCode == 204) return;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response.body, 'Không thể xóa địa chỉ'),
      );
    }
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      'Authorization': 'Bearer $accessToken',
    };
  }

  String _extractErrorMessage(String responseBody, String fallback) {
    if (responseBody.trim().isEmpty) return fallback;

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return (decoded['message'] as String?) ??
            (decoded['error'] as String?) ??
            fallback;
      }
    } catch (_) {
      return responseBody.trim();
    }

    return fallback;
  }
}
