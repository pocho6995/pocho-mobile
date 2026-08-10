import 'notification.dart';

/// Ответ на запрос списка уведомлений
class NotificationListResponse {
  final List<Notification> notifications;
  final int total;
  final int unreadCount;
  final int skip;
  final int limit;

  NotificationListResponse({
    required this.notifications,
    required this.total,
    required this.unreadCount,
    required this.skip,
    required this.limit,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final notificationsList = json['notifications'] as List<dynamic>? ?? [];
    return NotificationListResponse(
      notifications: notificationsList
          .map((item) => Notification.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifications': notifications.map((n) => n.toJson()).toList(),
      'total': total,
      'unread_count': unreadCount,
      'skip': skip,
      'limit': limit,
    };
  }
}












