import 'package:pawly_mobile/common/utils/image_url_util.dart';

class ProductPublicReviewDTO {
  final int? id;
  final int? productId;
  final String? authorName;
  final double? rating;
  final String? comment;
  final List<String> images;
  final String? variant;
  final String? createdAt;
  final int? likeCount;
  final bool? verifiedPurchase;

  ProductPublicReviewDTO({
    this.id,
    this.productId,
    this.authorName,
    this.rating,
    this.comment,
    this.images = const [],
    this.variant,
    this.createdAt,
    this.likeCount,
    this.verifiedPurchase,
  });

  factory ProductPublicReviewDTO.fromJson(Map<String, dynamic> json) {
    final images = json['images'] ?? json['imageUrls'] ?? json['thumbnails'];
    final user = json['user'];
    return ProductPublicReviewDTO(
      id: json['id'] as int?,
      productId: json['productId'] as int?,
      authorName:
          json['authorName'] as String? ??
          json['customerName'] as String? ??
          (user is Map<String, dynamic> ? user['name'] as String? : null),
      rating:
          (json['rating'] as num?)?.toDouble() ??
          (json['star'] as num?)?.toDouble(),
      comment: json['comment'] as String? ?? json['content'] as String?,
      images: images is List
          ? ImageUrlUtil.buildPublicUrls(images.whereType<String>())
          : <String>[],
      variant: json['variant'] as String?,
      createdAt: json['createdAt'] as String? ?? json['date'] as String?,
      likeCount:
          json['likeCount'] as int? ??
          json['helpfulCount'] as int? ??
          json['usefulCount'] as int?,
      verifiedPurchase:
          json['verifiedPurchase'] as bool? ?? json['isVerified'] as bool?,
    );
  }
}
