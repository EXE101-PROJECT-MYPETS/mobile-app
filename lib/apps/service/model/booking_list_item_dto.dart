import 'package:pawly_mobile/common/utils/image_url_util.dart';

class BookingListItemDTO {
  final int? id;
  final String? bookingCode;
  final int? shopId;
  final int? userId;
  final int? customerId;
  final int? petId;
  final String? userFullName;
  final String? userPhone;
  final String? userEmail;
  final String? userAvatarUrlPreview;
  final String? customerFullName;
  final String? customerPhone;
  final String? customerEmail;
  final String? petName;
  final String? startAt;
  final String? endAt;
  final List<BookingLineItemDTO> items;
  final num? totalAmount;
  final String? status;
  final String? statusLabel;
  final String? source;
  final String? note;
  final String? createdAt;

  BookingListItemDTO({
    this.id,
    this.bookingCode,
    this.shopId,
    this.userId,
    this.customerId,
    this.petId,
    this.userFullName,
    this.userPhone,
    this.userEmail,
    this.userAvatarUrlPreview,
    this.customerFullName,
    this.customerPhone,
    this.customerEmail,
    this.petName,
    this.startAt,
    this.endAt,
    this.items = const [],
    this.totalAmount,
    this.status,
    this.statusLabel,
    this.source,
    this.note,
    this.createdAt,
  });

  factory BookingListItemDTO.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List?;
    List<BookingLineItemDTO> itemsList = rawItems != null
        ? rawItems
            .map((e) => BookingLineItemDTO.fromJson(e as Map<String, dynamic>))
            .toList()
        : [];

    return BookingListItemDTO(
      id: json['id'] as int?,
      bookingCode: json['bookingCode'] as String?,
      shopId: json['shopId'] as int?,
      userId: json['userId'] as int?,
      customerId: json['customerId'] as int?,
      petId: json['petId'] as int?,
      userFullName: json['userFullName'] as String?,
      userPhone: json['userPhone'] as String?,
      userEmail: json['userEmail'] as String?,
      userAvatarUrlPreview:
          ImageUrlUtil.buildPublicUrl(json['userAvatarUrlPreview'] as String?),
      customerFullName: json['customerFullName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      customerEmail: json['customerEmail'] as String?,
      petName: json['petName'] as String?,
      startAt: json['startAt'] as String?,
      endAt: json['endAt'] as String?,
      items: itemsList,
      totalAmount: json['totalAmount'] as num?,
      status: json['status'] as String?,
      statusLabel: json['statusLabel'] as String?,
      source: json['source'] as String?,
      note: json['note'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}

class BookingLineItemDTO {
  final int? bookingItemId;
  final String? itemType;
  final int? refId;
  final int? productId;
  final int? serviceId;
  final String? name;
  final int? petId;
  final String? petName;
  final String? serviceType;
  final String? veterinaryServiceType;
  final int? vaccineId;
  final String? vaccineName;
  final int? quantity;
  final num? unitPrice;
  final num? amount;

  BookingLineItemDTO({
    this.bookingItemId,
    this.itemType,
    this.refId,
    this.productId,
    this.serviceId,
    this.name,
    this.petId,
    this.petName,
    this.serviceType,
    this.veterinaryServiceType,
    this.vaccineId,
    this.vaccineName,
    this.quantity,
    this.unitPrice,
    this.amount,
  });

  factory BookingLineItemDTO.fromJson(Map<String, dynamic> json) {
    return BookingLineItemDTO(
      bookingItemId: json['bookingItemId'] as int?,
      itemType: json['itemType'] as String?,
      refId: json['refId'] as int?,
      productId: json['productId'] as int?,
      serviceId: json['serviceId'] as int?,
      name: json['name'] as String?,
      petId: json['petId'] as int?,
      petName: json['petName'] as String?,
      serviceType: json['serviceType'] as String?,
      veterinaryServiceType: json['veterinaryServiceType'] as String?,
      vaccineId: json['vaccineId'] as int?,
      vaccineName: json['vaccineName'] as String?,
      quantity: json['quantity'] as int?,
      unitPrice: json['unitPrice'] as num?,
      amount: json['amount'] as num?,
    );
  }
}
