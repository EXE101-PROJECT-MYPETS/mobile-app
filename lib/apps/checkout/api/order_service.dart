import 'dart:convert';

import 'package:pawly_mobile/apps/checkout/model/order_request_model.dart';
import 'package:pawly_mobile/common/config/api_client.dart';
import 'package:pawly_mobile/common/config/api_config.dart';

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

  Future<Map<String, dynamic>> getCustomerOrders({
    String? status,
    int? cursor,
    int size = 10,
    String? token,
  }) async {
    final queryParams = <String, String>{'size': size.toString()};
    if (status != null) {
      queryParams['status'] = status;
    }
    if (cursor != null) {
      queryParams['cursor'] = cursor.toString();
    }

    final uri = Uri.parse(
      '${ApiConfig.ordersUrl}/customer',
    ).replace(queryParameters: queryParams);

    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(uri, headers: headers);
    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.trim().isEmpty) return <String, dynamic>{};
      return jsonDecode(body) as Map<String, dynamic>;
    }
    throw Exception('Lỗi lấy đơn hàng (${response.statusCode}): $body');
  }

  Future<Map<String, dynamic>> getCustomerOrderDetail({
    required int id,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.ordersUrl}/customer/$id');

    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.get(uri, headers: headers);
    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.trim().isEmpty) return <String, dynamic>{};
      return jsonDecode(body) as Map<String, dynamic>;
    }

    throw Exception(
      'Lỗi lấy chi tiết đơn hàng (${response.statusCode}): $body',
    );
  }

  Future<Map<String, dynamic>> cancelCustomerOrder({
    required int id,
    String? reason,
    String? token,
  }) async {
    final uri = Uri.parse('${ApiConfig.ordersUrl}/customer/$id/cancel');
    final trimmedReason = reason?.trim();
    final payload = <String, dynamic>{
      if (trimmedReason != null && trimmedReason.isNotEmpty)
        'reason': trimmedReason,
    };

    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(payload),
    );
    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (body.trim().isEmpty) return <String, dynamic>{};
      return jsonDecode(body) as Map<String, dynamic>;
    }

    throw Exception('Hủy đơn thất bại (${response.statusCode}): $body');
  }
}
