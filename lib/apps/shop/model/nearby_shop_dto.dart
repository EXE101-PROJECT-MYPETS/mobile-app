import 'package:pawly_mobile/common/config/api_config.dart';

class NearbyShopDTO {
  const NearbyShopDTO({
    this.id,
    this.name,
    this.imageUrl,
    this.coverImageUrl,
    this.rating,
    this.productCount,
    this.serviceCount,
    this.address,
    this.lat,
    this.lng,
    this.distanceKm,
    this.openingHours,
    this.closingHours,
  });

  final int? id;
  final String? name;
  final String? imageUrl;
  final String? coverImageUrl;
  final double? rating;
  final int? productCount;
  final int? serviceCount;
  final String? address;
  final double? lat;
  final double? lng;
  final double? distanceKm;
  final String? openingHours;
  final String? closingHours;

  String? get displayImageUrl {
    final primary = imageUrl?.trim();
    if (primary != null && primary.isNotEmpty) return primary;
    final cover = coverImageUrl?.trim();
    if (cover != null && cover.isNotEmpty) return cover;
    return null;
  }

  factory NearbyShopDTO.fromJson(Map<String, dynamic> json) {
    return NearbyShopDTO(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      imageUrl: ApiConfig.formatImageUrl(_asString(json['imageUrl'])),
      coverImageUrl: ApiConfig.formatImageUrl(_asString(json['coverImageUrl'])),
      rating: _asDouble(json['rating']),
      productCount: _asInt(json['productCount']),
      serviceCount: _asInt(json['serviceCount']),
      address: _asString(json['address']),
      lat: _asDouble(json['lat']),
      lng: _asDouble(json['lng']),
      distanceKm: _asDouble(json['distanceKm']),
      openingHours: _asString(json['openingHours']),
      closingHours: _asString(json['closingHours']),
    );
  }
}

String? _asString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
