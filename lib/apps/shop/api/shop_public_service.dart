import 'dart:convert';

import 'package:pawly_mobile/apps/shop/model/nearby_shop_dto.dart';
import 'package:pawly_mobile/common/config/api_config.dart';
import 'package:pawly_mobile/common/config/public_api_client.dart';

class ShopPublicService {
  ShopPublicService({PublicApiClient? client})
    : _client = client ?? PublicApiClient.instance;

  final PublicApiClient _client;

  Future<List<NearbyShopDTO>> getNearby({
    required double lat,
    required double lng,
    int size = 10,
    double? radiusKm,
  }) async {
    final queryParams = <String, String>{
      'lat': lat.toString(),
      'lng': lng.toString(),
      'size': size.clamp(1, 10).toString(),
    };

    if (radiusKm != null && radiusKm > 0) {
      queryParams['radiusKm'] = radiusKm.toString();
    }

    final uri = Uri.parse(
      ApiConfig.nearbyShopsUrl,
    ).replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(NearbyShopDTO.fromJson)
            .where((shop) => shop.id != null)
            .toList(growable: false);
      }
      throw Exception('Dữ liệu shop gần bạn không hợp lệ');
    }

    throw Exception('Không thể tải shop gần bạn (${response.statusCode})');
  }
}
