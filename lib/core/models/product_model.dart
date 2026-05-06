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
}
