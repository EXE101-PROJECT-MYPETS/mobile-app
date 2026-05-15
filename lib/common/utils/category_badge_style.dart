import 'package:flutter/material.dart';

class CategoryBadgeStyle {
  const CategoryBadgeStyle({
    required this.backgroundColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color textColor;
}

CategoryBadgeStyle resolveCategoryBadgeStyle(String label) {
  switch (_normalizeCategoryLabel(label)) {
    case 'thucan':
      return const CategoryBadgeStyle(
        backgroundColor: Color(0xFFFF8A34),
        textColor: Colors.white,
      );
    case 'chamsoc':
      return const CategoryBadgeStyle(
        backgroundColor: Color(0xFF0EA5A4),
        textColor: Colors.white,
      );
    case 'dochoi':
      return const CategoryBadgeStyle(
        backgroundColor: Color(0xFFFF5A4E),
        textColor: Colors.white,
      );
    case 'phukien':
      return const CategoryBadgeStyle(
        backgroundColor: Color(0xFF3B82F6),
        textColor: Colors.white,
      );
    default:
      return const CategoryBadgeStyle(
        backgroundColor: Color(0xFF64748B),
        textColor: Colors.white,
      );
  }
}

String _normalizeCategoryLabel(String value) {
  final lower = value.trim().toLowerCase();
  const replacements = {
    'à': 'a',
    'á': 'a',
    'ả': 'a',
    'ã': 'a',
    'ạ': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'ặ': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ậ': 'a',
    'è': 'e',
    'é': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ẹ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ệ': 'e',
    'ì': 'i',
    'í': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ị': 'i',
    'ò': 'o',
    'ó': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ọ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ộ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ợ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ụ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ự': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'ỵ': 'y',
    'đ': 'd',
  };

  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(replacements[char] ?? char);
  }

  return buffer.toString().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}
