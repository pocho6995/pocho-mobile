import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../models/global_chat/global_chat_message.dart';
import 'token_storage.dart';

/// WebSocket сервис для глобального чата в реальном времени
class GlobalChatWebSocketService {
  WebSocketChannel? _channel;
  final TokenStorage _tokenStorage;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _isConnecting = false;

  // Callbacks
  Function(GlobalChatMessage)? onMessageReceived;
  Function(int)? onOnlineCountUpdated;
  Function(int)? onMessageDeleted;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(dynamic)? onError;

  GlobalChatWebSocketService({required TokenStorage tokenStorage})
    : _tokenStorage = tokenStorage;

  /// Подключиться к WebSocket глобального чата
  Future<void> connect() async {
    if (_isConnecting || _isConnected) {
      if (kDebugMode) {
        print('WebSocket уже подключен или подключается');
      }
      return;
    }

    try {
      _isConnecting = true;

      final token = await _tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('WebSocket: Токен не найден, подключение невозможно');
        }
        _isConnecting = false;
        return;
      }

      final baseUrl = AppConfig.wsBaseUrl;

      final wsUrl =
          '$baseUrl/api/v1/global-chat/ws?token=${Uri.encodeComponent(token)}';

      if (kDebugMode) {
        print('🔍 Global Chat WebSocket URL Debug:');
        print('   Final baseUrl: $baseUrl');
        print('   Final wsUrl: $wsUrl');
      }

      if (kDebugMode) {
        print('🔍 Global Chat WebSocket: Проверка параметров');
        print('   Token length: ${token.length}');
        print(
          '   Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...',
        );
      }

      // Парсим URI и проверяем протокол
      final uri = Uri.parse(wsUrl);
      if (kDebugMode) {
        print('🔍 Parsed URI Debug:');
        print('   Scheme: ${uri.scheme}');
        print('   Host: ${uri.host}');
        print('   Port: ${uri.port}');
        print('   HasPort: ${uri.hasPort}');
        print('   Full URI: $uri');
      }

      // Если схема wss:// и порт 0 или не указан, исправляем на порт 443
      // Если схема ws:// и порт 0 или не указан, исправляем на порт 80
      Uri finalUri = uri;
      if (uri.scheme == 'wss' && (uri.port == 0 || !uri.hasPort)) {
        finalUri = uri.replace(port: 443);
        if (kDebugMode) {
          print('⚠️ WSS port was 0 or missing, corrected to 443');
          print('   Corrected URI: $finalUri');
        }
      } else if (uri.scheme == 'ws' && (uri.port == 0 || !uri.hasPort)) {
        finalUri = uri.replace(port: 80);
        if (kDebugMode) {
          print('⚠️ WS port was 0 or missing, corrected to 80');
          print('   Corrected URI: $finalUri');
        }
      }

      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🔌 Global Chat WebSocket: Подключение...');
        print('📍 Final URI: $finalUri');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      _channel = WebSocketChannel.connect(finalUri);

      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          if (kDebugMode) {
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            print('❌ Global Chat WebSocket Error: $error');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          }
          _isConnected = false;
          _isConnecting = false;
          onError?.call(error);
          // Автоматическое переподключение через 5 секунд
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isConnected) {
              connect();
            }
          });
        },
        onDone: () {
          if (kDebugMode) {
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            print('🔌 Global Chat WebSocket: Соединение закрыто');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          }
          _isConnected = false;
          _isConnecting = false;
          onDisconnected?.call();
          // Автоматическое переподключение через 5 секунд
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isConnected) {
              connect();
            }
          });
        },
        cancelOnError: false,
      );

      // Запускаем ping каждые 30 секунд
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _sendPing();
      });

      _isConnected = true;
      _isConnecting = false;

      if (kDebugMode) {
        print('✅ Global Chat WebSocket: Подключено');
      }

      onConnected?.call();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Global Chat WebSocket: Ошибка подключения');
        print('   Error: $e');
      }
      _isConnected = false;
      _isConnecting = false;
      onError?.call(e);
    }
  }

  /// Обработка входящих сообщений
  void _handleMessage(dynamic message) {
    try {
      if (message == 'pong') {
        if (kDebugMode) {
          print('🏓 Global Chat WebSocket: Получен pong');
        }
        return;
      }

      final data = jsonDecode(message.toString());

      if (kDebugMode) {
        print('📨 Global Chat WebSocket: Получено сообщение');
        print('   Type: ${data['type']}');
      }

      if (data['type'] == 'connection') {
        if (kDebugMode) {
          print('✅ Global Chat WebSocket: Подтверждение подключения');
          print('   User ID: ${data['user_id']}');
          print('   Online Count: ${data['online_count']}');
        }
        final onlineCount = data['online_count'] as int? ?? 0;
        onOnlineCountUpdated?.call(onlineCount);
        return;
      }

      if (data['type'] == 'new_message') {
        final messageData = data['message'] as Map<String, dynamic>;
        final chatMessage = GlobalChatMessage.fromJson(messageData);

        if (kDebugMode) {
          print('💬 Global Chat WebSocket: Новое сообщение');
          print('   Message ID: ${chatMessage.id}');
          print('   User ID: ${chatMessage.userId}');
        }

        onMessageReceived?.call(chatMessage);
      } else if (data['type'] == 'online_count') {
        final onlineCount = data['online_count'] as int? ?? 0;
        if (kDebugMode) {
          print('👥 Global Chat WebSocket: Обновление онлайн');
          print('   Online Count: $onlineCount');
        }
        onOnlineCountUpdated?.call(onlineCount);
      } else if (data['type'] == 'message_deleted') {
        final messageId = data['message_id'] as int?;
        if (messageId != null) {
          if (kDebugMode) {
            print('🗑️ Global Chat WebSocket: Сообщение удалено');
            print('   Message ID: $messageId');
          }
          onMessageDeleted?.call(messageId);
        }
      } else if (data['type'] == 'pong') {
        if (kDebugMode) {
          print('🏓 Global Chat WebSocket: Получен pong');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Global Chat WebSocket: Ошибка обработки сообщения');
        print('   Error: $e');
        print('   Message: $message');
      }
    }
  }

  /// Отправить ping для поддержания соединения
  void _sendPing() {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add('ping');
        if (kDebugMode) {
          print('🏓 Global Chat WebSocket: Отправлен ping');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Global Chat WebSocket: Ошибка отправки ping');
          print('   Error: $e');
        }
      }
    }
  }

  /// Отключиться от WebSocket
  Future<void> disconnect() async {
    if (kDebugMode) {
      print('🔌 Global Chat WebSocket: Отключение...');
    }

    _pingTimer?.cancel();
    _pingTimer = null;

    try {
      await _channel?.sink.close();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Global Chat WebSocket: Ошибка при отключении');
        print('   Error: $e');
      }
    }

    _channel = null;
    _isConnected = false;
    _isConnecting = false;

    if (kDebugMode) {
      print('✅ Global Chat WebSocket: Отключено');
    }

    onDisconnected?.call();
  }

  /// Проверить, подключены ли мы
  bool get isConnected => _isConnected;
}
