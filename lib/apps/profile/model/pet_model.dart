import 'package:petpee_mobile/apps/profile/model/pet_dto.dart';

class PetModel {
  final int? id;
  final int? shopId;
  final int? customerId;
  final int? speciesId;
  final int? breedId;
  final String name;
  final String? breedText;
  final String? avatarUrl;
  final String? gender;
  final DateTime? dob;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Fallback fields for display purposes
  final String? type; // Chó, Mèo (deprecated - use speciesId instead)
  final String? age;
  final String? shopName;

  PetModel({
    this.id,
    this.shopId,
    this.customerId,
    this.speciesId,
    this.breedId,
    required this.name,
    this.breedText,
    this.avatarUrl,
    this.gender,
    this.dob,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.type,
    this.age,
    this.shopName,
  });

  /// Convert from PetDTO (BE response)
  factory PetModel.fromDTO(PetDTO dto) {
    return PetModel(
      id: dto.id,
      shopId: dto.shopId,
      customerId: dto.customerId,
      speciesId: dto.speciesId,
      breedId: dto.breedId,
      name: dto.name,
      breedText: dto.breedText,
      avatarUrl: dto.avatarUrl,
      gender: dto.gender,
      dob: dto.dob,
      note: dto.note,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  /// Convert to PetDTO for sending to BE
  PetDTO toDTO() {
    return PetDTO(
      id: id,
      shopId: shopId,
      customerId: customerId,
      speciesId: speciesId,
      breedId: breedId,
      name: name,
      breedText: breedText,
      avatarUrl: avatarUrl,
      gender: gender,
      dob: dob,
      note: note,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
