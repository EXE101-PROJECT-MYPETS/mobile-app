import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_state.dart';
import '../models/pet_model.dart';
import 'add_pet_screen.dart';

class MyPetsScreen extends StatelessWidget {
  const MyPetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pets = context.watch<AppState>().myPets;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thú cưng của tôi',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.user, color: Colors.black87),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Thú cưng của tôi', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Quản lý hồ sơ thú cưng', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddPetScreen()),
                    );
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Thêm thú cưng', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63), // Pink
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // List of Pets
              ...pets.map((pet) => _buildPetCard(context, pet)),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetCard(BuildContext context, PetModel pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Edit / Delete buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildSmallIconButton(LucideIcons.edit2, 'Sửa', Colors.pink.shade100, Colors.pink),
              const SizedBox(width: 8),
              _buildSmallIconButton(LucideIcons.trash2, 'Xóa', Colors.pink.shade100, Colors.pink, onTap: () {
                context.read<AppState>().removePet(pet.id);
              }),
            ],
          ),
          
          // Pet basic info
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(pet.image),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('${pet.type} • ${pet.breed}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text('Shop: ${pet.shopName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          
          // Details
          Row(
            children: [
              const Icon(LucideIcons.checkCircle2, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Giới tính: ${pet.gender}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.calendar, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text('Tuổi: ${pet.age}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ],
          ),
          
          const SizedBox(height: 12),
          // Note box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Ghi chú: ${pet.note}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSmallIconButton(IconData icon, String label, Color bgColor, Color textColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor.withOpacity(0.4),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
