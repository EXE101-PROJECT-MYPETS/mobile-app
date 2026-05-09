import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:petpee_mobile/common/store/app_state.dart';
import 'add_address_screen.dart';

class AddressSelectionScreen extends StatelessWidget {
  const AddressSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final addresses = state.addresses;

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
          'Chọn địa chỉ nhận hàng',
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
            child: ListView.builder(
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final addr = addresses[index];
                return Container(
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 8),
                  child: RadioListTile<String>(
                    value: addr.id,
                    groupValue: state.defaultAddress?.id,
                    onChanged: (val) {
                      if (val != null) {
                        context.read<AppState>().setDefaultAddress(val);
                        Navigator.pop(context); // Optional: pop back immediately
                      }
                    },
                    activeColor: const Color(0xFFFB7185), // Pink theme
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      children: [
                        Text(addr.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        Text(addr.phone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Sửa', style: TextStyle(color: Colors.grey)),
                        )
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(addr.location, style: const TextStyle(color: Colors.black87)),
                        const SizedBox(height: 2),
                        Text(addr.region, style: const TextStyle(color: Colors.black87)),
                        if (addr.isDefault) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFFB7185)),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text('Mặc định', style: TextStyle(color: Color(0xFFFB7185), fontSize: 10)),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Add button
          Container(
            padding: EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
            color: Colors.white,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddAddressScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFB7185)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.plus, color: Color(0xFFFB7185), size: 20),
                  SizedBox(width: 8),
                  Text('Thêm Địa Chỉ Mới', style: TextStyle(color: Color(0xFFFB7185), fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
