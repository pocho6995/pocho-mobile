/// Модель сообщения в тикете поддержки
class SupportMessage {
  final int id;
  final int ticketId;
  final int userId;
  final String message;
  final bool isFromUser;
  final List<String>? attachments;
  final DateTime createdAt;

  SupportMessage({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.message,
    required this.isFromUser,
    this.attachments,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null || value == 'null') return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    List<String>? parseAttachments(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return null;
    }

    return SupportMessage(
      id: (json['id'] as num).toInt(),
      ticketId: (json['ticket_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      message: json['message'] as String,
      isFromUser: json['is_from_user'] as bool? ?? true,
      attachments: parseAttachments(json['attachments']),
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'user_id': userId,
      'message': message,
      'is_from_user': isFromUser,
      'attachments': attachments,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

