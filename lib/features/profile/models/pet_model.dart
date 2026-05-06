class PetModel {
  final String id;
  final String name;
  final String type; // Chó, Mèo...
  final String breed;
  final String shopName;
  final String gender;
  final String age;
  final String note;
  final String image;

  PetModel({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.shopName,
    required this.gender,
    required this.age,
    required this.note,
    required this.image,
  });
}
