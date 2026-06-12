import 'package:pawly_mobile/common/utils/image_url_util.dart';

class ShopMarkerDTO {
  final int? id;
  final String? name;
  final double? lat;
  final double? lng;
  final String? address;
  final String? imageUrl;
  final double? rating;

  const ShopMarkerDTO({
    this.id,
    this.name,
    this.lat,
    this.lng,
    this.address,
    this.imageUrl,
    this.rating,
  });

  bool get hasValidCoordinates => lat != null && lng != null;

  factory ShopMarkerDTO.fromJson(Map<String, dynamic> json) {
    String? getString(dynamic value) {
      if (value == null) return null;
      return value is String ? value : value.toString();
    }

    double? getDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int? getInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      return int.tryParse(value.toString());
    }

    return ShopMarkerDTO(
      id: getInt(json['id']),
      name: getString(json['name']),
      lat: getDouble(json['lat']),
      lng: getDouble(json['lng']),
      address: getString(json['address']),
      imageUrl: ImageUrlUtil.buildPublicUrl(getString(json['imageUrl'])),
      rating: getDouble(json['rating']),
    );
  }
}
