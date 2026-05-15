class ScrollResponse<T> {
  final List<T> content;
  final int size;
  final int? nextCursor;
  final bool hasNext;

  ScrollResponse({
    required this.content,
    required this.size,
    this.nextCursor,
    required this.hasNext,
  });

  factory ScrollResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return ScrollResponse<T>(
      content:
          (json['content'] as List<dynamic>?)
              ?.map((item) => fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      size: json['size'] as int? ?? 0,
      nextCursor: json['nextCursor'] as int?,
      hasNext: json['hasNext'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'size': size,
      'nextCursor': nextCursor,
      'hasNext': hasNext,
    };
  }
}
