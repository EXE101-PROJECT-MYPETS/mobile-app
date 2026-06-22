import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:pawly_mobile/common/auth/store/auth_provider.dart';
import 'package:pawly_mobile/common/user/api/review_service.dart';
import 'package:pawly_mobile/common/toast/app_toast.dart';

void showWriteReviewSheet({
  required BuildContext context,
  int? productId,
  int? serviceId,
  required String name,
  String? imageUrl,
  VoidCallback? onReviewSubmitted,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _WriteReviewSheet(
      productId: productId,
      serviceId: serviceId,
      name: name,
      imageUrl: imageUrl,
      onReviewSubmitted: onReviewSubmitted,
    ),
  );
}

class _WriteReviewSheet extends StatefulWidget {
  final int? productId;
  final int? serviceId;
  final String name;
  final String? imageUrl;
  final VoidCallback? onReviewSubmitted;

  const _WriteReviewSheet({
    this.productId,
    this.serviceId,
    required this.name,
    this.imageUrl,
    this.onReviewSubmitted,
  });

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  final ReviewService _reviewService = ReviewService();
  final TextEditingController _commentController = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating < 1 || _rating > 5) {
      showAppToast(
        context,
        message: 'Vui lòng chọn số sao đánh giá (1-5 sao)',
        type: AppToastType.error,
      );
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.isEmpty) {
      showAppToast(
        context,
        message: 'Vui lòng nhập nội dung đánh giá',
        type: AppToastType.error,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) {
        showAppToast(
          context,
          message: 'Vui lòng đăng nhập để gửi đánh giá',
          type: AppToastType.error,
        );
        return;
      }

      if (widget.productId != null) {
        await _reviewService.submitProductReview(
          productId: widget.productId!,
          rating: _rating,
          comment: comment,
          token: token,
        );
      } else if (widget.serviceId != null) {
        await _reviewService.submitServiceReview(
          serviceId: widget.serviceId!,
          rating: _rating,
          comment: comment,
          token: token,
        );
      } else {
        throw Exception('Chưa xác định sản phẩm hoặc dịch vụ để đánh giá');
      }

      if (!mounted) return;
      showAppToast(
        context,
        message: 'Gửi đánh giá thành công! Cảm ơn bạn nhé.',
        type: AppToastType.success,
      );
      Navigator.pop(context);
      if (widget.onReviewSubmitted != null) {
        widget.onReviewSubmitted!();
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString();
      if (errorMsg.contains('ReviewDuplicate')) {
        errorMsg = 'Bạn đã đánh giá sản phẩm/dịch vụ này rồi.';
      } else {
        errorMsg = 'Gửi đánh giá thất bại. Vui lòng thử lại sau.';
      }
      showAppToast(
        context,
        message: errorMsg,
        type: AppToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildStar(int index) {
    final isSelected = index <= _rating;
    return GestureDetector(
      onTap: _isSubmitting
          ? null
          : () {
              setState(() {
                _rating = index;
              });
            },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: isSelected ? 1.15 : 1.0,
        child: Icon(
          Icons.star_rounded,
          color: isSelected ? const Color(0xFFFFB300) : const Color(0xFFE5E7EB),
          size: 42,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tiêu đề sheet
            Center(
              child: Text(
                'Đánh giá chất lượng',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Thông tin sản phẩm/dịch vụ
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child:
                          widget.imageUrl != null && widget.imageUrl!.isNotEmpty
                              ? Image.network(
                                  widget.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(color: const Color(0xFFE2E8F0)),
                                )
                              : Container(
                                  color: const Color(0xFFE2E8F0),
                                  child: const Icon(LucideIcons.image,
                                      color: Colors.grey, size: 20),
                                ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rating Stars Header
            Center(
              child: Text(
                'Vui lòng chọn mức độ hài lòng',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Star selectors
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => _buildStar(index + 1)),
            ),
            const SizedBox(height: 20),

            // Textarea input
            Text(
              'Chia sẻ cảm nhận',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              enabled: !_isSubmitting,
              style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText:
                    'Hãy chia sẻ cảm nhận của bạn về sản phẩm/dịch vụ này nhé...',
                hintStyle: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFFB7185), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Gửi đánh giá button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Gửi đánh giá',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
