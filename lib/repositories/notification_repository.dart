import '../models/notification/notification.dart';
import '../models/notification/notification_list_response.dart';
import '../models/notification/notification_stats.dart';
import '../services/notification_service.dart';
import '../services/notification_websocket_service.dart';
import '../exceptions/auth_exceptions.dart';

/// Репозиторий для работы с уведомлениями
class NotificationRepository {
  final NotificationService _notificationService;
  final NotificationWebSocketService _webSocketService;

  NotificationRepository({
    required NotificationService notificationService,
    required NotificationWebSocketService webSocketService,
  })  : _notificationService = notificationService,
        _webSocketService = webSocketService;

  /// Получить список уведомлений
  Future<NotificationListResponse> getNotifications({
    int skip = 0,
    int limit = 100,
    bool? unreadOnly,
  }) async {
    try {
      return await _notificationService.getNotifications(
        skip: skip,
        limit: limit,
        unreadOnly: unreadOnly,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw UnknownException('Ошибка получения уведомлений: ${e.toString()}');
    }
  }

  /// Получить статистику уведомлений
  Future<NotificationStats> getStats() async {
    try {
      return await _notificationService.getStats();
    } on AuthException {
      rethrow;
    } catch (e) {
      throw UnknownException('Ошибка получения статистики: ${e.toString()}');
    }
  }

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(int notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw UnknownException('Ошибка отметки уведомления: ${e.toString()}');
    }
  }

  /// Отметить все уведомления как прочитанные
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
    } on AuthException {
      rethrow;
    } catch (e) {
      throw UnknownException('Ошибка отметки всех уведомлений: ${e.toString()}');
    }
  }

  /// Удалить уведомление
  Future<void> deleteNotification(int notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw UnknownException('Ошибка удаления уведомления: ${e.toString()}');
    }
  }

  /// Подключиться к WebSocket
  Future<void> connectWebSocket() async {
    await _webSocketService.connect();
  }

  /// Отключиться от WebSocket
  Future<void> disconnectWebSocket() async {
    await _webSocketService.disconnect();
  }

  /// Переподключиться к WebSocket
  Future<void> reconnectWebSocket() async {
    await _webSocketService.reconnect();
  }

  /// Проверить статус подключения WebSocket
  bool get isWebSocketConnected => _webSocketService.isConnected;

  /// Установить callback для получения уведомлений через WebSocket
  void setOnNotificationReceived(Function(Notification) callback) {
    _webSocketService.onNotificationReceived = callback;
  }

  /// Установить callback для подключения WebSocket
  void setOnWebSocketConnected(Function() callback) {
    _webSocketService.onConnected = callback;
  }

  /// Установить callback для отключения WebSocket
  void setOnWebSocketDisconnected(Function() callback) {
    _webSocketService.onDisconnected = callback;
  }

  /// Установить callback для ошибок WebSocket
  void setOnWebSocketError(Function(dynamic) callback) {
    _webSocketService.onError = callback;
  }
}












