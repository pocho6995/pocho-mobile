import 'user_block.dart';

/// Модель ответа API со списком заблокированных пользователей
class BlockedUsersResponse {
  final List<UserBlock> blockedUsers;
  final int total;

  BlockedUsersResponse({
    required this.blockedUsers,
    required this.total,
  });

  factory BlockedUsersResponse.fromJson(Map<String, dynamic> json) {
    return BlockedUsersResponse(
      blockedUsers: (json['blocked_users'] as List)
          .map((item) => UserBlock.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
    );
  }
}











