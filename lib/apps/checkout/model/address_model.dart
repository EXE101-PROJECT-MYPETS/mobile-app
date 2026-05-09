class AddressModel {
  final String id;
  final String name;
  final String phone;
  final String location; // e.g. Tên đường, Số nhà
  final String region; // e.g. Xã..., Huyện..., Tỉnh...
  final bool isDefault;
  final String type; // e.g. 'Văn Phòng', 'Nhà Riêng'

  AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.location,
    required this.region,
    this.isDefault = false,
    this.type = 'Nhà Riêng',
  });
}
