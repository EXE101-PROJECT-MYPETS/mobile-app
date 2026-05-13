import 'package:petpee_mobile/common/utils/image_url_util.dart';

class ServicePublicDTO {
  final ServiceInfoDTO? service;
  final ShopInfoDTO? shop;
  final double? distanceKm;

  ServicePublicDTO({
    this.service,
    this.shop,
    this.distanceKm,
  });

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
    this.imageUrl,
    this.active,
    this.rating,
    this.ratingCount,
  });

  factory ServiceInfoDTO.fromJson(Map<String, dynamic> json) {
    return ServiceInfoDTO(
      id: json['id'] as int?,
      name: json['name'] as String?,
      durationMin: json['durationMin'] as int?,
      basePrice: json['basePrice'] as int?,
      categoryId: json['categoryId'] as int?,
      imageUrl: ImageUrlUtil.buildPublicUrl(json['imageUrl'] as String?),
      active: json['active'] as bool?,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['ratingCount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'durationMin': durationMin,
      'basePrice': basePrice,
      'categoryId': categoryId,
      'imageUrl': imageUrl,
      'active': active,
      'rating': rating,
      'ratingCount': ratingCount,
    };
  }
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
      shopImageUrl: ImageUrlUtil.buildPublicUrl(json['shopImageUrl'] as String?),
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
