import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:petpee_mobile/apps/checkout/model/address_model.dart';
import 'package:petpee_mobile/common/config/api_config.dart';

class AddressService {
  Future<List<AddressModel>> getCurrentUserAddresses(String accessToken) async {
    final response = await http.get(
      Uri.parse(ApiConfig.currentUserAddressUrl),
      headers: {
        'Content-Type': 'application/json',
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
