import 'dart:convert';
import 'package:petpee_mobile/common/config/api_client.dart';
import 'package:petpee_mobile/common/config/api_config.dart';
import 'package:petpee_mobile/common/user/dto/product_dto.dart';
import 'package:petpee_mobile/common/user/dto/product_public_detail_dto.dart';
import 'package:petpee_mobile/common/user/dto/product_public_review_dto.dart';
import 'package:petpee_mobile/common/user/dto/shop_public_dto.dart';
import 'package:petpee_mobile/common/user/dto/scroll_response.dart';

class ProductService {
  final ApiClient _client;

  ProductService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  Future<ScrollResponse<ProductDTO>> getAllMobile({
    String? keyword,
    bool? active,
    int? cursor,
    int size = 20,
  }) async {
    final queryParams = <String, String>{};
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }
    if (active != null) {
      queryParams['active'] = active.toString();
    }
    if (cursor != null) {
      queryParams['cursor'] = cursor.toString();
    }
    queryParams['size'] = size.toString();

    final uri = Uri.parse(ApiConfig.productMobileUrl).replace(
      queryParameters: queryParams,
    );

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      return ScrollResponse<ProductDTO>.fromJson(
        jsonResponse,
        (json) => ProductDTO.fromJson(json),
      );
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  }

  Future<ProductPublicDetailDTO> getProductDetail(String productId) async {
    final uri = Uri.parse('${ApiConfig.productMobileUrl}/$productId');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      return ProductPublicDetailDTO.fromJson(jsonResponse);
    }

    throw Exception('Failed to load product detail: ${response.statusCode}');
  }

  Future<List<ProductDTO>> getProductRelated(
    String productId, {
    int size = 10,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.productPublicUrl}/$productId/related',
    ).replace(queryParameters: {'size': size.toString()});
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final dynamic jsonResponse = json.decode(response.body);
      return _parseListResponse(jsonResponse, (item) => ProductDTO.fromJson(item));
    }

    throw Exception('Failed to load related products: ${response.statusCode}');
  }

  Future<List<ProductPublicReviewDTO>> getProductReviews(
    String productId, {
    int size = 20,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.productPublicUrl}/$productId/reviews',
    ).replace(queryParameters: {'size': size.toString()});
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final dynamic jsonResponse = json.decode(response.body);
      return _parseListResponse(
        jsonResponse,
        (item) => ProductPublicReviewDTO.fromJson(item),
      );
    }

    throw Exception('Failed to load product reviews: ${response.statusCode}');
  }

  Future<ShopPublicDTO> getShopDetail(int shopId) async {
    final uri = Uri.parse('${ApiConfig.shopPublicUrl}/$shopId');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      return ShopPublicDTO.fromJson(jsonResponse);
    }

    throw Exception('Failed to load shop detail: ${response.statusCode}');
  }

  List<T> _parseListResponse<T>(
    dynamic body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (body is List) {
      return body.whereType<Map<String, dynamic>>().map(fromJson).toList();
    }

    if (body is Map<String, dynamic> && body['content'] is List) {
      return (body['content'] as List)
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList();
    }

    throw Exception('Unexpected response format: cannot parse list');
  }
}