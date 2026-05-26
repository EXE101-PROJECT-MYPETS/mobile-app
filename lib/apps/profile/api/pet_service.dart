import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:petpee_mobile/apps/profile/model/pet_dto.dart';
import 'package:petpee_mobile/apps/profile/model/pet_species_dto.dart';
import 'package:petpee_mobile/common/config/api_client.dart';
import 'package:petpee_mobile/common/config/api_config.dart';

class PetService {
  final ApiClient _client;

  PetService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  Future<List<PetSpeciesDTO>> getSpecies() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/species');
    final response = await _client.get(uri, includeContextHeaders: false);

    if (response.statusCode == 200) {
      final jsonResponse =
          json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
      return jsonResponse
          .map(
            (species) =>
                PetSpeciesDTO.fromJson(species as Map<String, dynamic>),
          )
          .toList();
    } else {
      throw Exception('Failed to load species: ${response.statusCode}');
    }
  }

  /// Get all pets for the current user from the JWT access token.
  Future<List<PetDTO>> getAll() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/my');
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
      throw Exception(
        'Không thể tải thú cưng (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Get pet by ID.
  Future<PetDTO> getById(int petId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/my/$petId');
    final response = await _client.get(uri, includeContextHeaders: false);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      return PetDTO.fromJson(jsonResponse);
    } else if (response.statusCode == 404) {
      throw Exception('Pet không tìm thấy');
    } else {
      throw Exception(
        'Không thể tải thú cưng (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Create new pet.
  Future<PetDTO> create(PetDTO petDTO, {XFile? avatarFile}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/my');
    final response = await _sendMultipartPetRequest(
      method: 'POST',
      uri: uri,
      petDTO: petDTO,
      avatarFile: avatarFile,
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
  Future<PetDTO> update(int petId, PetDTO petDTO, {XFile? avatarFile}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/my/$petId');
    final response = await _sendMultipartPetRequest(
      method: 'PUT',
      uri: uri,
      petDTO: petDTO,
      avatarFile: avatarFile,
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
    final uri = Uri.parse('${ApiConfig.baseUrl}/pets/my/$petId');
    final request = http.Request('DELETE', uri);
    final token = _client.token;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['ngrok-skip-browser-warning'] = 'true';
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

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

  Future<http.Response> _sendMultipartPetRequest({
    required String method,
    required Uri uri,
    required PetDTO petDTO,
    XFile? avatarFile,
  }) async {
    final request = http.MultipartRequest(method, uri);

    final token = _client.token;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['ngrok-skip-browser-warning'] = 'true';

    final shopId = _client.shopId;
    if (shopId != null) {
      request.headers['X-Shop-Id'] = shopId.toString();
    }

    request.fields['name'] = petDTO.name;
    if (petDTO.speciesId != null) {
      request.fields['speciesId'] = petDTO.speciesId.toString();
    }
    if (petDTO.breedId != null) {
      request.fields['breedId'] = petDTO.breedId.toString();
    }
    if (petDTO.breedText != null && petDTO.breedText!.isNotEmpty) {
      request.fields['breedText'] = petDTO.breedText!;
    }
    if (petDTO.gender != null && petDTO.gender!.isNotEmpty) {
      request.fields['gender'] = petDTO.gender!;
    }
    if (petDTO.dob != null) {
      request.fields['dob'] = petDTO.dob!.toIso8601String().split('T').first;
    }
    if (petDTO.note != null && petDTO.note!.isNotEmpty) {
      request.fields['note'] = petDTO.note!;
    }

    if (avatarFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'avatarUrlPreview',
          avatarFile.path,
          filename: avatarFile.name,
        ),
      );
    }

    final streamed = await request.send();
    final bodyBytes = await streamed.stream.toBytes();
    return http.Response.bytes(
      bodyBytes,
      streamed.statusCode,
      headers: streamed.headers,
      request: streamed.request,
      reasonPhrase: streamed.reasonPhrase,
      isRedirect: streamed.isRedirect,
      persistentConnection: streamed.persistentConnection,
    );
  }
}
