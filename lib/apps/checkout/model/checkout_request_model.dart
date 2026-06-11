import 'package:intl/intl.dart';

class CheckoutProductOrderRequest {
  final int productId;
  final int qty;
  final int unitPrice;

  const CheckoutProductOrderRequest({
    required this.productId,
    required this.qty,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() {
    return {'productId': productId, 'qty': qty, 'unitPrice': unitPrice};
  }
}

class CheckoutServiceBookingRequest {
  final int serviceId;
  final int petId;
  final DateTime bookingDate;
  final DateTime bookingTime;
  final int? staffUserId;
  final String? note;

  const CheckoutServiceBookingRequest({
    required this.serviceId,
    required this.petId,
    required this.bookingDate,
    required this.bookingTime,
    this.staffUserId,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'petId': petId,
      'bookingDate': DateFormat('yyyy-MM-dd').format(bookingDate),
      'bookingTime': DateFormat('HH:mm:ss').format(bookingTime),
      if (staffUserId != null) 'staffUserId': staffUserId,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
    };
  }
}

class CheckoutRequestModel {
  final int shopId;
  final int userId;
  final int? customerId;
  final String receiverName;
  final String receiverPhone;
  final String shippingAddress;
  final int shippingFee;
  final int pickupFee;
  final int discountAmount;
  final String? note;
  final List<CheckoutProductOrderRequest> productOrders;
  final List<CheckoutServiceBookingRequest> serviceBookings;

  const CheckoutRequestModel({
    required this.shopId,
    required this.userId,
    this.customerId,
    required this.receiverName,
    required this.receiverPhone,
    required this.shippingAddress,
    required this.shippingFee,
    this.pickupFee = 0,
    this.discountAmount = 0,
    this.note,
    required this.productOrders,
    required this.serviceBookings,
  });

  Map<String, dynamic> toJson() {
    return {
      'shopId': shopId,
      'userId': userId,
      if (customerId != null) 'customerId': customerId,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'shippingAddress': shippingAddress,
      'shippingFee': shippingFee,
      'pickupFee': pickupFee,
      'discountAmount': discountAmount,
      if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      'productOrders': productOrders.map((item) => item.toJson()).toList(),
      'serviceBookings': serviceBookings.map((item) => item.toJson()).toList(),
    };
  }
}
