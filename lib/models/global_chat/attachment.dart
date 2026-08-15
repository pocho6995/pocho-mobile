import '../../utils/image_url_helper.dart';

/// Модель вложения в сообщении
class Attachment {
  final String url;
  final String type;
  final String name;
  final int size;

  Attachment({
    required this.url,
    required this.type,
    required this.name,
    required this.size,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      url: ImageUrlHelper.getFullImageUrlOrEmpty(json['url'] as String?),
      type: json['type'] as String? ?? 'file',
      name: json['name'] as String? ?? 'file',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'url': url, 'type': type, 'name': name, 'size': size};
  }

  String get sizeFormatted {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
