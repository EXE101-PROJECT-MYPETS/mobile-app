import 'package:petpee_mobile/common/config/api_config.dart';

class ShopPublicContactDTO {
  final String? name;
  final String? phone;
  final String? email;

  const ShopPublicContactDTO({this.name, this.phone, this.email});

  factory ShopPublicContactDTO.fromJson(Map<String, dynamic> json) {
    String? getString(dynamic value) {
      if (value == null) return null;
      return value is String ? value : value.toString();
    }

    return ShopPublicContactDTO(
      name: getString(json['name']),
      phone: getString(json['phone']),
      email: getString(json['email']),
    );
  }
}

class ShopPublicDTO {
  final int? id;
  final String? name;
  final String? imageUrl;
  final double? rating;
  final int? productCount;
  final List<String> badges;
  final String? address;
  final ShopPublicContactDTO? contact;

  const ShopPublicDTO({
    this.id,
    this.name,
    this.imageUrl,
    this.rating,
    this.productCount,
    this.badges = const [],
    this.address,
    this.contact,
  });

  factory ShopPublicDTO.fromJson(Map<String, dynamic> json) {
    String? getString(dynamic value) {
      if (value == null) return null;
      return value is String ? value : value.toString();
    }

    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return const [];
    }

    final contactJson = json['contact'];

    return ShopPublicDTO(
      id: json['id'] as int?,
      name: getString(json['name']),
      imageUrl: ApiConfig.formatImageUrl(getString(json['imageUrl'])),
      rating: (json['rating'] as num?)?.toDouble(),
      productCount: json['productCount'] as int?,
      badges: parseStringList(json['badges']),
      address: getString(json['address']),
      contact: contactJson is Map<String, dynamic>
          ? ShopPublicContactDTO.fromJson(contactJson)
          : null,
    );
  }
}
