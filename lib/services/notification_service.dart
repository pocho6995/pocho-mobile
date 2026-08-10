import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/notification/notification_list_response.dart';
import '../models/notification/notification_stats.dart';
import 'api_client.dart';
import '../exceptions/auth_exceptions.dart';

/// REST API сервис для работы с уведомлениями
class NotificationService {
  final ApiClient apiClient;

  NotificationService({required this.apiClient});

  /// Получить список уведомлений
  Future<NotificationListResponse> getNotifications({
    int skip = 0,
    int limit = 100,
    bool? unreadOnly,
  }) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };

    if (unreadOnly != null) {
      queryParams['unread_only'] = unreadOnly.toString();
    }

    final queryString = queryParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final endpoint = '/api/v1/notifications?$queryString';

    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔵 NOTIFICATIONS REQUEST');
      print('📍 URL: ${ApiClient.baseUrl}$endpoint');
      print('📤 Endpoint: $endpoint');
      print('📤 Query: $queryString');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    try {
      final response = await apiClient.get(endpoint);

      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ NOTIFICATIONS RESPONSE');
        print('📥 Status Code: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      return _handleResponse<NotificationListResponse>(
        response,
        (json) => NotificationListResponse.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ NOTIFICATIONS ERROR');
        print('💥 Error: $e');
        print('💥 Error Type: ${e.runtimeType}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      throw _handleError(e);
    }
  }

  /// Получить статистику уведомлений
  Future<NotificationStats> getStats() async {
    const endpoint = '/api/v1/notifications/stats';

    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔵 NOTIFICATIONS STATS REQUEST');
      print('📍 URL: ${ApiClient.baseUrl}$endpoint');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    try {
      final response = await apiClient.get(endpoint);

      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ NOTIFICATIONS STATS RESPONSE');
        print('📥 Status Code: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      return _handleResponse<NotificationStats>(
        response,
        (json) => NotificationStats.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ NOTIFICATIONS STATS ERROR');
        print('💥 Error: $e');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      throw _handleError(e);
    }
  }

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(int notificationId) async {
    final endpoint = '/api/v1/notifications/$notificationId/read';

    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔵 MARK AS READ REQUEST');
      print('📍 URL: ${ApiClient.baseUrl}$endpoint');
      print('📤 Notification ID: $notificationId');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    try {
      final response = await apiClient.patch(endpoint, body: null);

      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ MARK AS READ RESPONSE');
        print('📥 Status Code: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError(response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ MARK AS READ ERROR');
        print('💥 Error: $e');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      throw _handleError(e);
    }
  }

  /// Отметить все уведомления как прочитанные
  Future<void> markAllAsRead() async {
    const endpoint = '/api/v1/notifications/read-all';

    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔵 MARK ALL AS READ REQUEST');
      print('📍 URL: ${ApiClient.baseUrl}$endpoint');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    try {
      final response = await apiClient.post(endpoint, body: null);

      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ MARK ALL AS READ RESPONSE');
        print('📥 Status Code: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError(response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ MARK ALL AS READ ERROR');
        print('💥 Error: $e');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      throw _handleError(e);
    }
  }

  /// Удалить уведомление
  Future<void> deleteNotification(int notificationId) async {
    final endpoint = '/api/v1/notifications/$notificationId';

    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔵 DELETE NOTIFICATION REQUEST');
      print('📍 URL: ${ApiClient.baseUrl}$endpoint');
      print('📤 Notification ID: $notificationId');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }

    try {
      final response = await apiClient.delete(endpoint);

      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('✅ DELETE NOTIFICATION RESPONSE');
        print('📥 Status Code: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError(response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ DELETE NOTIFICATION ERROR');
        print('💥 Error: $e');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      throw _handleError(e);
    }
  }

  T _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return fromJson(json);
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('⚠️ JSON Parse Error: $e');
          print('📥 Response Body: ${response.body}');
          print('📥 StackTrace: $stackTrace');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }
        throw UnknownException('Ошибка парсинга ответа сервера: $e');
      }
    } else {
      throw _mapHttpError(response);
    }
  }

  AuthException _handleError(dynamic error) {
    if (error is AuthException) {
      return error;
    }

    // Обработка сетевых ошибок
    if (error.toString().contains('SocketException') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Failed host lookup')) {
      return const NetworkException('Нет соединения с интернетом');
    }

    if (error.toString().contains('HttpException') ||
        error.toString().contains('FormatException')) {
      return const NetworkException('Ошибка сети');
    }

    return UnknownException('Неизвестная ошибка: ${error.toString()}');
  }

  AuthException _mapHttpError(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    switch (statusCode) {
      case 400:
        return const ValidationException('Неверный запрос');
      case 401:
        return const UnauthorizedException('Не авторизован');
      case 404:
        return const NotFoundException('Уведомление не найдено');
      case 500:
      case 502:
      case 503:
        return const ServerException('Ошибка сервера');
      default:
        try {
          final json = jsonDecode(body) as Map<String, dynamic>;
          final message = json['detail'] as String? ??
              json['message'] as String? ??
              'Неизвестная ошибка';
          return UnknownException(message);
        } catch (e) {
          return UnknownException('Ошибка: $statusCode');
        }
    }
  }
}

