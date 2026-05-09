import 'package:intl/intl.dart';

class PriceFormatter {
  static final NumberFormat _vndFormatter = NumberFormat('#,##0', 'vi_VN');

  static String formatVnd(num? amount, {String fallback = 'Liên hệ'}) {
    if (amount == null) return fallback;
    return '${_vndFormatter.format(amount).replaceAll(',', '.')}đ';
  }
}