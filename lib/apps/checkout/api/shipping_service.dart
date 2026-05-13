import 'dart:convert';
import 'package:petpee_mobile/apps/checkout/model/ghtk_fee_model.dart';
import 'package:petpee_mobile/common/config/api_client.dart';
import 'package:petpee_mobile/common/config/api_config.dart';

class ShippingService {
  final ApiClient _client;

  ShippingService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  /// POST /api/ghtk/orders/fee
  /// Header Authorization + X-Shop-Id tự inject bởi ApiClient.
  Future<GhtkFeeResponse> getShippingFee(GhtkFeeRequest request) async {
    final uri = Uri.parse(ApiConfig.ghtkOrdersFeeUrl);

    final response = await _client.post(
      uri,
      body: jsonEncode(request.toJson()),
    );

    final body = utf8.decode(response.bodyBytes);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return GhtkFeeResponse.fromJson(json);
    }

    throw Exception(
      'Lấy phí vận chuyển thất bại (${response.statusCode}): $body',
    );
  }
}
