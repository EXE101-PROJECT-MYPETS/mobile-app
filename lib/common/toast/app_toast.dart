import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum AppToastType { success, error, info, warning }

OverlayEntry? _activeToastEntry;

void showAppToast(
  BuildContext context, {
  required String message,
  AppToastType type = AppToastType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null || message.trim().isEmpty) {
    return;
  }

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _AppToastOverlay(message: message, type: type),
  );

  if (_activeToastEntry?.mounted ?? false) {
    _activeToastEntry!.remove();
  }
  _activeToastEntry = entry;

  overlay.insert(entry);
  Future.delayed(duration, () {
    if (_activeToastEntry == entry && entry.mounted) {
      entry.remove();
      _activeToastEntry = null;
    }
  });
}

class _AppToastOverlay extends StatelessWidget {
  const _AppToastOverlay({required this.message, required this.type});

  final String message;
  final AppToastType type;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 12;

    return Positioned(
      left: 18,
      right: 18,
      top: top,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, -14 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E7EE)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _backgroundColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_icon, color: _foregroundColor, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F2937),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color get _foregroundColor {
    return switch (type) {
      AppToastType.success => const Color(0xFF168A4A),
      AppToastType.error => const Color(0xFFE5484D),
      AppToastType.warning => const Color(0xFFC47A00),
      AppToastType.info => const Color(0xFF0A94E8),
    };
  }

  Color get _backgroundColor => _foregroundColor;

  IconData get _icon {
    return switch (type) {
      AppToastType.success => LucideIcons.checkCircle2,
      AppToastType.error => LucideIcons.alertCircle,
      AppToastType.warning => LucideIcons.alertTriangle,
      AppToastType.info => LucideIcons.info,
    };
  }
}
