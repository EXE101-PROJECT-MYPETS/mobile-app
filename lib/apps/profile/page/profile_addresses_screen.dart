import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pawly_mobile/apps/checkout/page/add_address_screen.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pawly_mobile/apps/checkout/api/address_service.dart';
import 'package:pawly_mobile/apps/checkout/model/address_model.dart';
import 'package:pawly_mobile/common/auth/store/auth_provider.dart';
import 'package:pawly_mobile/common/toast/app_toast.dart';
import 'package:provider/provider.dart';

class ProfileAddressesScreen extends StatefulWidget {
  const ProfileAddressesScreen({super.key});

  @override
  State<ProfileAddressesScreen> createState() => _ProfileAddressesScreenState();
}

class _ProfileAddressesScreenState extends State<ProfileAddressesScreen> {
  final AddressService _addressService = AddressService();
  late Future<List<AddressModel>> _addressesFuture;

  @override
  void initState() {
    super.initState();
    _addressesFuture = _loadAddresses();
  }

  Future<List<AddressModel>> _loadAddresses() async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) {
      throw Exception('Vui lòng đăng nhập để xem địa chỉ');
    }
    return _addressService.getCurrentUserAddresses(token);
  }

  void _reloadAddresses() {
    setState(() {
      _addressesFuture = _loadAddresses();
    });
  }

  Future<void> _openAddressScreen([AddressModel? address]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddAddressScreen(address: address),
      ),
    );
    if (saved == true) {
      _reloadAddresses();
    }
  }

  Future<void> _deleteAddress(AddressModel address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa địa chỉ?'),
        content: Text('Bạn có chắc muốn xóa địa chỉ của ${address.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;

    try {
      await _addressService.deleteCurrentUserAddress(
        accessToken: token,
        id: address.id,
      );
      if (!mounted) return;
      showAppToast(
        context,
        message: 'Xóa địa chỉ thành công',
        type: AppToastType.success,
      );
      _reloadAddresses();
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
      );
    }
  }

  Future<void> _setDefaultAddress(AddressModel address) async {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;

    try {
      await _addressService.updateCurrentUserAddress(
        accessToken: token,
        address: AddressModel(
          id: address.id,
          userId: address.userId,
          name: address.name,
          phone: address.phone,
          location: address.location,
          region: address.region,
          province: address.province,
          district: address.district,
          ward: address.ward,
          hamlet: address.hamlet,
          isDefault: true,
          type: address.type,
        ),
      );
      _reloadAddresses();
    } catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: e.toString().replaceFirst('Exception: ', ''),
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(LucideIcons.arrow_left, color: Color(0xFFFF4F3A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Địa chỉ của tôi',
          style: GoogleFonts.inter(
            color: const Color(0xFF1F2937),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FutureBuilder<List<AddressModel>>(
        future: _addressesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _AddressMessage(
              icon: LucideIcons.circle_alert,
              title: 'Không thể tải địa chỉ',
              message: snapshot.error.toString().replaceFirst(
                'Exception: ',
                '',
              ),
              actionLabel: 'Thử lại',
              onAction: _reloadAddresses,
            );
          }

          final addresses = snapshot.data ?? [];

          return Column(
            children: [
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: const Text(
                  'Địa chỉ',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
              ),
              Expanded(
                child: addresses.isEmpty
                    ? _AddressMessage(
                        icon: LucideIcons.map_pin,
                        title: 'Chưa có địa chỉ nào',
                        message: 'Thêm địa chỉ để giao hàng nhanh hơn.',
                        actionLabel: 'Thêm địa chỉ mới',
                        onAction: _openAddressScreen,
                      )
                    : ListView.separated(
                        itemCount: addresses.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        itemBuilder: (context, index) {
                          final address = addresses[index];
                          return _AddressTile(
                            address: address,
                            onTap: () => _openAddressScreen(address),
                            onDelete: () => _deleteAddress(address),
                            onSetDefault: address.isDefault
                                ? null
                                : () => _setDefaultAddress(address),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _openAddressScreen,
                      icon: const Icon(LucideIcons.plus, size: 18),
                      label: const Text('Thêm địa chỉ mới'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFFF4F3A),
                        side: const BorderSide(color: Color(0xFFFF4F3A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.onTap,
    required this.onDelete,
    required this.onSetDefault,
  });

  final AddressModel address;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          address.name.isEmpty ? 'Người nhận' : address.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        address.phone,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    address.location,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  if (address.region.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      address.region,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (address.isDefault) const _AddressBadge('Mặc định'),
                      if (address.isDefault)
                        const _AddressBadge('Địa chỉ lấy hàng'),
                      if (!address.isDefault && onSetDefault != null)
                        InkWell(
                          onTap: onSetDefault,
                          child: const _AddressBadge('Đặt mặc định'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'delete', child: Text('Xóa')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressBadge extends StatelessWidget {
  const _AddressBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF4F3A)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFFF4F3A), fontSize: 10),
      ),
    );
  }
}

class _AddressMessage extends StatelessWidget {
  const _AddressMessage({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: const Color(0xFFFF4F3A)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
