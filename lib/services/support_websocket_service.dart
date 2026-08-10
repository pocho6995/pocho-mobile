import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/support/support_message.dart';
import 'token_storage.dart';
import 'api_client.dart';

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

      // Получаем базовый URL для WebSocket
      // Используем ту же логику, что и ApiClient для консистентности
      String baseUrl;
      final wsBaseUrl = dotenv.env['WS_BASE_URL']?.trim();

      if (wsBaseUrl != null && wsBaseUrl.isNotEmpty) {
        // Если в .env указан IP адрес сети (192.168.x.x, 10.0.2.2 и т.д.), используем его для всех платформ
        if (wsBaseUrl.contains('192.168.') ||
            wsBaseUrl.contains('10.0.2.2') ||
            (wsBaseUrl.contains('10.') && !wsBaseUrl.contains('127.0.0.1'))) {
          baseUrl = wsBaseUrl;
        } else if (Platform.isAndroid &&
            (wsBaseUrl.contains('127.0.0.1') ||
                wsBaseUrl.contains('localhost'))) {
          // Если в .env указан localhost или 127.0.0.1, автоматически заменяем для Android эмулятора
          baseUrl = wsBaseUrl
              .replaceAll('127.0.0.1', '10.0.2.2')
              .replaceAll('localhost', '10.0.2.2');
        } else {
          // Для продакшн URL (wss://olmatech.uz) используем как есть
          baseUrl = wsBaseUrl;
        }
      } else {
        // Если WS_BASE_URL не указан, используем базовый URL из ApiClient (он уже скорректирован)
        final apiBaseUrl = ApiClient.baseUrl;
        // Преобразуем протокол: https:// -> wss://, http:// -> ws://
        if (apiBaseUrl.startsWith('https://')) {
          baseUrl = apiBaseUrl.replaceFirst('https://', 'wss://');
        } else if (apiBaseUrl.startsWith('http://')) {
          baseUrl = apiBaseUrl.replaceFirst('http://', 'ws://');
        } else {
          // Если протокол уже указан (wss:// или ws://), используем как есть
          baseUrl = apiBaseUrl;
        }
      }

      // Убираем trailing slash если есть
      baseUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;

      final wsUrl =
          '$baseUrl/api/v1/support/ws/ticket/$ticketId?token=${Uri.encodeComponent(token)}';

      if (kDebugMode) {
        print('🔍 Support WebSocket URL Debug:');
        print('   WS_BASE_URL from .env: $wsBaseUrl');
        print('   Final baseUrl: $baseUrl');
        print('   Final wsUrl: $wsUrl');
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
        print('🔌 Support WebSocket: Подключение...');
        print('📍 Final URI: $finalUri');
        print('🎫 Ticket ID: $ticketId');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
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
