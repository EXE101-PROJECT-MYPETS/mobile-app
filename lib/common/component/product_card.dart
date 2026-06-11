import 'package:flutter/material.dart';
import 'package:pawly_mobile/apps/product/model/product_model.dart';
import 'package:pawly_mobile/apps/product/page/product_detail_screen.dart';
import 'package:pawly_mobile/apps/product/page/spa_service_screen.dart';
import 'package:pawly_mobile/common/utils/category_badge_style.dart';
import 'package:pawly_mobile/common/utils/price_formatter.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  String get _formattedPrice {
    final raw = product.price.trim();
    final normalized = raw
        .replaceAll('đ', '')
        .replaceAll('Ä‘', '')
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();
    final amount = num.tryParse(normalized);
    return amount != null ? PriceFormatter.formatVnd(amount) : product.price;
  }

  @override
  Widget build(BuildContext context) {
    final trimmedCategory = product.category.trim();
    final categoryLabel = trimmedCategory.isNotEmpty ? trimmedCategory : null;
    final categoryBadgeStyle = categoryLabel != null
        ? resolveCategoryBadgeStyle(categoryLabel)
        : null;

    return GestureDetector(
      onTap: () {
        if (product.type == 'spa') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SpaServiceScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(productId: product.id),
            ),
          );
        }
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
                    child: Hero(
                      tag: 'product_image_${product.id}',
                      child: Image.network(product.image, fit: BoxFit.cover),
                    ),
                  ),
                  if (categoryLabel != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 92),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryBadgeStyle!.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          categoryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: categoryBadgeStyle.textColor,
                          ),
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
                    product.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formattedPrice,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFB7185),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            product.rating.toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '(${product.reviews})',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_shipping,
                        color: Color(0xFF0D9488),
                        size: 13,
                      ),
                      const SizedBox(width: 3),
                      const Text(
                        '2 - 5 ngày',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '|',
                        style: TextStyle(fontSize: 9, color: Color(0xFFCBD5E1)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF94A3B8),
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product.shopProvince,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
