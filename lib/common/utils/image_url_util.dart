class ImageUrlUtil {
  static const String _supabasePublicBaseUrl =
      'https://zwhhqsflmocntuvzbvqm.supabase.co/storage/v1/object/public';

  static String? buildPublicUrl(String? path) {
    final value = path?.trim();
    if (value == null || value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      return value;
    }

    final normalizedPath = value.replaceFirst(RegExp(r'^/+'), '');
    return '$_supabasePublicBaseUrl/$normalizedPath';
  }

  static List<String> buildPublicUrls(Iterable<String>? paths) {
    if (paths == null) return [];
    return paths
        .map(buildPublicUrl)
        .whereType<String>()
        .toList(growable: false);
  }
}
