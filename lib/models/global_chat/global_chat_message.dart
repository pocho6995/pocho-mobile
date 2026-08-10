import 'attachment.dart';

/// Модель сообщения в глобальном чате
class GlobalChatMessage {
  final int id;
  final int userId;
  final String userName;
  final String? userAvatar;
  final String? message;
  final MessageType messageType;
  final List<Attachment>? attachments;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  GlobalChatMessage({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.message,
    required this.messageType,
    this.attachments,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  factory GlobalChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null || value == 'null') return null;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    List<Attachment>? parseAttachments(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        try {
          return value
              .where((item) => item is Map<String, dynamic>)
              .map((item) => Attachment.fromJson(item as Map<String, dynamic>))
              .toList();
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return GlobalChatMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      userName: json['user_name'] as String? ?? 'Пользователь',
      userAvatar: json['user_avatar'] as String?,
      message: json['message'] as String?,
      messageType: MessageType.fromString(
        json['message_type'] as String? ?? 'text',
      ),
      attachments: parseAttachments(json['attachments']),
      metadata: json['metadata'] != null
          ? json['metadata'] as Map<String, dynamic>?
          : null,
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'message': message,
      'message_type': messageType.value,
      'attachments': attachments?.map((a) => a.toJson()).toList(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Типы сообщений
enum MessageType {
  text('text'),
  image('image'),
  video('video'),
  file('file'),
  audio('audio');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String? value) {
    if (value == null || value.isEmpty) {
      return MessageType.text;
    }
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }

  String get displayName {
    switch (this) {
      case MessageType.text:
        return 'Текст';
      case MessageType.image:
        return 'Изображение';
      case MessageType.video:
        return 'Видео';
      case MessageType.file:
        return 'Файл';
      case MessageType.audio:
        return 'Аудио';
    }
  }

  String get iconName {
    switch (this) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.video:
        return 'video';
      case MessageType.file:
        return 'file';
      case MessageType.audio:
        return 'audio';
    }
  }
}
