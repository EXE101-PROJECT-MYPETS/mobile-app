import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/api_config.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.customerLoginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      // Decode error from BE
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['message'] ?? 'Đăng nhập thất bại');
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? address,
    int? age,
    XFile? avatar,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.registerUrl));

    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['fullName'] = fullName;
    request.fields['phone'] = phone;

    if (address != null && address.isNotEmpty) {
      request.fields['address'] = address;
    }
    if (age != null) {
      request.fields['age'] = age.toString();
    }

    if (avatar != null) {
      String mimeType = avatar.mimeType ?? 'image/jpeg';
      final type = mimeType.split('/')[0];
      final subtype = mimeType.split('/').length > 1 ? mimeType.split('/')[1] : 'jpeg';

      request.files.add(await http.MultipartFile.fromPath(
        'avatarUrlPreview',
        avatar.path,
        contentType: MediaType(type, subtype),
      ));
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseData);
    } else {
      final errorData = jsonDecode(responseData);
      throw Exception(errorData['message'] ?? 'Đăng ký thất bại');
    }
  }
}
