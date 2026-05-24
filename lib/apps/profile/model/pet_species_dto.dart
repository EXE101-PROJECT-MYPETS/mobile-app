class PetSpeciesDTO {
  final int id;
  final String name;

  PetSpeciesDTO({required this.id, required this.name});

  factory PetSpeciesDTO.fromJson(Map<String, dynamic> json) {
    return PetSpeciesDTO(id: json['id'] as int, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
