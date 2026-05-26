import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/apps/home/page/home_screen.dart';
import 'package:petpee_mobile/apps/home/page/notifications_screen.dart';

import 'package:petpee_mobile/apps/profile/api/pet_service.dart';
import 'package:petpee_mobile/apps/profile/model/pet_model.dart';
import 'package:petpee_mobile/apps/profile/page/profile_screen.dart';
import 'package:petpee_mobile/common/component/common_bottom_nav.dart';
import 'package:petpee_mobile/common/utils/image_url_util.dart';
import 'package:petpee_mobile/features/chat/services/ai_pet_health_service.dart';
import 'package:petpee_mobile/features/chat/screens/ai_assistant_chat_screen.dart';
import 'package:petpee_mobile/apps/cart/page/cart_screen.dart';

class PetAiSelectionScreen extends StatefulWidget {
  const PetAiSelectionScreen({super.key});

  @override
  State<PetAiSelectionScreen> createState() => _PetAiSelectionScreenState();
}

class _PetAiSelectionScreenState extends State<PetAiSelectionScreen> {
  final PetService _petService = PetService();
  final AiPetHealthService _aiPetHealthService = AiPetHealthService();
  late Future<List<PetModel>> _petsFuture;
  int? _openingPetId;

  @override
  void initState() {
    super.initState();
    _petsFuture = _loadPets();
  }

  Future<List<PetModel>> _loadPets() async {
    final dtos = await _petService.getAll();
    return dtos.map(PetModel.fromDTO).toList();
  }

  Future<void> _openChat(PetModel pet) async {
    final petId = pet.id;
    if (petId == null || _openingPetId != null) return;

    setState(() {
      _openingPetId = petId;
    });

    try {
      final conversation = await _aiPetHealthService.getOrCreateConversation(
        petId,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AiAssistantChatScreen(
            selectedPet: pet,
            conversation: conversation,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở cuộc trò chuyện AI. Vui lòng thử lại.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingPetId = null;
        });
      }
    }
  }

  void _handleBottomNavTap(int index) {
    if (index == 1) return;

    final Widget screen;
    if (index == 0) {
      screen = const HomeScreen();
    } else if (index == 2) {
      screen = const CartScreen();
    } else if (index == 3) {
      screen = const NotificationsScreen();
    } else if (index == 4) {
      screen = const ProfileScreen();
    } else {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => screen),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Navigator.canPop(context)
            ? IconButton(
                tooltip: 'Quay lại',
                icon: const Icon(
                  LucideIcons.arrowLeft,
                  color: Color(0xFF3F3128),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'PetPee AI',
          style: GoogleFonts.inter(
            color: const Color(0xFF2E251F),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8A5A3B).withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.bot,
                color: Color(0xFFE76F51),
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<PetModel>>(
          future: _petsFuture,
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final pets = snapshot.data ?? const <PetModel>[];

            if (isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE76F51)),
              );
            }

            if (snapshot.hasError) {
              return const _PetLoadErrorState();
            }

            if (pets.isEmpty) {
              return const _EmptyPetState();
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
              children: [
                Text(
                  'Bạn muốn hỏi AI về bé nào?',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF2E251F),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 18),
                ...pets.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PetChatCard(
                      pet: entry.value,
                      isOpening: _openingPetId == entry.value.id,
                      onTap: () => _openChat(entry.value),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const _SuggestionSection(),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 1,
        onTap: _handleBottomNavTap,
      ),
    );
  }
}

class _PetChatCard extends StatelessWidget {
  const _PetChatCard({
    required this.pet,
    required this.isOpening,
    required this.onTap,
  });

  final PetModel pet;
  final bool isOpening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A5A3B).withValues(alpha: 0.07),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PetAvatar(pet: pet),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pet.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF2E251F),
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        isOpening
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFE76F51),
                                ),
                              )
                            : const Icon(
                                LucideIcons.chevronRight,
                                color: Color(0xFFB79884),
                                size: 18,
                              ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _petInfo(pet),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF8A7769),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Bắt đầu cuộc trò chuyện mới',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFE76F51),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.messagesSquare,
                          size: 13,
                          color: Color(0xFFE76F51),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Cuộc trò chuyện riêng cho bé này',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA56A43),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _petInfo(PetModel pet) {
    final breed = pet.breedText?.trim().isNotEmpty == true
        ? pet.breedText!.trim()
        : _speciesLabel(pet);
    final age = _ageLabel(pet.dob) ?? pet.age ?? 'Chưa rõ tuổi';
    final weight = _weightLabel(pet.weightKg);
    return '$breed • $age • $weight';
  }

  String _weightLabel(double? weightKg) {
    if (weightKg == null || weightKg <= 0) return 'Chưa cập nhật cân nặng';
    final text = weightKg == weightKg.roundToDouble()
        ? weightKg.toStringAsFixed(0)
        : weightKg.toStringAsFixed(1);
    return '${text}kg';
  }

  String _speciesLabel(PetModel pet) {
    if (pet.type?.trim().isNotEmpty == true) return pet.type!.trim();
    if (pet.speciesId == 1) return 'Chó';
    if (pet.speciesId == 2) return 'Mèo';
    return 'Thú cưng';
  }

  String? _ageLabel(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    if (years <= 0) {
      final months = (now.year - dob.year) * 12 + now.month - dob.month;
      return '${months.clamp(1, 11)} tháng';
    }
    return '$years tuổi';
  }
}

class _PetAvatar extends StatelessWidget {
  const _PetAvatar({required this.pet});

  final PetModel pet;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = ImageUrlUtil.buildPublicUrl(pet.avatarUrl);
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE6D7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: avatarUrl == null || avatarUrl.isEmpty
            ? Container(
                color: const Color(0xFFFFF1E7),
                child: Icon(
                  pet.speciesId == 2 ? LucideIcons.cat : LucideIcons.dog,
                  color: const Color(0xFFE76F51),
                  size: 28,
                ),
              )
            : Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFFFF1E7),
                  child: Icon(
                    pet.speciesId == 2 ? LucideIcons.cat : LucideIcons.dog,
                    color: const Color(0xFFE76F51),
                    size: 28,
                  ),
                ),
              ),
      ),
    );
  }
}

class _SuggestionSection extends StatelessWidget {
  const _SuggestionSection();

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      'Bé bỏ ăn?',
      'Bé bị nôn?',
      'Rụng lông nhiều?',
      'Bao lâu nên tắm?',
      'Đặt lịch grooming',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bạn có thể hỏi AI về',
          style: GoogleFonts.inter(
            color: const Color(0xFF2E251F),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map((label) => _QuestionChip(label: label))
              .toList(),
        ),
      ],
    );
  }
}

class _QuestionChip extends StatelessWidget {
  const _QuestionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFD8BE)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFF6D4C3D),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PetLoadErrorState extends StatelessWidget {
  const _PetLoadErrorState();

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
                LucideIcons.alertCircle,
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
              'Đăng nhập để PetPee AI tải hồ sơ thú cưng và tư vấn chính xác hơn.',
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
                  icon: const Icon(LucideIcons.logIn, size: 18),
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

class _EmptyPetState extends StatelessWidget {
  const _EmptyPetState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        const SizedBox(height: 18),
        const _PetIllustration(),
        const SizedBox(height: 24),
        Text(
          'Bạn chưa có hồ sơ thú cưng',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFF2E251F),
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tạo hồ sơ giúp PetPee AI tư vấn chính xác hơn cho từng bé.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFF7B685B),
            fontSize: 14,
            height: 1.45,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PetIllustration extends StatelessWidget {
  const _PetIllustration();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(46),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A5A3B).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 34,
              top: 42,
              child: Icon(
                LucideIcons.dog,
                color: const Color(0xFFE76F51).withValues(alpha: 0.78),
                size: 54,
              ),
            ),
            Positioned(
              right: 34,
              bottom: 40,
              child: Icon(
                LucideIcons.cat,
                color: const Color(0xFF8A5A3B).withValues(alpha: 0.72),
                size: 48,
              ),
            ),
            Positioned(
              right: 32,
              top: 30,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE9DC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: Color(0xFFE76F51),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
