import 'package:flutter_test/flutter_test.dart';
import 'package:pocho_new/utils/image_url_helper.dart';

void main() {
  group('ImageUrlHelper', () {
    test('rewrites localhost absolute urls to api host', () {
      final url = ImageUrlHelper.getFullImageUrl(
        'http://localhost:8000/uploads/avatars/2_abc.png',
      );
      expect(url, 'https://olmatech.uz/uploads/avatars/2_abc.png');
    });

    test('rewrites 127.0.0.1 urls and drops loopback port', () {
      final url = ImageUrlHelper.getFullImageUrl(
        'http://127.0.0.1:8000/uploads/x.jpg',
      );
      expect(url, 'https://olmatech.uz/uploads/x.jpg');
    });

    test('keeps production absolute urls', () {
      final url = ImageUrlHelper.getFullImageUrl(
        'https://olmatech.uz/uploads/a.png',
      );
      expect(url, 'https://olmatech.uz/uploads/a.png');
    });

    test('builds from relative path', () {
      final url = ImageUrlHelper.getFullImageUrl('/uploads/a.png');
      expect(url, 'https://olmatech.uz/uploads/a.png');
    });

    test('null/empty -> null', () {
      expect(ImageUrlHelper.getFullImageUrl(null), isNull);
      expect(ImageUrlHelper.getFullImageUrl(''), isNull);
    });
  });
}
