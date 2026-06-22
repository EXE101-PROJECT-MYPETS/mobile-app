import 'dart:convert';
import 'package:pawly_mobile/common/config/api_client.dart';
import 'package:pawly_mobile/common/config/api_config.dart';

class ReviewService {
  final ApiClient _client;

  ReviewService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  Future<void> submitProductReview({
    required int productId,
    required int rating,
    required String comment,
    String? token,
  }) async {
    final uri = Uri.parse(ApiConfig.productReviewsCustomerUrl);
    final payload = {
      'productId': productId,
      'rating': rating,
      'comment': comment.trim(),
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = utf8.decode(response.bodyBytes);
      throw Exception(
          'Gửi đánh giá sản phẩm thất bại (${response.statusCode}): $body');
    }
  }

  Future<void> submitServiceReview({
    required int serviceId,
    required int rating,
    required String comment,
    String? token,
  }) async {
    final uri = Uri.parse(ApiConfig.serviceReviewsCustomerUrl);
    final payload = {
      'serviceId': serviceId,
      'rating': rating,
      'comment': comment.trim(),
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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = utf8.decode(response.bodyBytes);
      throw Exception(
          'Gửi đánh giá dịch vụ thất bại (${response.statusCode}): $body');
    }
  }

  Future<void> likeProductReview(int reviewId, {String? token}) async {
    final uri = Uri.parse(ApiConfig.productReviewLikeUrl(reviewId));
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.post(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Thích đánh giá thất bại (${response.statusCode})');
    }
  }

  Future<void> dislikeProductReview(int reviewId, {String? token}) async {
    final uri = Uri.parse(ApiConfig.productReviewDislikeUrl(reviewId));
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.post(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không thích đánh giá thất bại (${response.statusCode})');
    }
  }

  Future<void> likeServiceReview(int reviewId, {String? token}) async {
    final uri = Uri.parse(ApiConfig.serviceReviewLikeUrl(reviewId));
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.post(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Thích đánh giá dịch vụ thất bại (${response.statusCode})');
    }
  }

  Future<void> dislikeServiceReview(int reviewId, {String? token}) async {
    final uri = Uri.parse(ApiConfig.serviceReviewDislikeUrl(reviewId));
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await _client.post(uri, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Không thích đánh giá dịch vụ thất bại (${response.statusCode})');
    }
  }
}
