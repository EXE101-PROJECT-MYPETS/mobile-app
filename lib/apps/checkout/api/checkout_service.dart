import 'dart:convert';

import 'package:pawly_mobile/apps/checkout/model/checkout_request_model.dart';
import 'package:pawly_mobile/apps/checkout/model/checkout_response_model.dart';
import 'package:pawly_mobile/common/config/api_client.dart';
import 'package:pawly_mobile/common/config/api_config.dart';

class CheckoutService {
  final ApiClient _client;

  CheckoutService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  Future<CheckoutResponseModel> checkout(CheckoutRequestModel request) async {
    final uri = Uri.parse(ApiConfig.ordersUrl);

    // Backend expects product items under `items`, while service bookings stay
    // in the checkout payload so spa services can be booked from the cart.
    final payload = {
      'shopId': request.shopId,
      'userId': request.userId,
      if (request.customerId != null) 'customerId': request.customerId,
      if (request.userAddressId != null) 'userAddressId': request.userAddressId,
      'source': request.source,
      'receiverName': request.receiverName,
      'receiverPhone': request.receiverPhone,
      'shippingAddress': request.shippingAddress,
      'shippingFee': request.shippingFee,
      if (request.pickupFee > 0) 'pickupFee': request.pickupFee,
      'discountAmount': request.discountAmount,
      if (request.note != null && request.note!.trim().isNotEmpty)
        'note': request.note!.trim(),
      'items': request.productOrders
          .map(
            (item) => {
              'productId': item.productId,
              'qty': item.qty,
              'unitPrice': item.unitPrice,
            },
          )
          .toList(),
      if (request.serviceBookings.isNotEmpty)
        'serviceBookings':
            request.serviceBookings.map((item) => item.toJson()).toList(),
    };

    final response = await _client.post(uri, body: jsonEncode(payload));

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
