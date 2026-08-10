/// Модель блокировки пользователя
class UserBlock {
  final int id;
  final int blockerId;
  final int blockedId;
  final String blockedUserName;
  final DateTime createdAt;

  UserBlock({
    required this.id,
    required this.blockerId,
    required this.blockedId,
    required this.blockedUserName,
    required this.createdAt,
  });

  factory UserBlock.fromJson(Map<String, dynamic> json) {
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

    return UserBlock(
      id: (json['id'] as num).toInt(),
      blockerId: (json['blocker_id'] as num).toInt(),
      blockedId: (json['blocked_id'] as num).toInt(),
      blockedUserName: json['blocked_user_name'] as String,
      createdAt: parseDateTime(json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blocker_id': blockerId,
      'blocked_id': blockedId,
      'blocked_user_name': blockedUserName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

