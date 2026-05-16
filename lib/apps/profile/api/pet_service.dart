import 'dart:convert';

import 'package:petpee_mobile/apps/profile/model/pet_dto.dart';
import 'package:petpee_mobile/common/config/api_client.dart';
import 'package:petpee_mobile/common/config/api_config.dart';

class PetService {
  final ApiClient _client;

  PetService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  /// Get all pets for the current user from the JWT access token.
  Future<List<PetDTO>> getAll() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets');
    final response = await _client.get(uri, includeContextHeaders: false);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body) as List<dynamic>;
      return jsonResponse
          .map((pet) => PetDTO.fromJson(pet as Map<String, dynamic>))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - vui lòng đăng nhập lại');
    } else if (response.statusCode == 400) {
      throw Exception('Bad Request: ${response.body}');
    } else {
      throw Exception('Failed to load pets: ${response.statusCode}');
    }
  }

  /// Get pet by ID.
  Future<PetDTO> getById(int petId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/$petId');
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      return PetDTO.fromJson(jsonResponse);
    } else if (response.statusCode == 404) {
      throw Exception('Pet không tìm thấy');
    } else {
      throw Exception('Failed to load pet: ${response.statusCode}');
    }
  }

  /// Create new pet.
  Future<PetDTO> create(PetDTO petDTO) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets');
    final body = jsonEncode(petDTO.toJson());

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      return PetDTO.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - vui lòng đăng nhập lại');
    } else if (response.statusCode == 400) {
      throw Exception('Dữ liệu không hợp lệ');
    } else {
      throw Exception('Failed to create pet: ${response.statusCode}');
    }
  }

  /// Update existing pet.
  Future<PetDTO> update(int petId, PetDTO petDTO) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/$petId');
    final body = jsonEncode(petDTO.toJson());

    final response = await _client.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      return PetDTO.fromJson(jsonResponse);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - vui lòng đăng nhập lại');
    } else if (response.statusCode == 404) {
      throw Exception('Pet không tìm thấy');
    } else {
      throw Exception('Failed to update pet: ${response.statusCode}');
    }
  }

  /// Delete pet.
  Future<void> delete(int petId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/$petId');
    final response = await _client.delete(uri);

    if (response.statusCode == 204) {
      return;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - vui lòng đăng nhập lại');
    } else if (response.statusCode == 404) {
      throw Exception('Pet không tìm thấy');
    } else {
      throw Exception('Failed to delete pet: ${response.statusCode}');
    }
  }
}
