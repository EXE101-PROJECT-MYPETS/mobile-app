import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:petpee_mobile/apps/profile/model/pet_model.dart';
import 'package:petpee_mobile/apps/profile/api/pet_service.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/common/toast/app_toast.dart';
import 'add_pet_screen.dart';

class MyPetsScreen extends StatefulWidget {
  const MyPetsScreen({super.key});

  @override
  State<MyPetsScreen> createState() => _MyPetsScreenState();
}

class _MyPetsScreenState extends State<MyPetsScreen> {
  final PetService _petService = PetService();
  late final AuthProvider _authProvider;
  late Future<List<PetModel>> _petsFuture;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _petsFuture = _loadPets();
  }

  Future<List<PetModel>> _loadPets() async {
    try {
      final dtos = await _petService.getAll();
      return dtos.map((dto) => PetModel.fromDTO(dto)).toList();
    } catch (e) {
      // Log token info for debugging 401 errors
      final message = e.toString();
      if (message.contains('401') || message.contains('Unauthorized')) {
        print('[MyPetsScreen] 401 Error - logging token info');
        _authProvider.debugPrintTokenInfo();

        try {
          await _authProvider.refreshSession();
          final refreshedDtos = await _petService.getAll();
          return refreshedDtos.map((dto) => PetModel.fromDTO(dto)).toList();
        } catch (refreshError) {
          print('[MyPetsScreen] refreshSession failed: $refreshError');
          throw refreshError;
        }
      }

      if (mounted) {
        showAppToast(
          context,
          message: 'Lỗi tải thú cưng: $e',
          type: AppToastType.error,
        );
      }
      rethrow;
    }
  }

  void _onAddPetSuccess() {
    final future = _loadPets();
    setState(() {
      _petsFuture = future;
    });
  }

  void _onDeletePetSuccess() {
    final future = _loadPets();
    setState(() {
      _petsFuture = future;
    });
    showAppToast(
      context,
      message: 'Xóa thú cưng thành công',
      type: AppToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          ),
        ],
      ),
      body: FutureBuilder<List<PetModel>>(
        future: _petsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.alertCircle,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      final future = _loadPets();
                      setState(() {
                        _petsFuture = future;
                      });
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final pets = snapshot.data ?? [];
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Thú cưng của tôi',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Quản lý hồ sơ thú cưng',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddPetScreen(),
                          ),
                        );
                        if (result == true) {
                          _onAddPetSuccess();
                        }
                      },
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Thêm thú cưng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  pets.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.dog,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có thú cưng nào',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: pets
                              .map((pet) => _buildPetCard(context, pet))
                              .toList(),
                        ),
                ],
              ),
            ),
          );
        },
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
              _buildSmallIconButton(
                LucideIcons.edit2,
                'Sửa',
                Colors.pink.shade100,
                Colors.pink,
              ),
              const SizedBox(width: 8),
              _buildSmallIconButton(
                LucideIcons.trash2,
                'Xóa',
                Colors.pink.shade100,
                Colors.pink,
                onTap: () async {
                  if (pet.id == null) return;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Xóa thú cưng?'),
                      content: Text('Bạn có chắc muốn xóa ${pet.name}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await _petService.delete(pet.id!);
                      _onDeletePetSuccess();
                    } catch (e) {
                      if (mounted) {
                        showAppToast(
                          context,
                          message: 'Lỗi xóa thú cưng: $e',
                          type: AppToastType.error,
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),

          // Pet basic info
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: pet.avatarUrl != null
                    ? NetworkImage(pet.avatarUrl!)
                    : null,
                child: pet.avatarUrl == null
                    ? const Icon(LucideIcons.dog, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet.breedText ?? 'Không rõ giống loài',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (pet.dob != null)
                      Text(
                        'Sinh ngày: ${pet.dob?.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
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
              const Icon(
                LucideIcons.checkCircle2,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                'Giới tính: ${pet.gender ?? 'Không rõ'}',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(LucideIcons.calendar, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Ngày sinh: ${pet.dob?.toLocal().toString().split(' ')[0] ?? 'Không rõ'}',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Note box
          if (pet.note != null && pet.note!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Ghi chú: ${pet.note}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton(
    IconData icon,
    String label,
    Color bgColor,
    Color textColor, {
    VoidCallback? onTap,
  }) {
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
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
