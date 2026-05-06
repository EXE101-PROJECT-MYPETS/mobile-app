  class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String phone;
  final String? address;
  final int? age;
  final String? avatarUrlPreview;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    this.address,
    this.age,
    this.avatarUrlPreview,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'],
      age: json['age'],
      avatarUrlPreview: json['avatarUrlPreview'],
      role: json['role'] ?? 'CUSTOMER',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'address': address,
      'age': age,
      'avatarUrlPreview': avatarUrlPreview,
      'role': role,
    };
  }
}
