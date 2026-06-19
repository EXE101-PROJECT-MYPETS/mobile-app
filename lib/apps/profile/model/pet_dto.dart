import 'package:pawly_mobile/common/utils/image_url_util.dart';

class PetDTO {
  final int? id;
  final int? userId;
  final int? shopId;
  final int? customerId;
  final int? speciesId;
  final String? speciesName;
  final int? breedId;
  final String? breedText;
  final String? avatarUrl;
  final String name;
  final String? gender;
  final DateTime? dob;
  final double? weightKg;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PetDTO({
    this.id,
    this.userId,
    this.shopId,
    this.customerId,
    this.speciesId,
    this.speciesName,
    this.breedId,
    this.breedText,
    this.avatarUrl,
    required this.name,
    this.gender,
    this.dob,
    this.weightKg,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory PetDTO.fromJson(Map<String, dynamic> json) {
    final avatarUrl = json['avatarUrl'];

    return PetDTO(
      id: json['id'] as int?,
      userId: json['userId'] as int?,
      shopId: json['shopId'] as int?,
      customerId: json['customerId'] as int? ?? json['userId'] as int?,
      speciesId: json['speciesId'] as int?,
      speciesName: _parseSpeciesName(json),
      breedId: json['breedId'] as int?,
      breedText: json['breedText'] as String?,
      avatarUrl: ImageUrlUtil.buildPublicUrl(avatarUrl?.toString()),
      name: json['name'] as String? ?? 'Unknown',
      gender: json['gender'] as String?,
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      weightKg: _parseDouble(json['weightKg']),
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'shopId': shopId,
      'customerId': customerId,
      'speciesId': speciesId,
      'speciesName': speciesName,
      'breedId': breedId,
      'breedText': breedText,
      'avatarUrl': avatarUrl,
      'name': name,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'weightKg': weightKg,
      'note': note,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PetDTO(id: $id, name: $name, gender: $gender, dob: $dob)';
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String? _parseSpeciesName(Map<String, dynamic> json) {
    final direct = json['speciesName']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final species = json['species'];
    if (species is Map<String, dynamic>) {
      final nested = species['name']?.toString().trim();
      if (nested != null && nested.isNotEmpty) return nested;
    }

    return null;
  }
}
