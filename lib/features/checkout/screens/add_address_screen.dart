import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../models/address_model.dart';
import 'dart:math';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regionController = TextEditingController();
  final _locationController = TextEditingController();
  
  bool _isDefault = false;
  String _addressType = 'Nhà Riêng';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _regionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _regionController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')));
      return;
    }

    final newAddress = AddressModel(
      id: 'a_${Random().nextInt(10000)}',
      name: _nameController.text,
      phone: _phoneController.text,
      region: _regionController.text,
      location: _locationController.text,
      isDefault: _isDefault,
      type: _addressType,
    );

    context.read<AppState>().addAddress(newAddress);
    Navigator.pop(context);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Địa chỉ mới',
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
                  // Paste Address Quick
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F1), // Light pink
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFD1D6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(LucideIcons.clipboardPaste, color: Color(0xFFFB7185), size: 18),
                            SizedBox(width: 8),
                            Text('Dán và nhập nhanh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Dán hoặc nhập thông tin, nhấn chọn Tự động điền để nhập tên, số điện thoại và địa chỉ.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const TextField(
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Dán hoặc nhập thông tin, nhấn chọn Tự động điền để nhập tên, số điện thoại và địa chỉ',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  // Form
                  Container(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text('Địa chỉ (dùng thông tin sau khi nhập)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        _buildTextField('Họ và tên', _nameController),
                        _buildTextField('Số điện thoại', _phoneController, keyboardType: TextInputType.phone),
                        _buildTextField('Tỉnh/Thành phố, Quận/Huyện, Phường/Xã', _regionController, suffixIcon: LucideIcons.chevronRight),
                        _buildTextField('Tên đường, Toà nhà, Số nhà.', _locationController),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Đặt làm địa chỉ mặc định', style: TextStyle(fontSize: 14)),
                              Switch(
                                value: _isDefault,
                                activeColor: const Color(0xFFFB7185),
                                onChanged: (val) {
                                  setState(() => _isDefault = val);
                                },
                              )
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Text('Loại địa chỉ:', style: TextStyle(fontSize: 14)),
                              const Spacer(),
                              _buildTypeChip('Văn Phòng'),
                              const SizedBox(width: 8),
                              _buildTypeChip('Nhà Riêng'),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // Complete button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
            color: Colors.white,
            child: ElevatedButton(
              onPressed: _saveAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB7185), // Pink theme
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
              ),
              child: const Text('HOÀN THÀNH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, {TextInputType? keyboardType, IconData? suffixIcon}) {
    return Column(
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: InputBorder.none,
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.grey) : null,
          ),
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }

  Widget _buildTypeChip(String type) {
    final isSelected = _addressType == type;
    return GestureDetector(
      onTap: () => setState(() => _addressType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFB7185) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? const Color(0xFFFB7185) : Colors.grey.shade300),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
