import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../models/notification/notification.dart';
import '../utils/websocket_uri.dart';
import 'token_storage.dart';

/// WebSocket уведомлений. Если сервер не поднимает WS — сразу сдаёмся,
/// без бесконечных реконнектов (они подвешивали UI).
class NotificationWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final TokenStorage _tokenStorage;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _permanentFailure = false;
  int _reconnectAttempt = 0;

  Function(Notification)? onNotificationReceived;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(dynamic)? onError;

  NotificationWebSocketService({required TokenStorage tokenStorage})
    : _tokenStorage = tokenStorage;

  bool get isConnected => _isConnected;
  bool get hasPermanentFailure => _permanentFailure;

  Future<void> connect() async {
    if (_permanentFailure || _isConnecting || _isConnected) return;

    try {
      _isConnecting = true;

      final token = await _tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        _isConnecting = false;
        return;
      }

      final finalUri = WebSocketUriBuilder.build(
        baseUrl: AppConfig.wsBaseUrl,
        path: '/api/v1/notifications/ws/notifications',
        queryParameters: {'token': token},
      );

      _channel = WebSocketChannel.connect(finalUri);

      // Сразу слушаем stream, иначе ошибка upgrade уходит в Unhandled Exception
      final ready = Completer<void>();
      _subscription = _channel!.stream.listen(
        (message) {
          if (!_isConnected) {
            _isConnected = true;
            _isConnecting = false;
            onConnected?.call();
          }
          _handleMessage(message);
        },
        onError: (error, stack) {
          if (!ready.isCompleted) {
            ready.completeError(error, stack);
          } else {
            _onStreamError(error);
          }
        },
        onDone: () {
          if (!ready.isCompleted) {
            ready.completeError(
              StateError('WebSocket closed before ready'),
            );
          } else {
            _onStreamDone();
          }
        },
        cancelOnError: false,
      );

      try {
        await Future.any([
          _channel!.ready,
          ready.future,
        ]).timeout(const Duration(seconds: 10));
      } catch (e) {
        await _cleanupChannel();
        _isConnecting = false;
        _handleFailure(e);
        return;
      }

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_isConnected && _channel != null) {
          try {
            _channel!.sink.add('ping');
          } catch (_) {}
        }
      });

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempt = 0;
      onConnected?.call();
    } catch (e) {
      _isConnecting = false;
      await _cleanupChannel();
      _handleFailure(e);
    }
  }

  void _onStreamError(dynamic error) {
    if (kDebugMode) {
      print('⚠️ Notification WebSocket error (suppressed spam): $error');
    }
    _isConnected = false;
    _isConnecting = false;
    onError?.call(error);
    _handleFailure(error);
  }

  void _onStreamDone() {
    _isConnected = false;
    _isConnecting = false;
    onDisconnected?.call();
    if (!_permanentFailure) {
      _scheduleReconnect();
    }
  }

  void _handleFailure(Object error) {
    onError?.call(error);
    if (WebSocketUriBuilder.isPermanentFailure(error) ||
        _reconnectAttempt >= 3) {
      _permanentFailure = true;
      _pingTimer?.cancel();
      if (kDebugMode) {
        print(
          '⚠️ Notification WebSocket недоступен — realtime отключён',
        );
      }
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_permanentFailure || _isConnected || _isConnecting) return;
    _reconnectAttempt++;
    Future.delayed(Duration(seconds: 5 * _reconnectAttempt), () {
      if (!_isConnected && !_permanentFailure) {
        connect();
      }
    });
  }

  void _handleMessage(dynamic message) {
    try {
      if (message == 'pong') return;
      final data = jsonDecode(message.toString()) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'connection':
          _isConnected = true;
          onConnected?.call();
          break;
        case 'notification':
          final notificationData =
              data['notification'] as Map<String, dynamic>?;
          if (notificationData != null) {
            onNotificationReceived?.call(
              Notification.fromJson(notificationData),
            );
          }
          break;
        default:
          break;
      }
    } catch (_) {}
  }

  Future<void> _cleanupChannel() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    await _cleanupChannel();
    _isConnected = false;
    _isConnecting = false;
  }

  Future<void> reconnect() async {
    if (_permanentFailure) return;
    await disconnect();
    await connect();
  }
}
