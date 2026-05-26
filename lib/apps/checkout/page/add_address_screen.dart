import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:petpee_mobile/apps/checkout/api/address_service.dart';
import 'package:petpee_mobile/common/store/app_state.dart';
import 'package:petpee_mobile/apps/checkout/model/address_model.dart';
import 'package:petpee_mobile/common/address/vietnam_address_service.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/common/toast/app_toast.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key, this.address});

  final AddressModel? address;

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final AddressService _addressService = AddressService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regionController = TextEditingController();
  final _locationController = TextEditingController();
  String _province = '';
  String _district = '';
  String _ward = '';

  bool _isSaving = false;
  bool _isDefault = false;
  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    if (address == null) return;

    _nameController.text = address.name;
    _phoneController.text = address.phone;
    _regionController.text = address.region;
    _locationController.text = address.location;
    _province = address.province;
    _district = address.district;
    _ward = address.ward;
    _isDefault = address.isDefault;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _regionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _regionController.text.isEmpty ||
        _locationController.text.isEmpty) {
      showAppToast(
        context,
        message: 'Vui lòng nhập đầy đủ thông tin',
        type: AppToastType.warning,
      );
      return;
    }

    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      showAppToast(
        context,
        message: 'Vui lòng đăng nhập để lưu địa chỉ',
        type: AppToastType.error,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final newAddress = AddressModel(
      id: widget.address?.id ?? '',
      userId: widget.address?.userId,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      region: _regionController.text.trim(),
      location: _locationController.text.trim(),
      province: _province,
      district: _district,
      ward: _ward,
      hamlet: widget.address?.hamlet ?? '',
      isDefault: _isDefault,
      type: widget.address?.type ?? 'Nhà Riêng',
    );

    try {
      final savedAddress = _isEditing
          ? await _addressService.updateCurrentUserAddress(
              accessToken: token,
              address: newAddress,
            )
          : await _addressService.createCurrentUserAddress(
              accessToken: token,
              address: newAddress,
            );
      if (!mounted) return;
      if (!_isEditing) {
        context.read<AppState>().addAddress(savedAddress);
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteAddress() async {
    final address = widget.address;
    if (address == null) return;

    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      showAppToast(
        context,
        message: 'Vui lòng đăng nhập để xóa địa chỉ',
        type: AppToastType.error,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _addressService.deleteCurrentUserAddress(
        accessToken: token,
        id: address.id,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectRegion() async {
    final result = await Navigator.push<_AddressRegionResult>(
      context,
      MaterialPageRoute(builder: (context) => const _AddressRegionScreen()),
    );

    if (!mounted || result == null) return;

    setState(() {
      _province = result.province;
      _district = result.district;
      _ward = result.ward;
      _regionController.text = result.regionText;
      if (result.locationText != null) {
        _locationController.text = result.locationText!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Sửa địa chỉ' : 'Địa chỉ mới',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Địa chỉ (dùng thông tin sau khi nhập)',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        _buildTextField('Họ và tên', _nameController),
                        _buildTextField(
                          'Số điện thoại',
                          _phoneController,
                          keyboardType: TextInputType.phone,
                        ),
                        _buildTextField(
                          'Tỉnh/Thành phố, Quận/Huyện, Phường/Xã',
                          _regionController,
                          suffixIcon: LucideIcons.chevronRight,
                          readOnly: true,
                          onTap: _selectRegion,
                        ),
                        _buildTextField(
                          'Tên đường, Toà nhà, Số nhà.',
                          _locationController,
                        ),
                      ],
                    ),
                  ),

                  // Settings
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    color: Colors.white,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Đặt làm địa chỉ mặc định',
                                style: TextStyle(fontSize: 14),
                              ),
                              Switch(
                                value: _isDefault,
                                activeThumbColor: const Color(0xFFFB7185),
                                onChanged: (val) {
                                  setState(() => _isDefault = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(
              16,
            ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
            color: Colors.white,
            child: Row(
              children: [
                if (_isEditing) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _deleteAddress,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFB7185),
                        side: const BorderSide(color: Color(0xFFFB7185)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Xóa địa chỉ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFB7185),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'HOÀN THÀNH',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
    IconData? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: InputBorder.none,
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: Colors.grey)
                : null,
          ),
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }
}

class _AddressRegionResult {
  const _AddressRegionResult({
    required this.province,
    required this.district,
    required this.ward,
    required this.regionText,
    this.locationText,
  });

  final String province;
  final String district;
  final String ward;
  final String regionText;
  final String? locationText;
}

enum _AddressRegionStep { province, district, ward }

class _AddressRegionScreen extends StatefulWidget {
  const _AddressRegionScreen();

  @override
  State<_AddressRegionScreen> createState() => _AddressRegionScreenState();
}

class _AddressRegionScreenState extends State<_AddressRegionScreen> {
  final VietnamAddressService _addressService = VietnamAddressService();
  final TextEditingController _searchController = TextEditingController();

  _AddressRegionStep _step = _AddressRegionStep.province;
  Future<List<VietnamAddressUnit>>? _future;
  VietnamAddressUnit? _province;
  VietnamAddressUnit? _district;
  String _query = '';
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _future = _addressService.fetchProvinces();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _sectionTitle {
    switch (_step) {
      case _AddressRegionStep.province:
        return 'Tỉnh/Thành phố';
      case _AddressRegionStep.district:
        return 'Quận/Huyện';
      case _AddressRegionStep.ward:
        return 'Phường/Xã';
    }
  }

  String get _hintText {
    switch (_step) {
      case _AddressRegionStep.province:
        return 'Tìm kiếm Tỉnh/Thành phố';
      case _AddressRegionStep.district:
        return 'Tìm kiếm Quận/Huyện';
      case _AddressRegionStep.ward:
        return 'Tìm kiếm Phường/Xã';
    }
  }

  void _resetSearch() {
    _searchController.clear();
    _query = '';
  }

  void _goBack() {
    if (_step == _AddressRegionStep.ward) {
      setState(() {
        _step = _AddressRegionStep.district;
        _future = _addressService.fetchDistricts(_province!.code);
        _resetSearch();
      });
      return;
    }
    if (_step == _AddressRegionStep.district) {
      setState(() {
        _step = _AddressRegionStep.province;
        _future = _addressService.fetchProvinces();
        _resetSearch();
      });
      return;
    }
    Navigator.pop(context);
  }

  void _selectUnit(VietnamAddressUnit unit) {
    if (_step == _AddressRegionStep.province) {
      setState(() {
        _province = unit;
        _district = null;
        _step = _AddressRegionStep.district;
        _future = _addressService.fetchDistricts(unit.code);
        _resetSearch();
      });
      return;
    }

    if (_step == _AddressRegionStep.district) {
      setState(() {
        _district = unit;
        _step = _AddressRegionStep.ward;
        _future = _addressService.fetchWards(unit.code);
        _resetSearch();
      });
      return;
    }

    final province = _province!;
    final district = _district!;
    Navigator.pop(
      context,
      _AddressRegionResult(
        province: province.name,
        district: district.name,
        ward: unit.name,
        regionText: '${province.name}, ${district.name}, ${unit.name}',
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Vui lòng bật dịch vụ định vị trên thiết bị');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Bạn chưa cấp quyền truy cập vị trí');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final address = await _reverseGeocode(position);

      if (!mounted) return;
      Navigator.pop(context, address);
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<_AddressRegionResult> _reverseGeocode(Position position) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'lat': position.latitude.toString(),
      'lon': position.longitude.toString(),
      'accept-language': 'vi',
      'addressdetails': '1',
    });

    final response = await http.get(
      uri,
      headers: const {
        'User-Agent': 'PetPee mobile address picker',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Không thể chuyển vị trí hiện tại thành địa chỉ');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Dữ liệu vị trí không hợp lệ');
    }

    final address = decoded['address'] is Map<String, dynamic>
        ? decoded['address'] as Map<String, dynamic>
        : const <String, dynamic>{};

    String read(List<String> keys) {
      for (final key in keys) {
        final value = address[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return '';
    }

    final province = read(['city', 'state', 'province', 'municipality']);
    final district = read(['city_district', 'district', 'county', 'suburb']);
    final ward = read([
      'quarter',
      'neighbourhood',
      'suburb',
      'village',
      'town',
    ]);
    final road = read(['road', 'pedestrian', 'residential']);
    final houseNumber = read(['house_number']);
    final locationText = [
      houseNumber,
      road,
    ].where((part) => part.isNotEmpty).join(' ').trim();
    final displayName = decoded['display_name']?.toString().trim() ?? '';
    final regionParts = [
      province,
      district,
      ward,
    ].where((part) => part.isNotEmpty).toList();

    if (regionParts.isEmpty && displayName.isEmpty) {
      throw Exception('Không tìm thấy địa chỉ từ vị trí hiện tại');
    }

    return _AddressRegionResult(
      province: province,
      district: district,
      ward: ward,
      regionText: regionParts.isNotEmpty ? regionParts.join(', ') : displayName,
      locationText: locationText.isNotEmpty ? locationText : displayName,
    );
  }

  List<VietnamAddressUnit> _filterUnits(List<VietnamAddressUnit> units) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return units;
    return units
        .where((unit) => unit.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(4, 8, 14, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _goBack,
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      color: Color(0xFFFF4F3A),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _query = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: _hintText,
                          prefixIcon: const Icon(
                            LucideIcons.search,
                            size: 18,
                            color: Color(0xFF9CA3AF),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: _isLocating ? null : _useCurrentLocation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isLocating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFF4F3A),
                                ),
                              )
                            : const Icon(
                                LucideIcons.mapPin,
                                color: Color(0xFFFF4F3A),
                                size: 20,
                              ),
                        const SizedBox(width: 10),
                        Text(
                          _isLocating
                              ? 'Đang lấy vị trí...'
                              : 'Sử dụng vị trí hiện tại của tôi',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: const Color(0xFFF5F5F5),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                _sectionTitle,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<VietnamAddressUnit>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          snapshot.error.toString().replaceFirst(
                            'Exception: ',
                            '',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final units = _filterUnits(snapshot.data ?? []);
                  if (units.isEmpty) {
                    return const Center(child: Text('Không có dữ liệu'));
                  }

                  return ListView.separated(
                    itemCount: units.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 52),
                    itemBuilder: (context, index) {
                      final unit = units[index];
                      return ListTile(
                        tileColor: Colors.white,
                        title: Text(
                          unit.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        onTap: () => _selectUnit(unit),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
