import 'support_message.dart';

/// Модель тикета поддержки
class SupportTicket {
  final int id;
  final int userId;
  final String subject;
  final TicketStatus status;
  final TicketPriority priority;
  final int? assignedTo;
  final bool isReadByUser;
  final bool isReadByAdmin;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final List<SupportMessage>? messages;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.status,
    required this.priority,
    this.assignedTo,
    required this.isReadByUser,
    required this.isReadByAdmin,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.closedAt,
    this.messages,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
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

    List<SupportMessage>? parseMessages(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value
            .map((item) => SupportMessage.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return null;
    }

    return SupportTicket(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      subject: json['subject'] as String,
      status: TicketStatus.fromString(json['status'] as String),
      priority: TicketPriority.fromString(json['priority'] as String),
      assignedTo: json['assigned_to'] != null
          ? (json['assigned_to'] as num).toInt()
          : null,
      isReadByUser: json['is_read_by_user'] as bool? ?? false,
      isReadByAdmin: json['is_read_by_admin'] as bool? ?? false,
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updated_at']),
      resolvedAt: parseDateTime(json['resolved_at']),
      closedAt: parseDateTime(json['closed_at']),
      messages: parseMessages(json['messages']) ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject': subject,
      'status': status.value,
      'priority': priority.value,
      'assigned_to': assignedTo,
      'is_read_by_user': isReadByUser,
      'is_read_by_admin': isReadByAdmin,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      if (messages != null && messages!.isNotEmpty)
        'messages': messages!.map((m) => m.toJson()).toList(),
    };
  }
}

/// Статусы тикета
enum TicketStatus {
  open('open'),
  inProgress('in_progress'),
  waitingForUser('waiting_for_user'),
  resolved('resolved'),
  closed('closed');

  final String value;
  const TicketStatus(this.value);

  static TicketStatus fromString(String value) {
    return TicketStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TicketStatus.open,
    );
  }

  String get displayName {
    switch (this) {
      case TicketStatus.open:
        return 'Открыт';
      case TicketStatus.inProgress:
        return 'В работе';
      case TicketStatus.waitingForUser:
        return 'Ожидание ответа';
      case TicketStatus.resolved:
        return 'Решен';
      case TicketStatus.closed:
        return 'Закрыт';
    }
  }

  int get colorValue {
    switch (this) {
      case TicketStatus.open:
        return 0xFF2196F3; // Синий
      case TicketStatus.inProgress:
        return 0xFFFF9800; // Оранжевый
      case TicketStatus.waitingForUser:
        return 0xFFFFC107; // Желтый
      case TicketStatus.resolved:
        return 0xFF4CAF50; // Зеленый
      case TicketStatus.closed:
        return 0xFF9E9E9E; // Серый
    }
  }
}

/// Приоритеты тикета
enum TicketPriority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  final String value;
  const TicketPriority(this.value);

  static TicketPriority fromString(String value) {
    return TicketPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => TicketPriority.medium,
    );
  }

  String get displayName {
    switch (this) {
      case TicketPriority.low:
        return 'Низкий';
      case TicketPriority.medium:
        return 'Средний';
      case TicketPriority.high:
        return 'Высокий';
      case TicketPriority.urgent:
        return 'Срочный';
    }
  }

  int get colorValue {
    switch (this) {
      case TicketPriority.low:
        return 0xFF4CAF50; // Зеленый
      case TicketPriority.medium:
        return 0xFF2196F3; // Синий
      case TicketPriority.high:
        return 0xFFFF9800; // Оранжевый
      case TicketPriority.urgent:
        return 0xFFF44336; // Красный
    }
  }
}

