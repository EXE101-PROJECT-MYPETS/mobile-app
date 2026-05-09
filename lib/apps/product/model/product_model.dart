import 'package:petpee_mobile/common/user/dto/product_dto.dart';
import 'package:petpee_mobile/common/utils/price_formatter.dart';

class ProductModel {
  final String id;
  final String name;
  final String price;
  final double rating;
  final int reviews;
  final String image;
  final String type; // 'spa', 'thu_y', 'product'
  final String category; // 'Chó', 'Mèo', 'Spa', 'Thú y', 'Cát vệ sinh', 'Sữa tắm', v.v.
  final String description;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.reviews,
    required this.image,
    required this.type,
    required this.category,
    this.description = 'Chưa có thông tin mô tả chi tiết.',
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price'] ?? '',
      rating: map['rating']?.toDouble() ?? 0.0,
      reviews: map['reviews']?.toInt() ?? 0,
      image: map['image'] ?? '',
      type: map['type'] ?? '',
      category: map['category'] ?? 'Tất cả',
      description: map['description'] ?? 'Chưa có thông tin mô tả chi tiết.',
    );
  }

  // Factory method to convert from ProductDTO
  factory ProductModel.fromDTO(ProductDTO dto) {
    return ProductModel(
      id: dto.id?.toString() ?? '',
      name: dto.name ?? 'Tên sản phẩm',
      price: PriceFormatter.formatVnd(dto.price),
      rating: dto.rating ?? 0.0,
      reviews: dto.reviewCount ?? 0,
      image: dto.imageUrls?.isNotEmpty == true ? dto.imageUrls!.first : '',
      type: _determineType(dto.categoryName),
      category: dto.categoryName ?? 'Tất cả',
      description: 'Sản phẩm chất lượng cao',
    );
  }

  // Helper method to determine product type based on category
  static String _determineType(String? categoryName) {
    if (categoryName == null) return 'product';

    final category = categoryName.toLowerCase();
    if (category.contains('spa') || category.contains('dịch vụ')) {
      return 'spa';
    } else if (category.contains('thú y') || category.contains('khám')) {
      return 'thu_y';
    } else {
      return 'product';
    }
  }
}
