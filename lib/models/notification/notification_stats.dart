/// Статистика уведомлений
class NotificationStats {
  final int total;
  final int unread;
  final int read;

  NotificationStats({
    required this.total,
    required this.unread,
    required this.read,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      total: (json['total'] as num?)?.toInt() ?? 0,
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      read: (json['read'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'unread': unread,
      'read': read,
    };
  }
}












