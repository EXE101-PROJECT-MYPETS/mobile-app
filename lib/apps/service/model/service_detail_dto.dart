import 'package:pawly_mobile/common/utils/image_url_util.dart';

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
    this.rating,
    this.ratingCount,
    this.reviews,
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
  final double? rating;
  final int? ratingCount;
  final List<ServiceDetailReviewDTO>? reviews;

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
      rating: _asDouble(json['rating']),
      ratingCount: _asInt(json['ratingCount']),
      reviews: _asReviews(json['reviews']),
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
      'rating': rating,
      'ratingCount': ratingCount,
      'reviews': reviews?.map((review) => review.toJson()).toList(),
    };
  }

  static List<ServiceDetailReviewDTO> _asReviews(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(ServiceDetailReviewDTO.fromJson)
        .toList();
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

class ServiceDetailReviewDTO {
  const ServiceDetailReviewDTO({
    this.id,
    this.star,
    this.content,
    this.user,
    this.date,
  });

  final int? id;
  final int? star;
  final String? content;
  final ServiceDetailReviewUserDTO? user;
  final String? date;

  factory ServiceDetailReviewDTO.fromJson(Map<String, dynamic> json) {
    return ServiceDetailReviewDTO(
      id: ServiceDetailDTO._asInt(json['id']),
      star: ServiceDetailDTO._asInt(json['star']),
      content: ServiceDetailDTO._asString(json['content']),
      user: json['user'] is Map<String, dynamic>
          ? ServiceDetailReviewUserDTO.fromJson(
              json['user'] as Map<String, dynamic>,
            )
          : null,
      date: ServiceDetailDTO._asString(json['date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'star': star,
      'content': content,
      'user': user?.toJson(),
      'date': date,
    };
  }
}

class ServiceDetailReviewUserDTO {
  const ServiceDetailReviewUserDTO({
    this.id,
    this.fullName,
    this.email,
    this.avatarUrl,
  });

  final int? id;
  final String? fullName;
  final String? email;
  final String? avatarUrl;

  factory ServiceDetailReviewUserDTO.fromJson(Map<String, dynamic> json) {
    return ServiceDetailReviewUserDTO(
      id: ServiceDetailDTO._asInt(json['id']),
      fullName:
          ServiceDetailDTO._asString(json['fullName']) ??
          ServiceDetailDTO._asString(json['name']),
      email: ServiceDetailDTO._asString(json['email']),
      avatarUrl: ImageUrlUtil.buildPublicUrl(
        ServiceDetailDTO._asString(
          json['avatarUrl'] ?? json['avatarUrlPreview'],
        ),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }
}
