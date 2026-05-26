import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/apps/service/page/service_detail_screen.dart';
import 'package:petpee_mobile/common/user/dto/service_public_dto.dart';
import 'package:petpee_mobile/common/utils/price_formatter.dart';

class ServiceCard extends StatelessWidget {
  final ServicePublicDTO service;
  final bool showLocation;
  final double width;

  const ServiceCard({
    super.key,
    required this.service,
    this.showLocation = true,
    this.width = 200,
  });

  @override
  Widget build(BuildContext context) {
    final formattedPrice = PriceFormatter.formatVnd(service.basePrice ?? 0);
    final shopName = service.shopName?.trim();
    final imageUrl = service.imageUrl;
    final shopProvince = service.shopProvince?.trim();

    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        child: GestureDetector(
          onTap: () {
            final serviceId = service.id;
            if (serviceId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Không tìm thấy mã dịch vụ')),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceDetailScreen(
                  serviceId: serviceId,
                  name: service.name,
                  image: service.imageUrl,
                  price: service.basePrice,
                  shopId: service.shopId,
                  shopName: service.shopName,
                  rating: service.rating,
                  soldCount: service.ratingCount,
                  address: service.shopAddress,
                  distanceKm: service.distanceKm,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const _ServiceImageFallback(),
                              )
                            : const _ServiceImageFallback(),
                      ),
                      if (_shouldShowDistanceBadge(service.distanceKm))
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8B15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.mapPin,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDistanceBadge(service.distanceKm!),
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name ?? 'Dịch vụ',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (shopName != null && shopName.isNotEmpty) ...[
                        Text(
                          shopName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      _ServiceRating(
                        rating: service.rating,
                        ratingCount: service.ratingCount,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formattedPrice,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFB7185),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (showLocation) ...[
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF94A3B8),
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                _buildLocationText(shopProvince),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildLocationText(String? shopProvince) {
    final province = shopProvince?.isNotEmpty == true
        ? shopProvince!
        : 'Thành phố Hà Nội';
    return province;
  }

  bool _shouldShowDistanceBadge(double? distanceKm) {
    return distanceKm != null && distanceKm >= 0;
  }

  String _formatDistanceBadge(double distanceKm) {
    if (distanceKm < 1) {
      return '< 1 km';
    }
    if (distanceKm >= 100) {
      return '${distanceKm.round()} km';
    }
    final value = distanceKm.toStringAsFixed(1);
    return '${value.endsWith('.0') ? value.substring(0, value.length - 2) : value} km';
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
        const Icon(Icons.star, color: Colors.amber, size: 14),
        const SizedBox(width: 3),
        Text(
          ratingValue.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          '(${ratingCount ?? 0})',
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
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
