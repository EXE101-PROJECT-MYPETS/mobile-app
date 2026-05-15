import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:petpee_mobile/apps/search/model/search_models.dart';
import 'package:petpee_mobile/common/config/api_client.dart';
import 'package:petpee_mobile/common/config/api_config.dart';

class SearchService {
  SearchService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<SearchInitialResponse> getInitial({
    double? lat,
    double? lng,
    int recommendedSize = 10,
  }) async {
    final response = await _client.get(
      _uri('/search/initial', {
        'lat': lat,
        'lng': lng,
        'recommendedSize': recommendedSize,
      }),
    );
    _ensureSuccess(response, 'load initial search data');
    return SearchInitialResponse.fromJson(_decodeMap(response));
  }

  Future<SearchSuggestionsResponse> getSuggestions({
    required String keyword,
    double? lat,
    double? lng,
    double? radiusKm,
    int size = 10,
  }) async {
    final response = await _client.get(
      _uri('/search/suggestions', {
        'keyword': keyword,
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
        'size': size,
      }),
    );
    _ensureSuccess(response, 'load search suggestions');
    return SearchSuggestionsResponse.fromJson(_decodeMap(response));
  }

  Future<SearchPageResponse> search({
    required String keyword,
    String type = 'ALL',
    double? lat,
    double? lng,
    double? radiusKm,
    String sort = 'RELEVANT',
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      _uri('/search', {
        'keyword': keyword,
        'type': type,
        'lat': lat,
        'lng': lng,
        'radiusKm': radiusKm,
        'sort': sort,
        'page': page,
        'size': size,
      }),
    );
    _ensureSuccess(response, 'search');
    return SearchPageResponse.fromJson(_decodeMap(response));
  }

  Future<void> saveHistory(String keyword) async {
    final response = await _client.post(
      _uri('/search/history'),
      body: jsonEncode({'keyword': keyword}),
    );
    _ensureSuccess(response, 'save search history');
  }

  Future<List<String>> getHistory() async {
    final response = await _client.get(_uri('/search/history'));
    _ensureSuccess(response, 'load search history');
    final json = _decodeMap(response);
    final value = json['keywords'];
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> deleteHistory({String? keyword}) async {
    final response = await _client.delete(
      _uri('/search/history', {'keyword': keyword}),
    );
    _ensureSuccess(response, 'delete search history');
  }

  Uri _uri(String path, [Map<String, Object?> query = const {}]) {
    final queryParameters = <String, String>{};
    for (final entry in query.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      queryParameters[entry.key] = value.toString();
    }

    return Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected search response format');
  }

  void _ensureSuccess(http.Response response, String action) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Failed to $action: ${response.statusCode}');
  }
}
