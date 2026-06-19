class ImageUrlUtil {
  static const String supabasePublicBaseUrl =
      'https://zwhhqsflmocntuvzbvqm.supabase.co/storage/v1/object/public';

  static String? buildPublicUrl(String? path) {
    final value = path?.trim();
    if (value == null || value.isEmpty) return null;

    final publicStoragePath = _extractPublicStoragePath(value);
    if (publicStoragePath != null && publicStoragePath.isNotEmpty) {
      return '$supabasePublicBaseUrl/$publicStoragePath';
    }

    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) {
      return value;
    }

    return '$supabasePublicBaseUrl/${_normalizePath(value)}';
  }

  static List<String> buildPublicUrls(Iterable<String>? paths) {
    if (paths == null) return [];
    return paths
        .map(buildPublicUrl)
        .whereType<String>()
        .toList(growable: false);
  }

  static String? _extractPublicStoragePath(String value) {
    const publicPathMarker = '/storage/v1/object/public/';
    final lowerValue = value.toLowerCase();
    final publicPathIndex = lowerValue.indexOf(publicPathMarker);
    if (publicPathIndex >= 0) {
      return _normalizePath(
        value.substring(publicPathIndex + publicPathMarker.length),
      );
    }

    final uploadsIndex = lowerValue.indexOf('/uploads/');
    if (uploadsIndex >= 0) {
      return _normalizePath(value.substring(uploadsIndex + 1));
    }

    if (lowerValue.startsWith('uploads/') ||
        lowerValue.startsWith('/uploads/')) {
      return _normalizePath(value);
    }

    return null;
  }

  static String _normalizePath(String value) {
    return value.replaceFirst(RegExp(r'^/+'), '');
  }
}
