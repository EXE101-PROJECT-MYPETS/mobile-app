class BookingCreateRequest {
  const BookingCreateRequest({
    required this.startAt,
    required this.items,
    this.petId,
    this.note,
  });

  final int? petId;
  final DateTime startAt;
  final String? note;
  final List<BookingItemCreateRequest> items;

  Map<String, dynamic> toJson() {
    return {
      if (petId != null) 'petId': petId,
      'startAt': _formatDateTimeWithOffset(startAt),
      'note': note?.trim().isEmpty == true ? null : note?.trim(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }

  static String _formatDateTimeWithOffset(DateTime value) {
    final local = value.toLocal();
    final offset = local.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final absoluteOffset = offset.abs();
    final offsetHours = absoluteOffset.inHours.toString().padLeft(2, '0');
    final offsetMinutes = (absoluteOffset.inMinutes % 60).toString().padLeft(
          2,
          '0',
        );

    String twoDigits(int number) => number.toString().padLeft(2, '0');

    return '${local.year.toString().padLeft(4, '0')}-'
        '${twoDigits(local.month)}-'
        '${twoDigits(local.day)}T'
        '${twoDigits(local.hour)}:'
        '${twoDigits(local.minute)}:'
        '${twoDigits(local.second)}'
        '$sign$offsetHours:$offsetMinutes';
  }
}

class BookingItemCreateRequest {
  const BookingItemCreateRequest({
    required this.itemType,
    required this.refId,
    required this.qty,
  });

  final String itemType;
  final int refId;
  final int qty;

  Map<String, dynamic> toJson() {
    return {'itemType': itemType, 'refId': refId, 'qty': qty};
  }
}
