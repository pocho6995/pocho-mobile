import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../utils/websocket_uri.dart';
import 'token_storage.dart';

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

      final finalUri = WebSocketUriBuilder.build(
        baseUrl: AppConfig.wsBaseUrl,
        path: '/api/v1/ws',
        queryParameters: {'token': token},
      );

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
