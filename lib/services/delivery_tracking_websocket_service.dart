import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'token_storage.dart';
import 'api_client.dart';

/// Модель локации водителя
class DriverLocation {
  final int orderId;
  final int driverId;
  final double lat;
  final double lng;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final DateTime timestamp;

  DriverLocation({
    required this.orderId,
    required this.driverId,
    required this.lat,
    required this.lng,
    this.speed,
    this.heading,
    this.accuracy,
    required this.timestamp,
  });

  factory DriverLocation.fromJson(Map<String, dynamic> json) {
    return DriverLocation(
      orderId: json['order_id'] as int,
      driverId: json['driver_id'] as int,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading: json['heading'] != null
          ? (json['heading'] as num).toDouble()
          : null,
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] as num).toDouble()
          : null,
      timestamp: DateTime.parse(json['ts'] as String),
    );
  }
}

/// WebSocket сервис для трекинга доставки в реальном времени
class DeliveryTrackingWebSocketService {
  WebSocketChannel? _channel;
  final TokenStorage _tokenStorage;
  Timer? _pingTimer;
  bool _isConnected = false;
  bool _isConnecting = false;
  int? _subscribedOrderId;

  // Callbacks
  Function(DriverLocation)? onDriverLocationUpdated;
  Function(int, String)? onOrderStatusUpdated; // orderId, newStatus
  Function()? onConnected;
  Function()? onDisconnected;
  Function(dynamic)? onError;

  DeliveryTrackingWebSocketService({required TokenStorage tokenStorage})
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
        // Используем базовый URL из ApiClient (он уже скорректирован для платформы)
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

      final wsUrl = '$baseUrl/api/v1/ws?token=${Uri.encodeComponent(token)}';

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
          _subscribedOrderId = null;
          onDisconnected?.call();
        },
        cancelOnError: false,
      );

      _isConnected = true;
      _isConnecting = false;
      onConnected?.call();

      // Запускаем ping каждые 30 секунд
      _startPingTimer();
    } catch (e) {
      _isConnected = false;
      _isConnecting = false;
      onError?.call(e);
    }
  }

  /// Подписаться на заказ (для клиента)
  void subscribeToOrder(int orderId) {
    if (!_isConnected || _channel == null) {
      return;
    }

    _subscribedOrderId = orderId;
    final message = jsonEncode({
      'type': 'subscribe_order',
      'order_id': orderId,
    });

    try {
      _channel!.sink.add(message);
    } catch (e) {
      // Игнорируем ошибки подписки
    }
  }

  /// Отправить локацию водителя (для водителя)
  void sendDriverLocation({
    required double lat,
    required double lng,
    double? speed,
    double? heading,
    double? accuracy,
  }) {
    if (!_isConnected || _channel == null) {
      return;
    }

    final message = jsonEncode({
      'type': 'driver_location',
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'heading': heading,
      'accuracy': accuracy,
      'ts': DateTime.now().toUtc().toIso8601String(),
    });

    try {
      _channel!.sink.add(message);
    } catch (e) {
      // Игнорируем ошибки отправки локации
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final type = data['type'] as String?;

      switch (type) {
        case 'subscribed':
          break;

        case 'location_sent':
          break;

        case 'order_update':
          final orderId = data['order_id'] as int;
          final status = data['status'] as String;
          onOrderStatusUpdated?.call(orderId, status);
          break;

        case 'driver_location':
          try {
            final location = DriverLocation.fromJson(data);
            onDriverLocationUpdated?.call(location);
          } catch (e) {
            // Игнорируем ошибки парсинга локации
          }
          break;

        case 'pong':
          break;

        default:
          break;
      }
    } catch (e) {
      // Игнорируем ошибки обработки сообщений
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          // Игнорируем ошибки отправки ping
        }
      }
    });
  }

  /// Отключиться от WebSocket
  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscribedOrderId = null;

    try {
      await _channel?.sink.close();
      _channel = null;
      _isConnected = false;
      _isConnecting = false;
      onDisconnected?.call();
    } catch (e) {
      // Игнорируем ошибки отключения
    }
  }

  bool get isConnected => _isConnected;
  int? get subscribedOrderId => _subscribedOrderId;
}
