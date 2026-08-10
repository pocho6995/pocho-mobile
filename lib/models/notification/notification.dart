/// Модель уведомления
class Notification {
  final int id;
  final int? userId;
  final String title;
  final String message;
  final NotificationType notificationType;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic> extraData;
  final DateTime createdAt;

  Notification({
    required this.id,
    this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    this.readAt,
    required this.extraData,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
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

    return Notification(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] != null ? (json['user_id'] as num).toInt() : null,
      title: json['title'] as String,
      message: json['message'] as String,
      notificationType: NotificationType.fromString(
        json['notification_type'] as String? ?? 'info',
      ),
      isRead: json['is_read'] as bool? ?? false,
      readAt: parseDateTime(json['read_at']),
      extraData: json['extra_data'] != null
          ? json['extra_data'] as Map<String, dynamic>
          : {},
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'notification_type': notificationType.toString(),
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'extra_data': extraData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Notification copyWith({
    int? id,
    int? userId,
    String? title,
    String? message,
    NotificationType? notificationType,
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? extraData,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      notificationType: notificationType ?? this.notificationType,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      extraData: extraData ?? this.extraData,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Тип уведомления
enum NotificationType {
  info,
  warning,
  success,
  error,
  promotion;

  static NotificationType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'info':
        return NotificationType.info;
      case 'warning':
        return NotificationType.warning;
      case 'success':
        return NotificationType.success;
      case 'error':
        return NotificationType.error;
      case 'promotion':
        return NotificationType.promotion;
      default:
        return NotificationType.info;
    }
  }

  @override
  String toString() {
    switch (this) {
      case NotificationType.info:
        return 'info';
      case NotificationType.warning:
        return 'warning';
      case NotificationType.success:
        return 'success';
      case NotificationType.error:
        return 'error';
      case NotificationType.promotion:
        return 'promotion';
    }
  }

  /// Иконка для типа уведомления
  String get iconName {
    switch (this) {
      case NotificationType.info:
        return 'info';
      case NotificationType.warning:
        return 'warning';
      case NotificationType.success:
        return 'check_circle';
      case NotificationType.error:
        return 'error';
      case NotificationType.promotion:
        return 'local_offer';
    }
  }

  /// Цвет для типа уведомления
  int get colorValue {
    switch (this) {
      case NotificationType.info:
        return 0xFF1565C0; // Синий
      case NotificationType.warning:
        return 0xFFF59E0B; // Желтый
      case NotificationType.success:
        return 0xFF10B981; // Зеленый
      case NotificationType.error:
        return 0xFFEF4444; // Красный
      case NotificationType.promotion:
        return 0xFFFF9800; // Оранжевый
    }
  }
}

