import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../models/notification/notification.dart';
import 'token_storage.dart';

/// WebSocket сервис для получения уведомлений в реальном времени
class NotificationWebSocketService {
  WebSocketChannel? _channel;
  final TokenStorage _tokenStorage;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _isConnecting = false;

  // Callbacks
  Function(Notification)? onNotificationReceived;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(dynamic)? onError;

  NotificationWebSocketService({required TokenStorage tokenStorage})
    : _tokenStorage = tokenStorage;

  /// Подключиться к WebSocket
  Future<void> connect() async {
    if (_isConnecting || _isConnected) {
      return;
    }

    try {
      _isConnecting = true;

      final token = await _tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        _isConnecting = false;
        return;
      }

      final baseUrl = AppConfig.wsBaseUrl;

      final wsUrl =
          '$baseUrl/api/v1/notifications/ws/notifications?token=${Uri.encodeComponent(token)}';

      // Парсим URI и проверяем протокол
      final uri = Uri.parse(wsUrl);

      // Если схема wss:// и порт 0 или не указан, исправляем на порт 443
      // Если схема ws:// и порт 0 или не указан, исправляем на порт 80
      Uri finalUri = uri;
      if (uri.scheme == 'wss' && (uri.port == 0 || !uri.hasPort)) {
        finalUri = uri.replace(port: 443);
      } else if (uri.scheme == 'ws' && (uri.port == 0 || !uri.hasPort)) {
        finalUri = uri.replace(port: 80);
      }

      _channel = WebSocketChannel.connect(finalUri);

      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
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
        if (_isConnected && _channel != null) {
          _channel!.sink.add('ping');
        }
      });
    } catch (e) {
      _isConnecting = false;
      onError?.call(e);
    }
  }

  /// Обработка входящих сообщений
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString()) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'connection':
          _handleConnectionMessage(data);
          break;
        case 'notification':
          _handleNotificationMessage(data);
          break;
        case 'pong':
          break;
        default:
          break;
      }
    } catch (e) {
      // Игнорируем ошибки парсинга
    }
  }

  /// Обработка сообщения о подключении
  void _handleConnectionMessage(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    if (status == 'connected') {
      _isConnected = true;
      _isConnecting = false;
      onConnected?.call();
    }
  }

  /// Обработка уведомления
  void _handleNotificationMessage(Map<String, dynamic> data) {
    try {
      final notificationData = data['notification'] as Map<String, dynamic>?;
      if (notificationData != null) {
        final notification = Notification.fromJson(notificationData);
        onNotificationReceived?.call(notification);
      }
    } catch (e) {
      // Игнорируем ошибки обработки уведомлений
    }
  }

  /// Отключиться от WebSocket
  void disconnect() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _isConnecting = false;
  }

  /// Проверка статуса подключения
  bool get isConnected => _isConnected;

  /// Переподключение
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await connect();
  }
}
