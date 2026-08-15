import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../models/support/support_message.dart';
import '../utils/websocket_uri.dart';
import 'token_storage.dart';

/// WebSocket сервис для чата поддержки в реальном времени
class SupportWebSocketService {
  WebSocketChannel? _channel;
  final TokenStorage _tokenStorage;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _isConnecting = false;
  int? _currentTicketId;

  // Callbacks
  Function(SupportMessage)? onMessageReceived;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(dynamic)? onError;

  SupportWebSocketService({required TokenStorage tokenStorage})
    : _tokenStorage = tokenStorage;

  /// Подключиться к WebSocket чату тикета
  Future<void> connect(int ticketId) async {
    // Если уже подключены к этому тикету, ничего не делаем
    if (_isConnected && _currentTicketId == ticketId) {
      if (kDebugMode) {
        print('WebSocket уже подключен к тикету $ticketId');
      }
      return;
    }

    // Если подключены к другому тикету, отключаемся
    if (_isConnected && _currentTicketId != ticketId) {
      await disconnect();
    }

    if (_isConnecting) {
      if (kDebugMode) {
        print('WebSocket уже подключается');
      }
      return;
    }

    try {
      _isConnecting = true;
      _currentTicketId = ticketId;

      final token = await _tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('WebSocket: Токен не найден, подключение невозможно');
        }
        _isConnecting = false;
        return;
      }

      final finalUri = WebSocketUriBuilder.build(
        baseUrl: AppConfig.wsBaseUrl,
        path: '/api/v1/support/ws/ticket/$ticketId',
        queryParameters: {'token': token},
      );

      if (kDebugMode) {
        print('🔌 Support WebSocket: $finalUri');
      }

      _channel = WebSocketChannel.connect(finalUri);

      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          if (kDebugMode) {
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            print('❌ Support WebSocket Error: $error');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          }
          _isConnected = false;
          _isConnecting = false;
          onError?.call(error);
        },
        onDone: () {
          if (kDebugMode) {
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            print('🔌 Support WebSocket: Соединение закрыто');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          }
          _isConnected = false;
          _isConnecting = false;
          _currentTicketId = null;
          onDisconnected?.call();
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
        print('✅ Support WebSocket: Подключено');
      }

      onConnected?.call();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Support WebSocket: Ошибка подключения');
        print('   Error: $e');
      }
      _isConnected = false;
      _isConnecting = false;
      _currentTicketId = null;
      onError?.call(e);
    }
  }

  /// Обработка входящих сообщений
  void _handleMessage(dynamic message) {
    try {
      if (message == 'pong') {
        if (kDebugMode) {
          print('🏓 Support WebSocket: Получен pong');
        }
        return;
      }

      final data = jsonDecode(message.toString());

      if (kDebugMode) {
        print('📨 Support WebSocket: Получено сообщение');
        print('   Type: ${data['type']}');
      }

      if (data['type'] == 'connection') {
        if (kDebugMode) {
          print('✅ Support WebSocket: Подтверждение подключения');
          print('   Ticket ID: ${data['ticket_id']}');
          print('   User ID: ${data['user_id']}');
        }
        return;
      }

      if (data['type'] == 'new_message') {
        final messageData = data['message'] as Map<String, dynamic>;
        final supportMessage = SupportMessage.fromJson(messageData);

        if (kDebugMode) {
          print('💬 Support WebSocket: Новое сообщение');
          print('   Message ID: ${supportMessage.id}');
          print('   From User: ${supportMessage.isFromUser}');
        }

        onMessageReceived?.call(supportMessage);
      } else if (data['type'] == 'pong') {
        if (kDebugMode) {
          print('🏓 Support WebSocket: Получен pong');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Support WebSocket: Ошибка обработки сообщения');
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
          print('🏓 Support WebSocket: Отправлен ping');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Support WebSocket: Ошибка отправки ping');
          print('   Error: $e');
        }
      }
    }
  }

  /// Отключиться от WebSocket
  Future<void> disconnect() async {
    if (kDebugMode) {
      print('🔌 Support WebSocket: Отключение...');
    }

    _pingTimer?.cancel();
    _pingTimer = null;

    try {
      await _channel?.sink.close();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Support WebSocket: Ошибка при отключении');
        print('   Error: $e');
      }
    }

    _channel = null;
    _isConnected = false;
    _isConnecting = false;
    _currentTicketId = null;

    if (kDebugMode) {
      print('✅ Support WebSocket: Отключено');
    }

    onDisconnected?.call();
  }

  /// Проверить, подключены ли мы
  bool get isConnected => _isConnected;

  /// Получить ID текущего тикета
  int? get currentTicketId => _currentTicketId;
}
