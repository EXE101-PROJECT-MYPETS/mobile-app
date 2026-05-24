import 'dart:convert';

import 'package:petpee_mobile/apps/checkout/model/checkout_request_model.dart';
import 'package:petpee_mobile/apps/checkout/model/checkout_response_model.dart';
import 'package:petpee_mobile/common/config/api_client.dart';
import 'package:petpee_mobile/common/config/api_config.dart';

class CheckoutService {
  final ApiClient _client;

  CheckoutService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  Future<CheckoutResponseModel> checkout(CheckoutRequestModel request) async {
    final uri = Uri.parse(ApiConfig.checkoutUrl);
    final response = await _client.post(
      uri,
      body: jsonEncode(request.toJson()),
    );

    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.trim().isEmpty) {
        return const CheckoutResponseModel();
      }

      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return CheckoutResponseModel.fromJson(decoded);
      }
      return const CheckoutResponseModel();
    }

    throw Exception('Thanh toán thất bại (${response.statusCode}): $body');
  }
}