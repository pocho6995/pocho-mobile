import 'profile_documents.dart';
import 'profile_settings.dart';

class ProfileResponse {
  final int id;
  final int userId;
  final ProfileDocuments documents;
  final ProfileSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileResponse({
    required this.id,
    required this.userId,
    required this.documents,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      documents: ProfileDocuments.fromJson(json['documents'] as Map<String, dynamic>),
      settings: ProfileSettings.fromJson(json['settings'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'documents': documents.toJson(),
      'settings': settings.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

