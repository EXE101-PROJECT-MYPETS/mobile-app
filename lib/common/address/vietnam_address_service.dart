import 'dart:convert';

import 'package:http/http.dart' as http;

class VietnamAddressUnit {
  const VietnamAddressUnit({required this.code, required this.name});

  final int code;
  final String name;

  factory VietnamAddressUnit.fromJson(Map<String, dynamic> json) {
    return VietnamAddressUnit(
      code: json['code'] as int,
      name: json['name'] as String,
    );
  }
}

class VietnamAddressService {
  static const _baseUrl = 'https://provinces.open-api.vn/api/v1';

  List<VietnamAddressUnit>? _provinceCache;
  final Map<int, List<VietnamAddressUnit>> _districtCache = {};
  final Map<int, List<VietnamAddressUnit>> _wardCache = {};

  Future<List<VietnamAddressUnit>> fetchProvinces() async {
    if (_provinceCache != null) {
      return _provinceCache!;
    }

    final response = await http.get(Uri.parse('$_baseUrl/p/'));
    final data = _decodeResponse(response);
    final provinces = data
        .map(
          (item) => VietnamAddressUnit.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    _provinceCache = provinces;
    return provinces;
  }

  Future<List<VietnamAddressUnit>> fetchDistricts(int provinceCode) async {
    final cached = _districtCache[provinceCode];
    if (cached != null) {
      return cached;
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/p/$provinceCode?depth=2'),
    );
    final body = _decodeObjectResponse(response);
    final districts = (body['districts'] as List<dynamic>? ?? [])
        .map(
          (item) => VietnamAddressUnit.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    _districtCache[provinceCode] = districts;
    return districts;
  }

  Future<List<VietnamAddressUnit>> fetchWards(int districtCode) async {
    final cached = _wardCache[districtCode];
    if (cached != null) {
      return cached;
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/d/$districtCode?depth=2'),
    );
    final body = _decodeObjectResponse(response);
    final wards = (body['wards'] as List<dynamic>? ?? [])
        .map(
          (item) => VietnamAddressUnit.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    _wardCache[districtCode] = wards;
    return wards;
  }

  List<dynamic> _decodeResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không tải được danh sách địa chỉ');
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
  }

  Map<String, dynamic> _decodeObjectResponse(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không tải được danh sách địa chỉ');
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}
