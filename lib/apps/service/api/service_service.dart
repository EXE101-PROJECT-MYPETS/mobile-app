import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pawly_mobile/apps/service/model/booking_create_request.dart';
import 'package:pawly_mobile/apps/service/model/service_detail_dto.dart';
import 'package:pawly_mobile/common/config/api_client.dart';
import 'package:pawly_mobile/common/config/api_config.dart';
import 'package:pawly_mobile/common/user/dto/service_public_dto.dart';
import 'package:pawly_mobile/common/user/dto/scroll_response.dart';

class ServiceNotFoundException implements Exception {
  const ServiceNotFoundException();

  @override
  String toString() => 'Không tìm thấy dịch vụ';
}

class ServicePublicService {
  final http.Client _client;

  ServicePublicService({http.Client? client})
    : _client = client ?? http.Client();

  Future<ServiceDetailDTO> getDetail(int id) async {
    final uri = Uri.parse(ApiConfig.serviceDetailUrl(id));

    final response = await _client.get(
      uri,
      headers: const {'ngrok-skip-browser-warning': 'true'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is Map<String, dynamic>) {
        return ServiceDetailDTO.fromJson(json);
      }
      throw Exception('Dữ liệu chi tiết dịch vụ không hợp lệ');
    }

    if (response.statusCode == 404) {
      throw const ServiceNotFoundException();
    }

    throw Exception('Không thể tải chi tiết dịch vụ (${response.statusCode})');
  }

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
      final response = await _client.get(
        uri,
        headers: const {'ngrok-skip-browser-warning': 'true'},
      );

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

  Future<ScrollResponse<ServicePublicDTO>> getVeterinaryForScroll({
    int? shopId,
    String? search,
    int? categoryId,
    bool active = true,
    double? minRating,
    double? lat,
    double? lng,
    double? radiusKm,
    int? perShopLimit,
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
    if (perShopLimit != null) {
      queryParams['perShopLimit'] = perShopLimit.toString();
    }
    if (cursor != null) {
      queryParams['cursor'] = cursor.toString();
    }
    queryParams['size'] = size.toString();

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/public/services/veterinary',
    ).replace(queryParameters: queryParams);

    try {
      final response = await _client.get(
        uri,
        headers: const {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ScrollResponse<ServicePublicDTO>.fromJson(
          json,
          (item) => ServicePublicDTO.fromJson(item),
        );
      } else {
        throw Exception(
          'Failed to load veterinary services: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<ScrollResponse<ServicePublicDTO>> getRelatedForScroll({
    required int serviceId,
    int? cursor,
    int size = 10,
  }) async {
    final queryParams = <String, String>{'size': size.clamp(1, 20).toString()};

    if (cursor != null) {
      queryParams['cursor'] = cursor.toString();
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/public/services/$serviceId/related',
    ).replace(queryParameters: queryParams);

    final response = await _client.get(
      uri,
      headers: const {'ngrok-skip-browser-warning': 'true'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is Map<String, dynamic>) {
        return ScrollResponse<ServicePublicDTO>.fromJson(
          json,
          (item) => ServicePublicDTO.fromJson(item),
        );
      }
      throw Exception('Dữ liệu dịch vụ liên quan không hợp lệ');
    }

    throw Exception('Không thể tải dịch vụ liên quan (${response.statusCode})');
  }
}

class ServiceBookingService {
  ServiceBookingService({ApiClient? client})
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<void> createBooking({
    required int shopId,
    required BookingCreateRequest request,
  }) async {
    final uri = Uri.parse(ApiConfig.shopBookingsUrl(shopId));
    final response = await _client.post(
      uri,
      includeContextHeaders: false,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Vui lòng đăng nhập để đặt lịch');
    }

    if (response.statusCode == 400) {
      throw Exception('Thông tin đặt lịch chưa hợp lệ');
    }

    throw Exception('Không thể tạo lịch hẹn (${response.statusCode})');
  }
}
