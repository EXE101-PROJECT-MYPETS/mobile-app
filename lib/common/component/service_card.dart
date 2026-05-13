import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/common/user/dto/service_public_dto.dart';
import 'package:petpee_mobile/common/utils/price_formatter.dart';

class ServiceCard extends StatelessWidget {
  final ServicePublicDTO service;

  const ServiceCard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final formattedPrice = PriceFormatter.formatVnd(service.basePrice ?? 0);
    final duration = service.durationMin ?? 0;
    final durationText = duration >= 60
        ? '${(duration / 60).toStringAsFixed(1)}h'
        : '${duration}p';
    final imageUrl = service.imageUrl;
    final shopProvince = service.shopProvince?.trim();
    final distanceText = _formatDistance(service.distanceKm);

    return Container(
      width: 252,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          // TODO: Navigate to service detail page
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header với icon service và badge khoảng cách
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 175,
                    width: double.infinity,
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const _ServiceImageFallback(),
                          )
                        : const _ServiceImageFallback(),
                  ),
                  if (service.distanceKm != null)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8B15),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDistanceBadge(service.distanceKm!),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service name
                    Text(
                      service.name ?? 'Dịch vụ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Diễn ra trong $durationText',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF8B98A7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    _ServiceRating(
                      rating: service.rating,
                      ratingCount: service.ratingCount,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            formattedPrice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF5A4E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _buildLocationText(shopProvince, distanceText),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildLocationText(String? shopProvince, String? distanceText) {
    final province = shopProvince?.isNotEmpty == true
        ? shopProvince!
        : 'Thành phố Hà Nội';
    if (distanceText == null) {
      return province;
    }
    return '$province - $distanceText';
  }

  String? _formatDistance(double? distanceKm) {
    if (distanceKm == null) {
      return null;
    }
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(distanceKm >= 10 ? 0 : 1)} km';
  }

  String _formatDistanceBadge(double distanceKm) {
    if (distanceKm < 1) {
      return '< 1 km';
    }
    final roundedKm = distanceKm.round();
    return '$roundedKm km';
  }
}

class _ServiceRating extends StatelessWidget {
  const _ServiceRating({required this.rating, required this.ratingCount});

  final double? rating;
  final int? ratingCount;

  @override
  Widget build(BuildContext context) {
    final ratingValue = rating != null && rating! > 0 ? rating! : 0.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.star, size: 15, color: Color(0xFFFFC107)),
        const SizedBox(width: 4),
        Text(
          ratingValue.toStringAsFixed(1),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        Text(
          ' (${ratingCount ?? 0})',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF8B98A7),
          ),
        ),
      ],
    );
  }
}

class _ServiceImageFallback extends StatelessWidget {
  const _ServiceImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE4E9), Color(0xFFFFC7D7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(LucideIcons.sparkles, size: 62, color: Color(0xFFFF5A4E)),
      ),
    );
  }
}
