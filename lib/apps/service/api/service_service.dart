import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:petpee_mobile/common/config/api_config.dart';
import 'package:petpee_mobile/common/user/dto/service_public_dto.dart';
import 'package:petpee_mobile/common/user/dto/scroll_response.dart';

class ServicePublicService {
  final http.Client _client;

  ServicePublicService({http.Client? client}) : _client = client ?? http.Client();

  Future<ScrollResponse<ServicePublicDTO>> getAllForScroll({
    int? shopId,
    String? search,
    int? categoryId,
    bool active = true,
    double? minRating,
    double? lat,
    double? lng,
    double? radiusKm,
    int? cursor,
    int size = 20,
  }) async {
    final queryParams = <String, String>{};

    if (shopId != null) {
      queryParams['shopId'] = shopId.toString();
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (categoryId != null) {
      queryParams['categoryId'] = categoryId.toString();
    }
    queryParams['active'] = active.toString();
    
    if (minRating != null) {
      queryParams['minRating'] = minRating.toString();
    }
    if (lat != null) {
      queryParams['lat'] = lat.toString();
    }
    if (lng != null) {
      queryParams['lng'] = lng.toString();
    }
    if (radiusKm != null) {
      queryParams['radiusKm'] = radiusKm.toString();
    }
    if (cursor != null) {
      queryParams['cursor'] = cursor.toString();
    }
    queryParams['size'] = size.toString();

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/public/services',
    ).replace(queryParameters: queryParams);

    try {
      final response = await _client.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ScrollResponse<ServicePublicDTO>.fromJson(
          json,
          (item) => ServicePublicDTO.fromJson(item),
        );
      } else {
        throw Exception('Failed to load services: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
