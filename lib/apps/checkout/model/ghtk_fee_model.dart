/// Request body gửi lên BE để tính phí GHTK.
class GhtkFeeRequest {
  final int userAddressId;
  final num weight;
  final int value; // VNĐ
  final String transport; // "road" | "fly"

  const GhtkFeeRequest({
    required this.userAddressId,
    required this.weight,
    required this.value,
    this.transport = 'road',
  });

  Map<String, dynamic> toJson() => {
        'userAddressId': userAddressId,
        'weight': weight,
        'value': value,
        'transport': transport,
      };
}

/// Response từ BE sau khi tính phí GHTK.
class GhtkFeeResponse {
  final int fee;
  final int? shipFeeOnly;
  final String? estimatedDelivery; // thời gian giao dự kiến (có thể null)
  final String? message;

  const GhtkFeeResponse({
    required this.fee,
    this.shipFeeOnly,
    this.estimatedDelivery,
    this.message,
  });

  factory GhtkFeeResponse.fromJson(Map<String, dynamic> json) {
    final feeData = json['fee'];
    final nestedFee = feeData is Map<String, dynamic> ? feeData : null;

    return GhtkFeeResponse(
      // BE hiện trả `fee` là object từ GHTK, trong đó `fee.fee` là tổng phí chính.
      fee: _toInt(
        nestedFee?['fee'] ??
            nestedFee?['ship_fee_only'] ??
            json['fee'] ??
            json['shippingFee'],
      ),
      shipFeeOnly: _toNullableInt(nestedFee?['ship_fee_only']),
      estimatedDelivery: json['estimatedDelivery'] as String?,
      message: json['message'] as String?,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    return _toInt(value);
  }
}
