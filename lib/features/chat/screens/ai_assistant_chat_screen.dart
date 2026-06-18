import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:pawly_mobile/apps/product/page/spa_service_screen.dart';
import 'package:pawly_mobile/apps/profile/model/pet_model.dart';
import 'package:pawly_mobile/common/component/common_bottom_nav.dart';
import 'package:pawly_mobile/common/navigation/main_tab_navigation.dart';
import 'package:pawly_mobile/features/chat/models/ai_pet_health_models.dart';
import 'package:pawly_mobile/features/chat/services/ai_pet_health_service.dart';

class AiAssistantChatScreen extends StatefulWidget {
  const AiAssistantChatScreen({super.key, this.selectedPet, this.conversation});

  final PetModel? selectedPet;
  final AiPetHealthConversation? conversation;

  @override
  State<AiAssistantChatScreen> createState() => _AiAssistantChatScreenState();
}

class _AiAssistantChatScreenState extends State<AiAssistantChatScreen> {
  final AiPetHealthService _aiPetHealthService = AiPetHealthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<AiPetHealthMessage> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  String get _petName => widget.selectedPet?.name ?? 'boss';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final conversationId = widget.conversation?.id;
    if (conversationId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messages = await _aiPetHealthService.getMessages(conversationId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(messages);
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải tin nhắn. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    final petId = widget.selectedPet?.id;
    if (text.isEmpty || _isSending || petId == null) return;

    final now = DateTime.now();
    final tempUserMessage = AiPetHealthMessage(
      id: -now.microsecondsSinceEpoch,
      role: 'USER',
      content: text,
      createdAt: now,
    );

    setState(() {
      _messages.add(tempUserMessage);
      _isSending = true;
      _errorMessage = null;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _aiPetHealthService.sendMessage(
        petId: petId,
        conversationId: widget.conversation?.id,
        message: text,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          AiPetHealthMessage(
            id: -DateTime.now().microsecondsSinceEpoch,
            role: 'ASSISTANT',
            content: response.answer,
            metadata: response.toMetadata(),
            createdAt: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((message) => message.id == tempUserMessage.id);
        _errorMessage = 'Không thể gửi tin nhắn. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleBottomNavTap(int index) {
    MainTabNavigation.open(context, index, currentIndex: 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: Color(0xFF27313F)),
          tooltip: 'Quay lại',
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                'assets/icon_chatbot.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.selectedPet == null
                        ? 'Trợ lý AI'
                        : 'AI của $_petName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF253044),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2ECC71),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'ĐANG HOẠT ĐỘNG',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8190A5),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            if (_errorMessage != null) _ErrorBanner(message: _errorMessage!),
            _MessageComposer(
              controller: _messageController,
              isSending: _isSending,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 1,
        onTap: _handleBottomNavTap,
      ),
    );
  }

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE76F51)),
      );
    }

    if (_messages.isEmpty) {
      return ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        children: [_WelcomeBubble(petName: _petName)],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isSending && index == _messages.length) {
          return const _TypingIndicator();
        }
        return _ChatMessageBubble(
          message: _messages[index],
          currentPet: widget.selectedPet,
        );
      },
    );
  }
}

class _WelcomeBubble extends StatelessWidget {
  const _WelcomeBubble({required this.petName});

  final String petName;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _AssistantAvatar(size: 30),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                18,
              ).copyWith(bottomLeft: const Radius.circular(6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'Bạn muốn hỏi gì về $petName? Pawly AI sẽ tư vấn dựa trên hồ sơ của bé.',
              style: GoogleFonts.inter(
                color: const Color(0xFF2D3648),
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({required this.message, required this.currentPet});

  final AiPetHealthMessage message;
  final PetModel? currentPet;

  @override
  Widget build(BuildContext context) {
    final maxBubbleWidth = MediaQuery.sizeOf(context).width * 0.72;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const _AssistantAvatar(size: 30),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color:
                        message.isUser ? const Color(0xFF0866D8) : Colors.white,
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomLeft: Radius.circular(message.isUser ? 18 : 6),
                      bottomRight: Radius.circular(message.isUser ? 6 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: GoogleFonts.inter(
                          color: message.isUser
                              ? Colors.white
                              : const Color(0xFF2D3648),
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!message.isUser &&
                          (message.riskLevel != null ||
                              message.shouldBookVet)) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (message.riskLevel != null)
                              _MetaChip(label: 'Mức độ: ${message.riskLevel}'),
                            if (message.shouldBookVet)
                              const _MetaChip(label: 'Nên đặt lịch thú y'),
                          ],
                        ),
                      ],
                      if (!message.isUser && _bookingActionConfig != null) ...[
                        const SizedBox(height: 12),
                        AiBookingActionCard(
                          petId: currentPet?.id,
                          petName: currentPet?.name ?? 'bé',
                          keyword: _bookingActionConfig!.keyword,
                          serviceType: _bookingActionConfig!.serviceType,
                          preferredDateText:
                              _bookingActionConfig!.preferredDateText,
                          isVetRecommendation:
                              _bookingActionConfig!.isVetRecommendation,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTime(message.createdAt),
                  style: GoogleFonts.inter(
                    color: const Color(0xFF9AA4B2),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  _BookingActionConfig? get _bookingActionConfig {
    final action = message.action;
    if (action?.type == 'OPEN_BOOKING_FLOW') {
      return _BookingActionConfig(
        keyword: _stringArg(action!.arguments, 'keyword') ??
            _stringArg(action.arguments, 'prefillKeyword'),
        serviceType: _stringArg(action.arguments, 'serviceType'),
        preferredDateText: _stringArg(action.arguments, 'preferredDateText'),
      );
    }

    if (message.shouldBookVet) {
      return const _BookingActionConfig(
        keyword: 'khám thú y',
        serviceType: 'VET',
        isVetRecommendation: true,
      );
    }

    return null;
  }

  String? _stringArg(Map<String, dynamic> arguments, String key) {
    final value = arguments[key];
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class _BookingActionConfig {
  const _BookingActionConfig({
    this.keyword,
    this.serviceType,
    this.preferredDateText,
    this.isVetRecommendation = false,
  });

  final String? keyword;
  final String? serviceType;
  final String? preferredDateText;
  final bool isVetRecommendation;
}

class AiBookingActionCard extends StatelessWidget {
  const AiBookingActionCard({
    super.key,
    required this.petId,
    required this.petName,
    this.keyword,
    this.serviceType,
    this.preferredDateText,
    this.isVetRecommendation = false,
  });

  final int? petId;
  final String petName;
  final String? keyword;
  final String? serviceType;
  final String? preferredDateText;
  final bool isVetRecommendation;

  @override
  Widget build(BuildContext context) {
    final title =
        isVetRecommendation ? 'Nên liên hệ thú y sớm' : 'Đặt lịch cho $petName';
    final serviceLabel = _serviceLabel(serviceType, keyword);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD8BE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              color: const Color(0xFF2E251F),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isVetRecommendation
                ? 'Pawly AI gợi ý bạn đặt lịch khám để được bác sĩ kiểm tra kỹ hơn.'
                : 'Mình sẽ mở màn đặt lịch để bạn chọn shop, dịch vụ và khung giờ phù hợp.',
            style: GoogleFonts.inter(
              color: const Color(0xFF6D5B4F),
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (serviceLabel != null) ...[
            const SizedBox(height: 8),
            _ActionInfoLine(label: 'Dịch vụ gợi ý', value: serviceLabel),
          ],
          if (preferredDateText?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            _ActionInfoLine(
              label: 'Thời gian gợi ý',
              value: preferredDateText!.trim(),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpaServiceScreen(
                      petId: petId,
                      prefillKeyword:
                          isVetRecommendation ? 'khám thú y' : keyword,
                      serviceType: isVetRecommendation ? 'VET' : serviceType,
                      preferredDateText: preferredDateText,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE76F51),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: Text(
                isVetRecommendation
                    ? 'Đặt lịch khám'
                    : 'Chọn shop và khung giờ',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _serviceLabel(String? serviceType, String? keyword) {
    final type = serviceType?.trim().toUpperCase();
    if (type == 'VET') return 'Khám thú y';
    if (type == 'GROOMING') return 'Tắm/grooming';
    final keywordText = keyword?.trim();
    return keywordText == null || keywordText.isEmpty ? null : keywordText;
  }
}

class _ActionInfoLine extends StatelessWidget {
  const _ActionInfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $value',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        color: const Color(0xFFA56A43),
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: const Color(0xFF0866D8),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Color(0xFFEAF4FF),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.asset('assets/icon_chatbot.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _AssistantAvatar(size: 30),
          const SizedBox(width: 10),
          Text(
            'Đang trả lời...',
            style: GoogleFonts.inter(
              color: const Color(0xFFA5ADBA),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(
          color: const Color(0xFFD92D20),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: controller,
                enabled: !isSending,
                minLines: 1,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: GoogleFonts.inter(
                    color: const Color(0xFFB1B8C4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF7F8FC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton.filled(
              tooltip: 'Gửi',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF0866D8),
                foregroundColor: Colors.white,
              ),
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(LucideIcons.send, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
