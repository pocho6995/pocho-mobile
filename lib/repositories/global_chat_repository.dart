import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/global_chat/global_chat_message.dart';
import '../models/global_chat/global_chat_message_list_response.dart';
import '../models/global_chat/user_block.dart';
import '../models/global_chat/blocked_users_response.dart';
import '../models/global_chat/upload_response.dart';
import '../models/global_chat/attachment.dart';
import '../services/global_chat_service.dart';
import '../services/global_chat_websocket_service.dart';

/// Репозиторий для управления глобальным чатом
class GlobalChatRepository {
  final GlobalChatService _chatService;
  final GlobalChatWebSocketService _webSocketService;

  // Кэш сообщений
  List<GlobalChatMessage> _messages = [];
  Set<int> _blockedUserIds = {};

  // Stream для новых сообщений
  final _messageStreamController =
      StreamController<GlobalChatMessage>.broadcast();
  Stream<GlobalChatMessage> get messageStream => _messageStreamController.stream;

  // Stream для обновления онлайн
  final _onlineCountStreamController = StreamController<int>.broadcast();
  Stream<int> get onlineCountStream => _onlineCountStreamController.stream;

  // Stream для удаленных сообщений
  final _messageDeletedStreamController = StreamController<int>.broadcast();
  Stream<int> get messageDeletedStream =>
      _messageDeletedStreamController.stream;

  GlobalChatRepository({
    required GlobalChatService chatService,
    required GlobalChatWebSocketService webSocketService,
  })  : _chatService = chatService,
        _webSocketService = webSocketService {
    // Подписываемся на WebSocket события
    _webSocketService.onMessageReceived = (message) {
      // Игнорируем сообщения от заблокированных пользователей
      if (!_blockedUserIds.contains(message.userId)) {
        _messageStreamController.add(message);
        // Добавляем в кэш
        _messages.insert(0, message);
      }
    };

    _webSocketService.onOnlineCountUpdated = (count) {
      _onlineCountStreamController.add(count);
    };

    _webSocketService.onMessageDeleted = (messageId) {
      _messageDeletedStreamController.add(messageId);
      // Удаляем из кэша
      _messages.removeWhere((m) => m.id == messageId);
    };

    _webSocketService.onConnected = () {
      if (kDebugMode) {
        print('✅ GlobalChatRepository: WebSocket подключен');
      }
    };

    _webSocketService.onError = (error) {
      if (kDebugMode) {
        print('❌ GlobalChatRepository: WebSocket ошибка: $error');
      }
    };
  }

  /// Загрузить сообщения
  Future<List<GlobalChatMessage>> loadMessages({
    int skip = 0,
    int limit = 100,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh && _messages.isNotEmpty && skip == 0) {
        return _messages;
      }

      final response = await _chatService.getMessages(
        skip: skip,
        limit: limit,
      );

      if (skip == 0) {
        _messages = response.messages;
      } else {
        _messages.addAll(response.messages);
      }

      // Обновляем счетчик онлайн
      if (response.onlineCount > 0) {
        _onlineCountStreamController.add(response.onlineCount);
      }

      return _messages;
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatRepository: Ошибка при загрузке сообщений');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Поиск сообщений
  Future<List<GlobalChatMessage>> searchMessages({
    required String query,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final response = await _chatService.searchMessages(
        query: query,
        skip: skip,
        limit: limit,
      );

      return response.messages;
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatRepository: Ошибка при поиске');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Отправить текстовое сообщение
  Future<GlobalChatMessage> sendTextMessage(String message) async {
    try {
      final chatMessage = await _chatService.sendMessage(
        message: message,
        messageType: MessageType.text,
      );

      // Добавляем в кэш
      _messages.insert(0, chatMessage);

      return chatMessage;
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatRepository: Ошибка при отправке сообщения');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Загрузить файл и отправить сообщение
  Future<GlobalChatMessage> sendFileMessage({
    required File file,
    required String fileType,
    String? caption,
  }) async {
    try {
      // Сначала загружаем файл
      final uploadResponse = await _chatService.uploadFile(
        file: file,
        fileType: fileType,
      );

      // Затем отправляем сообщение с вложением
      final messageType = uploadResponse.messageType;
      final chatMessage = await _chatService.sendMessage(
        message: caption ?? '',
        messageType: messageType,
        attachments: [uploadResponse.attachment],
      );

      // Добавляем в кэш
      _messages.insert(0, chatMessage);

      return chatMessage;
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatRepository: Ошибка при отправке файла');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Получить количество онлайн
  Future<int> getOnlineCount() async {
    try {
      return await _chatService.getOnlineCount();
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatRepository: Ошибка при получении онлайн');
        print('   Error: $e');
      }
      return 0;
    }
  }

  /// Заблокировать пользователя
  Future<UserBlock> blockUser(int userId) async {
    try {
      final userBlock = await _chatService.blockUser(userId);

      // Добавляем в список заблокированных
      _blockedUserIds.add(userId);

      // Удаляем сообщения заблокированного пользователя из кэша
      _messages.removeWhere((m) => m.userId == userId);

      return userBlock;
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatRepository: Ошибка при блокировке');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Разблокировать пользователя
  Future<void> unblockUser(int userId) async {
    try {
      await _chatService.unblockUser(userId);

      // Удаляем из списка заблокированных
      _blockedUserIds.remove(userId);

      // Перезагружаем сообщения, чтобы увидеть сообщения разблокированного пользователя
      await loadMessages(forceRefresh: true);
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatRepository: Ошибка при разблокировке');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Получить список заблокированных пользователей
  Future<List<UserBlock>> getBlockedUsers() async {
    try {
      final response = await _chatService.getBlockedUsers();

      // Обновляем список заблокированных ID
      _blockedUserIds = response.blockedUsers.map((b) => b.blockedId).toSet();

      return response.blockedUsers;
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatRepository: Ошибка при получении заблокированных');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Очистить историю чата (персонально)
  Future<int> clearHistory() async {
    try {
      final count = await _chatService.clearHistory();

      // Очищаем кэш
      _messages.clear();

      return count;
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatRepository: Ошибка при очистке истории');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Удалить сообщение (для всех)
  Future<void> deleteMessage(int messageId) async {
    try {
      await _chatService.deleteMessage(messageId);

      // Удаляем из кэша
      _messages.removeWhere((m) => m.id == messageId);
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatRepository: Ошибка при удалении сообщения');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Подключиться к WebSocket
  Future<void> connectWebSocket() async {
    try {
      if (kDebugMode) {
        print('🔌 GlobalChatRepository: Подключение к WebSocket...');
      }
      await _webSocketService.connect();
      if (kDebugMode) {
        print('✅ GlobalChatRepository: WebSocket подключен');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatRepository: Ошибка подключения WebSocket');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Отключиться от WebSocket
  Future<void> disconnectWebSocket() async {
    await _webSocketService.disconnect();
  }

  /// Получить сообщения из кэша
  List<GlobalChatMessage> getCachedMessages() {
    return List.from(_messages);
  }

  /// Добавить сообщение в кэш (из WebSocket)
  void addMessageToCache(GlobalChatMessage message) {
    if (!_blockedUserIds.contains(message.userId)) {
      _messages.insert(0, message);
    }
  }

  /// Очистить кэш
  void clearCache() {
    _messages.clear();
  }

  /// Проверить, заблокирован ли пользователь
  bool isUserBlocked(int userId) {
    return _blockedUserIds.contains(userId);
  }

  void dispose() {
    _messageStreamController.close();
    _onlineCountStreamController.close();
    _messageDeletedStreamController.close();
  }
}

