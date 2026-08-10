import 'global_chat_message.dart';

/// Модель ответа API со списком сообщений глобального чата
class GlobalChatMessageListResponse {
  final List<GlobalChatMessage> messages;
  final int total;
  final int skip;
  final int limit;
  final int onlineCount;

  GlobalChatMessageListResponse({
    required this.messages,
    required this.total,
    required this.skip,
    required this.limit,
    required this.onlineCount,
  });

  factory GlobalChatMessageListResponse.fromJson(Map<String, dynamic> json) {
    return GlobalChatMessageListResponse(
      messages: (json['messages'] as List)
          .map((item) =>
              GlobalChatMessage.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num).toInt(),
      skip: (json['skip'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      onlineCount: (json['online_count'] as num?)?.toInt() ?? 0,
    );
  }
}











