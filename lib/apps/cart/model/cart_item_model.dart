import 'package:pawly_mobile/common/utils/image_url_util.dart';

class CartItem {
  final String id;
  final bool isService;
  final int shopId;
  final String shopName;
  final int? productId;
  final int? serviceId;
  final String name;
  final String imageUrl;
  final String? description;
  final int unitPrice;
  final double? weightKg;
  final int? durationMin;
  int quantity;
  bool isSelected;

  CartItem._({
    required this.id,
    required this.isService,
    required this.shopId,
    required this.shopName,
    required this.productId,
    required this.serviceId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    this.weightKg,
    required this.quantity,
    required this.isSelected,
    this.description,
    this.durationMin,
  });

  factory CartItem.product({
    required String id,
    required int shopId,
    required String shopName,
    required int productId,
    required String name,
    required String imageUrl,
    required int unitPrice,
    int quantity = 1,
    bool isSelected = false,
    String? description,
    double? weightKg,
  }) {
    return CartItem._(
      id: id,
      isService: false,
      shopId: shopId,
      shopName: shopName,
      productId: productId,
      serviceId: null,
      name: name,
      imageUrl: ImageUrlUtil.buildPublicUrl(imageUrl) ?? '',
      unitPrice: unitPrice,
      weightKg: weightKg,
      quantity: quantity,
      isSelected: isSelected,
      description: description,
    );
  }

  factory CartItem.service({
    required String id,
    required int shopId,
    required String shopName,
    required int serviceId,
    required String name,
    required String imageUrl,
    required int unitPrice,
    required int durationMin,
    int quantity = 1,
    bool isSelected = false,
    String? description,
  }) {
    return CartItem._(
      id: id,
      isService: true,
      shopId: shopId,
      shopName: shopName,
      productId: null,
      serviceId: serviceId,
      name: name,
      imageUrl: ImageUrlUtil.buildPublicUrl(imageUrl) ?? '',
      unitPrice: unitPrice,
      weightKg: null,
      quantity: quantity,
      isSelected: isSelected,
      description: description,
      durationMin: durationMin,
    );
  }

  int get amount => unitPrice * quantity;

  CartItem copyWith({int? quantity, bool? isSelected, double? weightKg}) {
    return CartItem._(
      id: id,
      isService: isService,
      shopId: shopId,
      shopName: shopName,
      productId: productId,
      serviceId: serviceId,
      name: name,
      imageUrl: ImageUrlUtil.buildPublicUrl(imageUrl) ?? '',
      unitPrice: unitPrice,
      weightKg: weightKg ?? this.weightKg,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
      description: description,
      durationMin: durationMin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'isService': isService,
      'shopId': shopId,
      'shopName': shopName,
      'productId': productId,
      'serviceId': serviceId,
      'name': name,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'weightKg': weightKg,
      'quantity': quantity,
      'isSelected': isSelected,
      'description': description,
      'durationMin': durationMin,
    };
  }

  factory CartItem.fromMap(Map<dynamic, dynamic> map) {
    return CartItem._(
      id: map['id'] ?? '',
      isService: map['isService'] ?? false,
      shopId: map['shopId'] ?? 0,
      shopName: map['shopName'] ?? '',
      productId: map['productId'],
      serviceId: map['serviceId'],
      name: map['name'] ?? '',
      imageUrl: ImageUrlUtil.buildPublicUrl(map['imageUrl']?.toString()) ?? '',
      unitPrice: map['unitPrice'] ?? 0,
      weightKg: _parseDouble(map['weightKg']),
      quantity: map['quantity'] ?? 1,
      isSelected: map['isSelected'] ?? false,
      description: map['description'],
      durationMin: map['durationMin'],
    );
  }
}

typedef CartItemModel = CartItem;

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
