import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:pawly_mobile/apps/profile/model/pet_model.dart';
import 'package:pawly_mobile/apps/profile/api/pet_service.dart';
import 'package:pawly_mobile/common/auth/store/auth_provider.dart';
import 'package:pawly_mobile/common/config/api_config.dart';
import 'package:pawly_mobile/common/toast/app_toast.dart';
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

  String? _resolvePetAvatarUrl(String? avatarUrl) {
    final value = avatarUrl?.trim();
    if (value == null || value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'file') {
      return ApiConfig.formatImageUrl(uri.path);
    }

    return ApiConfig.formatImageUrl(value);
  }

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _petsFuture = _loadPets();
  }

  Future<List<PetModel>> _loadPets() async {
    final token = _authProvider.token;
    if (token == null || token.isEmpty) {
      throw const PetAuthRequiredException();
    }

    try {
      final dtos = await _petService.getAll();
      return dtos.map((dto) => PetModel.fromDTO(dto)).toList();
    } catch (e) {
      // Log token info for debugging 401 errors
      final message = e.toString();
      if (message.contains('401') || message.contains('Unauthorized')) {
        debugPrint('[MyPetsScreen] 401 Error - logging token info');
        _authProvider.debugPrintTokenInfo();

        try {
          await _authProvider.refreshSession();
          final refreshedDtos = await _petService.getAll();
          return refreshedDtos.map((dto) => PetModel.fromDTO(dto)).toList();
        } catch (refreshError) {
          debugPrint('[MyPetsScreen] refreshSession failed: $refreshError');
          rethrow;
        }
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

  void _retryLoadPets() {
    final future = _loadPets();
    setState(() {
      _petsFuture = future;
    });
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
          icon: const Icon(LucideIcons.arrow_left, color: Colors.black87),
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
            final error = snapshot.error;
            if (_isAuthError(error)) {
              return const _PetLoginRequiredState();
            }
            return _PetLoadErrorState(error: error, onRetry: _retryLoadPets);
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
    final avatarUrl = _resolvePetAvatarUrl(pet.avatarUrl);

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
                LucideIcons.square_pen,
                'Sửa',
                Colors.pink.shade100,
                Colors.pink,
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddPetScreen(pet: pet),
                    ),
                  );
                  if (result == true) {
                    _onAddPetSuccess();
                  }
                },
              ),
              const SizedBox(width: 8),
              _buildSmallIconButton(
                LucideIcons.trash_2,
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
                      if (!context.mounted) return;
                      showAppToast(
                        context,
                        message: 'Lỗi xóa thú cưng: $e',
                        type: AppToastType.error,
                      );
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
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
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
                LucideIcons.circle_check_big,
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
          color: bgColor.withValues(alpha: 0.4),
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

  bool _isAuthError(Object? error) {
    if (error is PetAuthRequiredException) return true;
    final message = error.toString();
    return message.contains('401') || message.contains('Unauthorized');
  }
}

class PetAuthRequiredException implements Exception {
  const PetAuthRequiredException();

  @override
  String toString() => 'Cần đăng nhập để xem danh sách thú cưng';
}

class _PetLoadErrorState extends StatelessWidget {
  const _PetLoadErrorState({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error.toString().replaceFirst('Exception: ', '');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE9DC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.triangle_alert,
                color: Color(0xFFE76F51),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không thể tải danh sách thú cưng',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF2E251F),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: const Color(0xFF7B685B),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(LucideIcons.refresh_cw, size: 18),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFFE11D48),
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetLoginRequiredState extends StatelessWidget {
  const _PetLoginRequiredState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE9DC),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.circle_alert,
                color: Color(0xFFE76F51),
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vui lòng đăng nhập để xem danh sách thú cưng',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF2E251F),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng nhập để Pawly tải hồ sơ thú cưng và đồng bộ dữ liệu của bạn.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF7B685B),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.22),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(LucideIcons.log_in, size: 18),
                  label: const Text('Đăng nhập'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    textStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
