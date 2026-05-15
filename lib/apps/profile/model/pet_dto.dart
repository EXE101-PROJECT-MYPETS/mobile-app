class PetDTO {
  final int? id;
  final int? shopId;
  final int? customerId;
  final int? speciesId;
  final int? breedId;
  final String? breedText;
  final String? avatarUrl;
  final String name;
  final String? gender;
  final DateTime? dob;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PetDTO({
    this.id,
    this.shopId,
    this.customerId,
    this.speciesId,
    this.breedId,
    this.breedText,
    this.avatarUrl,
    required this.name,
    this.gender,
    this.dob,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory PetDTO.fromJson(Map<String, dynamic> json) {
    return PetDTO(
      id: json['id'] as int?,
      shopId: json['shopId'] as int?,
      customerId: json['customerId'] as int?,
      speciesId: json['speciesId'] as int?,
      breedId: json['breedId'] as int?,
      breedText: json['breedText'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      name: json['name'] as String? ?? 'Unknown',
      gender: json['gender'] as String?,
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
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
      'shopId': shopId,
      'customerId': customerId,
      'speciesId': speciesId,
      'breedId': breedId,
      'breedText': breedText,
      'avatarUrl': avatarUrl,
      'name': name,
      'gender': gender,
      'dob': dob?.toIso8601String(),
      'note': note,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PetDTO(id: $id, name: $name, gender: $gender, dob: $dob)';
  }
}
