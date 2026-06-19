import 'package:pawly_mobile/common/utils/image_url_util.dart';

class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String phone;
  final String? status;
  final String? address;
  final int? age;
  final String? avatarUrlPreview;
  final String role;
  final String? createdAt;
  final String? updatedAt;
  final String? lastLoginAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    this.status,
    this.address,
    this.age,
    this.avatarUrlPreview,
    required this.role,
    this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final avatarUrlPreview = json['avatarUrlPreview'];

    return UserModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      status: json['status'],
      address: json['address'],
      age: (json['age'] as num?)?.toInt(),
      avatarUrlPreview: ImageUrlUtil.buildPublicUrl(
        avatarUrlPreview?.toString(),
      ),
      role: json['role'] ?? 'CUSTOMER',
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
      lastLoginAt: json['lastLoginAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'status': status,
      'address': address,
      'age': age,
      'avatarUrlPreview': avatarUrlPreview,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLoginAt': lastLoginAt,
    };
  }
}
