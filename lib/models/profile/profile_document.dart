import '../../utils/image_url_helper.dart';

class ProfileDocument {
  final String? imageUrl;
  final bool verified;
  final DateTime? uploadedAt;

  ProfileDocument({
    this.imageUrl,
    required this.verified,
    this.uploadedAt,
  });

  factory ProfileDocument.fromJson(Map<String, dynamic> json) {
    String? uploadedAtStr = json['uploaded_at'] as String?;
    DateTime? uploadedAt;
    
    if (uploadedAtStr != null && uploadedAtStr.isNotEmpty && uploadedAtStr != 'null') {
      try {
        uploadedAt = DateTime.parse(uploadedAtStr);
      } catch (e) {
        // Игнорируем ошибки парсинга даты
        uploadedAt = null;
      }
    }
    
    return ProfileDocument(
      imageUrl: ImageUrlHelper.getFullImageUrl(json['image_url'] as String?),
      verified: json['verified'] as bool? ?? false,
      uploadedAt: uploadedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'verified': verified,
      'uploaded_at': uploadedAt?.toIso8601String(),
    };
  }
}

