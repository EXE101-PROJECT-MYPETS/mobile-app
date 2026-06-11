import 'dart:convert';

import 'package:pawly_mobile/common/config/api_client.dart';
import 'package:pawly_mobile/common/config/api_config.dart';
import 'package:pawly_mobile/common/user/dto/shop_marker_dto.dart';

class ShopMarkerService {
  const ShopMarkerService();

  Future<List<ShopMarkerDTO>> getAllMarkers() async {
    final uri = Uri.parse(ApiConfig.shopMarkersUrl);
    final response = await ApiClient.instance.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load shop markers: ${response.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw Exception('Invalid shop markers response format');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ShopMarkerDTO.fromJson)
        .where((shop) => shop.hasValidCoordinates)
        .toList();
  }
}
