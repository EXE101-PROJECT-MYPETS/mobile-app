class CheckoutResponseModel {
  final int? orderId;
  final String? orderCode;
  final List<int> bookingIds;
  final int productSubtotalAmount;
  final int serviceSubtotalAmount;
  final int subtotalAmount;
  final int shippingFee;
  final int pickupFee;
  final int discountAmount;
  final int totalAmount;

  const CheckoutResponseModel({
    this.orderId,
    this.orderCode,
    this.bookingIds = const [],
    this.productSubtotalAmount = 0,
    this.serviceSubtotalAmount = 0,
    this.subtotalAmount = 0,
    this.shippingFee = 0,
    this.pickupFee = 0,
    this.discountAmount = 0,
    this.totalAmount = 0,
  });

  factory CheckoutResponseModel.fromJson(Map<String, dynamic> json) {
    return CheckoutResponseModel(
      orderId: (json['orderId'] as num?)?.toInt(),
      orderCode: json['orderCode'] as String?,
      bookingIds: (json['bookingIds'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(),
      productSubtotalAmount: (json['productSubtotalAmount'] as num?)?.toInt() ?? 0,
      serviceSubtotalAmount: (json['serviceSubtotalAmount'] as num?)?.toInt() ?? 0,
      subtotalAmount: (json['subtotalAmount'] as num?)?.toInt() ?? 0,
      shippingFee: (json['shippingFee'] as num?)?.toInt() ?? 0,
      pickupFee: (json['pickupFee'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
    );
  }
}