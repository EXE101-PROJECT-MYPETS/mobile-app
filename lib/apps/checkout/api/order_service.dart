import 'dart:convert';

import 'package:petpee_mobile/apps/checkout/model/order_request_model.dart';
import 'package:petpee_mobile/common/config/api_client.dart';
import 'package:petpee_mobile/common/config/api_config.dart';

class OrderService {
  final ApiClient _client;

  OrderService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  Future<Map<String, dynamic>> createOrder(CreateOrderRequest request) async {
    final uri = Uri.parse(ApiConfig.ordersUrl);

    final response = await _client.post(
      uri,
      body: jsonEncode(request.toJson()),
    );

    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.trim().isEmpty) return <String, dynamic>{};
      return jsonDecode(body) as Map<String, dynamic>;
    }

    throw Exception('Tạo đơn thất bại (${response.statusCode}): $body');
  }
}