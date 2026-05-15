class OrderItemRequest {
  final int productId;
  final int qty;
  final int unitPrice;

  const OrderItemRequest({
    required this.productId,
    required this.qty,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {'productId': productId, 'qty': qty, 'unitPrice': unitPrice};
  }
}

class CreateOrderRequest {
  final int userId;
  final int userAddressId;
  final String source;
  final int shippingFee;
  final int discountAmount;
  final String note;
  final List<OrderItemRequest> items;

  const CreateOrderRequest({
    required this.userId,
    required this.userAddressId,
    this.source = 'ONLINE',
    required this.shippingFee,
    this.discountAmount = 0,
    this.note = '',
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userAddressId': userAddressId,
      'source': source,
      'shippingFee': shippingFee,
      'discountAmount': discountAmount,
      'note': note,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
