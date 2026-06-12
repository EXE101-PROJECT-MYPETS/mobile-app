import 'package:pawly_mobile/common/utils/image_url_util.dart';

class ProductDTO {
  final int? id;
  final int? shopId;
  final int? categoryId;
  final String? categoryName;
  final double? rating;
  final int? reviewCount;
  final double? reviewAvg;
  final int? totalReviews;
  final String? sku;
  final String? name;
  final String? unit;
  final int? price;
  final double? weightKg;
  final bool? active;
  final int? stockQty;
  final List<String>? imageUrls;
  final String? shopProvince;

  ProductDTO({
    this.id,
    this.shopId,
    this.categoryId,
    this.categoryName,
    this.rating,
    this.reviewCount,
    this.reviewAvg,
    this.totalReviews,
    this.sku,
    this.name,
    this.unit,
    this.price,
    this.weightKg,
    this.active,
    this.stockQty,
    this.imageUrls,
    this.shopProvince,
  });

  factory ProductDTO.fromJson(Map<String, dynamic> json) {
    String? readString(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        final trimmed = value.trim();
        return trimmed.isEmpty ? null : trimmed;
      }
      final normalized = value.toString().trim();
      return normalized.isEmpty ? null : normalized;
    }

    final shopData = json['shop'] as Map<String, dynamic>?;

    return ProductDTO(
      id: json['id'] as int?,
      shopId: json['shopId'] as int?,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int?,
      reviewAvg: (json['reviewAvg'] as num?)?.toDouble(),
      totalReviews: json['totalReviews'] as int?,
      sku: json['sku'] as String?,
      name: json['name'] as String?,
      unit: json['unit'] as String?,
      price: json['price'] as int?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      active: json['active'] as bool?,
      stockQty: json['stockQty'] as int?,
      imageUrls: ImageUrlUtil.buildPublicUrls(
        (json['imageUrls'] as List<dynamic>?)?.whereType<String>(),
      ),
      shopProvince:
          readString(shopData?['province']) ??
          readString(json['province']) ??
          readString(json['shopProvince']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shopId': shopId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'rating': rating,
      'reviewCount': reviewCount,
      'reviewAvg': reviewAvg,
      'totalReviews': totalReviews,
      'sku': sku,
      'name': name,
      'unit': unit,
      'price': price,
      'weightKg': weightKg,
      'active': active,
      'stockQty': stockQty,
      'imageUrls': imageUrls,
      'shopProvince': shopProvince,
    };
  }
}
