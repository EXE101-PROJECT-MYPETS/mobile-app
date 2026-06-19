import 'package:flutter_test/flutter_test.dart';
import 'package:pawly_mobile/common/utils/image_url_util.dart';

void main() {
  group('ImageUrlUtil.buildPublicUrl', () {
    const baseUrl = ImageUrlUtil.supabasePublicBaseUrl;

    test('builds Supabase public URL from uploads path', () {
      expect(
        ImageUrlUtil.buildPublicUrl('uploads/shops/1/avatar/file.jpg'),
        '$baseUrl/uploads/shops/1/avatar/file.jpg',
      );
    });

    test('builds Supabase public URL from slash-prefixed uploads path', () {
      expect(
        ImageUrlUtil.buildPublicUrl('/uploads/shops/1/avatar/file.jpg'),
        '$baseUrl/uploads/shops/1/avatar/file.jpg',
      );
    });

    test('rewrites legacy backend uploads URL to Supabase public URL', () {
      expect(
        ImageUrlUtil.buildPublicUrl(
          'http://192.168.1.11:8080/uploads/shops/1/avatar/file.jpg',
        ),
        '$baseUrl/uploads/shops/1/avatar/file.jpg',
      );
    });

    test('keeps non-storage absolute URL unchanged', () {
      const url = 'https://example.com/images/file.jpg';
      expect(ImageUrlUtil.buildPublicUrl(url), url);
    });
  });
}
