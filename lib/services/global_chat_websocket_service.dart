import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../models/global_chat/global_chat_message.dart';
import '../utils/websocket_uri.dart';
import 'token_storage.dart';

/// WebSocket сервис для глобального чата в реальном времени.
/// Если сервер не отдаёт WS (404 / not upgraded) — не крутим бесконечный reconnect.
class GlobalChatWebSocketService {
  WebSocketChannel? _channel;
  final TokenStorage _tokenStorage;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _permanentFailure = false;
  int _reconnectAttempt = 0;

  Function(GlobalChatMessage)? onMessageReceived;
  Function(int)? onOnlineCountUpdated;
  Function(int)? onMessageDeleted;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(dynamic)? onError;

  /// Вызывается, когда WS недоступен и нужен HTTP polling.
  Function()? onFallbackToPolling;

  GlobalChatWebSocketService({required TokenStorage tokenStorage})
    : _tokenStorage = tokenStorage;

  bool get isConnected => _isConnected;
  bool get hasPermanentFailure => _permanentFailure;

  Future<void> connect() async {
    if (_permanentFailure) {
      onFallbackToPolling?.call();
      return;
    }
    if (_isConnecting || _isConnected) return;

    try {
      _isConnecting = true;

      final token = await _tokenStorage.getAccessToken();
      if (token == null || token.isEmpty) {
        _isConnecting = false;
        return;
      }

      final finalUri = WebSocketUriBuilder.build(
        baseUrl: AppConfig.wsBaseUrl,
        path: '/api/v1/global-chat/ws',
        queryParameters: {'token': token},
      );

      if (kDebugMode) {
        print('🔌 Global Chat WebSocket: $finalUri');
      }

      _channel = WebSocketChannel.connect(finalUri);

      // Ждём готовности канала — иначе ошибка upgrade приходит асинхронно
      await _channel!.ready.timeout(const Duration(seconds: 12));

      _channel!.stream.listen(
        _handleMessage,
        onError: _onSocketError,
        onDone: _onSocketDone,
        cancelOnError: false,
      );

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _sendPing();
      });

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempt = 0;
      _permanentFailure = false;
      onConnected?.call();
    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      _handleConnectFailure(e);
    }
  }

  void _onSocketError(dynamic error) {
    if (kDebugMode) {
      print('❌ Global Chat WebSocket Error: $error');
    }
    _isConnected = false;
    _isConnecting = false;
    onError?.call(error);
    _handleConnectFailure(error);
  }

  void _onSocketDone() {
    _isConnected = false;
    _isConnecting = false;
    onDisconnected?.call();
    if (!_permanentFailure) {
      _scheduleReconnect();
    }
  }

  void _handleConnectFailure(Object error) {
    onError?.call(error);

    if (WebSocketUriBuilder.isPermanentFailure(error)) {
      _permanentFailure = true;
      _pingTimer?.cancel();
      if (kDebugMode) {
        print(
          '⚠️ Global Chat WebSocket недоступен на сервере — переключаемся на polling',
        );
      }
      onFallbackToPolling?.call();
      return;
    }

    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_permanentFailure || _isConnected || _isConnecting) return;
    _reconnectAttempt++;
    if (_reconnectAttempt > 5) {
      _permanentFailure = true;
      onFallbackToPolling?.call();
      return;
    }
    final delay = Duration(seconds: 3 * _reconnectAttempt);
    Future.delayed(delay, () {
      if (!_isConnected && !_permanentFailure) {
        connect();
      }
    });
  }

  void _handleMessage(dynamic message) {
    try {
      if (message == 'pong') return;

      final data = jsonDecode(message.toString());
      final type = data['type'];

      if (type == 'connection' || type == 'online_count') {
        onOnlineCountUpdated?.call(data['online_count'] as int? ?? 0);
        return;
      }

      if (type == 'new_message') {
        final messageData = data['message'] as Map<String, dynamic>;
        onMessageReceived?.call(GlobalChatMessage.fromJson(messageData));
      } else if (type == 'message_deleted') {
        final messageId = data['message_id'] as int?;
        if (messageId != null) onMessageDeleted?.call(messageId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Global Chat WebSocket parse error: $e');
      }
    }
  }

  void _sendPing() {
    if (_channel != null && _isConnected) {
      try {
        _channel!.sink.add('ping');
      } catch (_) {}
    }
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _isConnected = false;
    _isConnecting = false;
    onDisconnected?.call();
  }

  /// Сброс флага, чтобы снова попробовать WS (например после смены сервера).
  void resetPermanentFailure() {
    _permanentFailure = false;
    _reconnectAttempt = 0;
  }
}
