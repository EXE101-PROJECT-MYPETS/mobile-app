import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/apps/product/page/spa_service_screen.dart';
import 'package:petpee_mobile/common/utils/image_url_util.dart';
import 'package:petpee_mobile/common/utils/price_formatter.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({
    super.key,
    required this.serviceId,
    required this.name,
    this.image,
    this.price,
    this.shopId,
    this.shopName,
    this.rating,
    this.soldCount,
    this.address,
    this.distanceKm,
  });

  final int serviceId;
  final String name;
  final String? image;
  final num? price;
  final int? shopId;
  final String? shopName;
  final double? rating;
  final int? soldCount;
  final String? address;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ImageUrlUtil.buildPublicUrl(image);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        title: const Text('Chi tiết dịch vụ'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 1.25,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const _ServiceFallbackImage(),
                    )
                  : const _ServiceFallbackImage(),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  PriceFormatter.formatVnd(price, fallback: 'Liên hệ'),
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFF4D4F),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: LucideIcons.store,
                  text: shopName?.isNotEmpty == true
                      ? shopName!
                      : 'Thông tin shop đang cập nhật',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: LucideIcons.star,
                  text:
                      '${(rating ?? 0).toStringAsFixed(1)} (${soldCount ?? 0})',
                ),
                if (distanceKm != null) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: LucideIcons.mapPin,
                    text: '${distanceKm!.toStringAsFixed(1)} km',
                  ),
                ],
                if (address?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  _InfoRow(icon: LucideIcons.mapPin, text: address!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A4E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SpaServiceScreen(),
                  ),
                );
              },
              child: const Text('Xem danh sách dịch vụ'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 13,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _ServiceFallbackImage extends StatelessWidget {
  const _ServiceFallbackImage();

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
        child: Icon(LucideIcons.sparkles, color: Color(0xFFFF5A4E), size: 56),
      ),
    );
  }
}
