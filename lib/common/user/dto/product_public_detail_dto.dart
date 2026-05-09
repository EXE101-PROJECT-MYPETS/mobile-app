import 'package:petpee_mobile/common/utils/price_formatter.dart';

class ProductPublicDetailDTO {
  final int? id;
  final int? shopId;
  final String? shopName;
  final String? shopLogoUrl;
  final bool? shopVerified;
  final double? shopRating;
  final int? shopProductCount;

  final String? name;
  final String? sku;
  final String? categoryName;
  final String? description;
  final String? shortDescription;
  final int? price;
  final int? originalPrice;
  final int? discountPercent;
  final String? unit;
  final int? stockQty;
  final int? soldCount;
  final double? rating;
  final int? reviewCount;
  final int? totalReviews;
  final bool? active;
  final List<String> imageUrls;
  final List<String> badgeLabels;
  final List<String> highlightPoints;
  final List<String> policyHighlights;
  final List<String> availableVariants;
  final String? deliveryNote;
  final String? returnPolicy;

  ProductPublicDetailDTO({
    this.id,
    this.shopId,
    this.shopName,
    this.shopLogoUrl,
    this.shopVerified,
    this.shopRating,
    this.shopProductCount,
    this.name,
    this.sku,
    this.categoryName,
    this.description,
    this.shortDescription,
    this.price,
    this.originalPrice,
    this.discountPercent,
    this.unit,
    this.stockQty,
    this.soldCount,
    this.rating,
    this.reviewCount,
    this.totalReviews,
    this.active,
    this.imageUrls = const [],
    this.badgeLabels = const [],
    this.highlightPoints = const [],
    this.policyHighlights = const [],
    this.availableVariants = const [],
    this.deliveryNote,
    this.returnPolicy,
  });

  factory ProductPublicDetailDTO.fromJson(Map<String, dynamic> json) {
    String? _getString(dynamic value) {
      if (value == null) return null;
      return value is String ? value : value.toString();
    }

    List<String> _parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.whereType<String>().toList();
      }
      if (value is String) {
        return [value];
      }
      return [];
    }

    final shopData = json['shop'] as Map<String, dynamic>?;

    final dynamic images = json['imageUrls'] ?? json['images'] ?? json['imageUrl'];

    return ProductPublicDetailDTO(
      id: json['id'] as int?,
      shopId: json['shopId'] as int?,
      shopName: _getString(json['shopName']) ?? _getString(shopData?['name']),
      shopLogoUrl: _getString(json['shopLogoUrl']) ?? _getString(shopData?['logoUrl']) ?? _getString(shopData?['avatar']),
      shopVerified: json['shopVerified'] as bool? ?? shopData?['verified'] as bool?,
      shopRating: (json['shopRating'] as num?)?.toDouble() ?? (shopData?['rating'] as num?)?.toDouble(),
      shopProductCount: json['shopProductCount'] as int? ?? shopData?['productCount'] as int?,
      name: _getString(json['name']),
      sku: _getString(json['sku']),
      categoryName: _getString(json['categoryName']),
      description: _getString(json['description']),
      shortDescription: _getString(json['shortDescription']),
      price: json['price'] as int?,
      originalPrice: json['originalPrice'] as int?,
      discountPercent: json['discountPercent'] as int?,
      unit: _getString(json['unit']),
      stockQty: json['stockQty'] as int?,
      soldCount: json['soldCount'] as int?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int?,
      totalReviews: json['totalReviews'] as int?,
      active: json['active'] as bool?,
      imageUrls: _parseStringList(images),
      badgeLabels: _parseStringList(json['badgeLabels'] ?? json['badges']),
      highlightPoints: _parseStringList(json['highlightPoints'] ?? json['highlights'] ?? json['features']),
      policyHighlights: _parseStringList(json['policyHighlights'] ?? json['policies'] ?? json['guarantees']),
      availableVariants: _parseStringList(json['availableVariants'] ?? json['variants']),
      deliveryNote: _getString(json['deliveryNote'] ?? json['delivery']),
      returnPolicy: _getString(json['returnPolicy'] ?? json['returnPolicyText']),
    );
  }

  String get priceText => PriceFormatter.formatVnd(price);
  String get originalPriceText => originalPrice != null ? PriceFormatter.formatVnd(originalPrice, fallback: '') : '';
  String get soldText => soldCount != null ? 'Đã bán ${soldCount!}+' : 'Đã bán';
  String get stockText => stockQty != null ? 'Kho còn ${stockQty}' : 'Còn hàng';
  String get reviewSummary => reviewCount != null ? '$reviewCount đánh giá' : 'Chưa có đánh giá';
}
