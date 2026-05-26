import 'package:petpee_mobile/common/utils/image_url_util.dart';

class ServiceDetailDTO {
  const ServiceDetailDTO({
    this.id,
    this.shopId,
    this.shopName,
    this.shopPhone,
    this.shopAddress,
    this.shopImageUrl,
    this.shopLat,
    this.shopLng,
    this.distanceKm,
    this.name,
    this.durationMin,
    this.basePrice,
    this.categoryId,
    this.categoryName,
    this.serviceType,
    this.veterinaryServiceType,
    this.vaccineId,
    this.vaccineName,
    this.imageUrl,
    this.active,
  });

  final int? id;
  final int? shopId;
  final String? shopName;
  final String? shopPhone;
  final String? shopAddress;
  final String? shopImageUrl;
  final double? shopLat;
  final double? shopLng;
  final double? distanceKm;
  final String? name;
  final int? durationMin;
  final num? basePrice;
  final int? categoryId;
  final String? categoryName;
  final String? serviceType;
  final String? veterinaryServiceType;
  final int? vaccineId;
  final String? vaccineName;
  final String? imageUrl;
  final bool? active;

  factory ServiceDetailDTO.fromJson(Map<String, dynamic> json) {
    return ServiceDetailDTO(
      id: _asInt(json['id']),
      shopId: _asInt(json['shopId']),
      shopName: _asString(json['shopName']),
      shopPhone: _asString(json['shopPhone']),
      shopAddress: _asString(json['shopAddress']),
      shopImageUrl: ImageUrlUtil.buildPublicUrl(
        _asString(json['shopImageUrl']),
      ),
      shopLat: _asDouble(json['shopLat']),
      shopLng: _asDouble(json['shopLng']),
      distanceKm: _asDouble(json['distanceKm']),
      name: _asString(json['name']),
      durationMin: _asInt(json['durationMin']),
      basePrice: _asNum(json['basePrice']),
      categoryId: _asInt(json['categoryId']),
      categoryName: _asString(json['categoryName']),
      serviceType: _asString(json['serviceType']),
      veterinaryServiceType: _asString(json['veterinaryServiceType']),
      vaccineId: _asInt(json['vaccineId']),
      vaccineName: _asString(json['vaccineName']),
      imageUrl: ImageUrlUtil.buildPublicUrl(_asString(json['imageUrl'])),
      active: _asBool(json['active']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'shopName': shopName,
      'shopPhone': shopPhone,
      'shopAddress': shopAddress,
      'shopImageUrl': shopImageUrl,
      'shopLat': shopLat,
      'shopLng': shopLng,
      'distanceKm': distanceKm,
      'name': name,
      'durationMin': durationMin,
      'basePrice': basePrice,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'serviceType': serviceType,
      'veterinaryServiceType': veterinaryServiceType,
      'vaccineId': vaccineId,
      'vaccineName': vaccineName,
      'imageUrl': imageUrl,
      'active': active,
    };
  }

  static String? _asString(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static num? _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }

  static bool? _asBool(dynamic value) {
    if (value is bool) return value;
    final text = value?.toString().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
    return null;
  }
}
