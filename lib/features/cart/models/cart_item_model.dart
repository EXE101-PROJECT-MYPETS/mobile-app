import '../../../core/models/product_model.dart';

class CartItemModel {
  final String id;
  final ProductModel product;
  final String shopName;
  int quantity;
  bool isSelected;

  CartItemModel({
    required this.id,
    required this.product,
    required this.shopName,
    this.quantity = 1,
    this.isSelected = false,
  });

  // Giả lập giá tiền từ string "150.000đ" sang double để tiện tính toán
  double get priceAsDouble {
    try {
      String cleanPrice = product.price.replaceAll('đ', '').replaceAll('.', '').trim();
      return double.parse(cleanPrice);
    } catch (_) {
      return 0.0;
    }
  }
}
