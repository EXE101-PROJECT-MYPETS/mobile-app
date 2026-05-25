class AddressModel {
  final String id;
  final String? userId;
  final String name;
  final String phone;
  final String location; // e.g. Tên đường, Số nhà
  final String region; // e.g. Xã..., Huyện..., Tỉnh...
  final String province;
  final String district;
  final String ward;
  final String hamlet;
  final bool isDefault;
  final String type; // e.g. 'Văn Phòng', 'Nhà Riêng'

  AddressModel({
    required this.id,
    this.userId,
    required this.name,
    required this.phone,
    required this.location,
    required this.region,
    this.province = '',
    this.district = '',
    this.ward = '',
    this.hamlet = '',
    this.isDefault = false,
    this.type = 'Nhà Riêng',
  });

  factory AddressModel.fromApi(Map<String, dynamic> json) {
    final ward = _readString(json['ward']);
    final district = _readString(json['district']);
    final province = _readString(json['province']);
    final hamlet = _readString(json['hamlet']);
    final regionParts = [
      ward,
      district,
      province,
    ].where((part) => part.isNotEmpty).toList();

    return AddressModel(
      id: ((json['id'] as num?)?.toInt() ?? 0).toString(),
      userId: ((json['userId'] as num?)?.toInt())?.toString(),
      name: _readString(json['name']),
      phone: _readString(json['tel']),
      location: _readString(json['address']),
      region: regionParts.join(', '),
      province: province,
      district: district,
      ward: ward,
      hamlet: hamlet,
      isDefault: _readBool(json['isDefault']),
      type: hamlet.isNotEmpty ? hamlet : 'Nhà Riêng',
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'tel': phone,
      'address': location,
      'province': province,
      'district': district,
      'ward': ward,
      'hamlet': hamlet,
      'isDefault': isDefault,
    };
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }
}
