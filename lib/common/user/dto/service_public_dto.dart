import 'package:petpee_mobile/common/utils/image_url_util.dart';

class ServicePublicDTO {
  final ServiceInfoDTO? service;
  final ShopInfoDTO? shop;
  final double? distanceKm;

  ServicePublicDTO({this.service, this.shop, this.distanceKm});

  int? get id => service?.id;
  int? get shopId => shop?.shopId;
  String? get shopName => shop?.shopName;
  String? get shopImageUrl => shop?.shopImageUrl;
  String? get shopAddress => shop?.shopAddress;
  String? get shopProvince => shop?.shopProvince;
  double? get shopLat => shop?.shopLat;
  double? get shopLng => shop?.shopLng;
  String? get name => service?.name;
  int? get durationMin => service?.durationMin;
  int? get basePrice => service?.basePrice;
  int? get categoryId => service?.categoryId;
  String? get serviceType => service?.serviceType;
  String? get veterinaryServiceType => service?.veterinaryServiceType;
  int? get vaccineId => service?.vaccineId;
  String? get vaccineName => service?.vaccineName;
  String? get imageUrl => service?.imageUrl;
  bool? get active => service?.active;
  double? get rating => service?.rating;
  int? get ratingCount => service?.ratingCount;

  factory ServicePublicDTO.fromJson(Map<String, dynamic> json) {
    return ServicePublicDTO(
      service: json['service'] is Map<String, dynamic>
          ? ServiceInfoDTO.fromJson(json['service'] as Map<String, dynamic>)
          : null,
      shop: json['shop'] is Map<String, dynamic>
          ? ShopInfoDTO.fromJson(json['shop'] as Map<String, dynamic>)
          : null,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service': service?.toJson(),
      'shop': shop?.toJson(),
      'distanceKm': distanceKm,
    };
  }
}

class ServiceInfoDTO {
  final int? id;
  final String? name;
  final int? durationMin;
  final int? basePrice;
  final int? categoryId;
  final String? serviceType;
  final String? veterinaryServiceType;
  final int? vaccineId;
  final String? vaccineName;
  final String? imageUrl;
  final bool? active;
  final double? rating;
  final int? ratingCount;

  ServiceInfoDTO({
    this.id,
    this.name,
    this.durationMin,
    this.basePrice,
    this.categoryId,
    this.serviceType,
    this.veterinaryServiceType,
    this.vaccineId,
    this.vaccineName,
    this.imageUrl,
    this.active,
    this.rating,
    this.ratingCount,
  });

  factory ServiceInfoDTO.fromJson(Map<String, dynamic> json) {
    return ServiceInfoDTO(
      id: _asInt(json['id']),
      name: json['name'] as String?,
      durationMin: _asInt(json['durationMin']),
      basePrice: _asInt(json['basePrice']),
      categoryId: _asInt(json['categoryId']),
      serviceType: json['serviceType'] as String?,
      veterinaryServiceType: json['veterinaryServiceType'] as String?,
      vaccineId: _asInt(json['vaccineId']),
      vaccineName: json['vaccineName'] as String?,
      imageUrl: ImageUrlUtil.buildPublicUrl(json['imageUrl'] as String?),
      active: json['active'] as bool?,
      rating: _asDouble(json['rating']),
      ratingCount: _asInt(json['ratingCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'durationMin': durationMin,
      'basePrice': basePrice,
      'categoryId': categoryId,
      'serviceType': serviceType,
      'veterinaryServiceType': veterinaryServiceType,
      'vaccineId': vaccineId,
      'vaccineName': vaccineName,
      'imageUrl': imageUrl,
      'active': active,
      'rating': rating,
      'ratingCount': ratingCount,
    };
  }
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

class ShopInfoDTO {
  final int? shopId;
  final String? shopName;
  final String? shopImageUrl;
  final String? shopAddress;
  final String? shopProvince;
  final double? shopLat;
  final double? shopLng;

  ShopInfoDTO({
    this.shopId,
    this.shopName,
    this.shopImageUrl,
    this.shopAddress,
    this.shopProvince,
    this.shopLat,
    this.shopLng,
  });

  factory ShopInfoDTO.fromJson(Map<String, dynamic> json) {
    return ShopInfoDTO(
      shopId: json['shopId'] as int?,
      shopName: json['shopName'] as String?,
      shopImageUrl: ImageUrlUtil.buildPublicUrl(
        json['shopImageUrl'] as String?,
      ),
      shopAddress: json['shopAddress'] as String?,
      shopProvince: json['shopProvince'] as String?,
      shopLat: (json['shopLat'] as num?)?.toDouble(),
      shopLng: (json['shopLng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopId': shopId,
      'shopName': shopName,
      'shopImageUrl': shopImageUrl,
      'shopAddress': shopAddress,
      'shopProvince': shopProvince,
      'shopLat': shopLat,
      'shopLng': shopLng,
    };
  }
}
