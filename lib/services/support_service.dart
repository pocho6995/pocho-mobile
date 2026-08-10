import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/support/support_ticket.dart';
import '../models/support/support_message.dart';
import '../models/support/support_ticket_list_response.dart';
import 'api_client.dart';
import '../exceptions/auth_exceptions.dart';

/// Сервис для работы с тикетами поддержки
class SupportService {
  final ApiClient apiClient;

  SupportService({required this.apiClient});

  /// Создать новый тикет
  Future<SupportTicket> createTicket({
    required String subject,
    required String message,
  }) async {
    try {
      if (kDebugMode) {
        print('📝 SupportService: Создание тикета');
        print('   Subject: $subject');
      }

      final body = {
        'subject': subject,
        'message': message,
      };

      final response = await apiClient.post('/api/v1/support', body: body);

      if (kDebugMode) {
        print('✅ SupportService: Тикет создан');
        print('   Status Code: ${response.statusCode}');
        print('   Response Body: ${response.body}');
      }

      return _handleResponse<SupportTicket>(
        response,
        (json) => SupportTicket.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ SupportService: Ошибка при создании тикета');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Получить список тикетов
  Future<SupportTicketListResponse> getTickets({
    int skip = 0,
    int limit = 100,
    String? status,
  }) async {
    try {
      if (kDebugMode) {
        print('📋 SupportService: Получение списка тикетов');
        print('   Skip: $skip, Limit: $limit, Status: $status');
      }

      String endpoint = '/api/v1/support?skip=$skip&limit=$limit';
      if (status != null && status.isNotEmpty) {
        endpoint += '&status=$status';
      }

      final response = await apiClient.get(endpoint);

      if (kDebugMode) {
        print('✅ SupportService: Список тикетов получен');
        print('   Status Code: ${response.statusCode}');
        print('   Response Body: ${response.body}');
      }

      return _handleResponse<SupportTicketListResponse>(
        response,
        (json) => SupportTicketListResponse.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ SupportService: Ошибка при получении списка тикетов');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Получить тикет с сообщениями
  Future<SupportTicket> getTicket(int ticketId) async {
    try {
      if (kDebugMode) {
        print('📄 SupportService: Получение тикета $ticketId');
      }

      final response = await apiClient.get('/api/v1/support/$ticketId');

      if (kDebugMode) {
        print('✅ SupportService: Тикет получен');
        print('   Status Code: ${response.statusCode}');
        print('   Response Body: ${response.body}');
      }

      return _handleResponse<SupportTicket>(
        response,
        (json) => SupportTicket.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ SupportService: Ошибка при получении тикета');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Отправить сообщение в тикет
  Future<SupportMessage> sendMessage({
    required int ticketId,
    required String message,
    List<String>? attachments,
  }) async {
    try {
      if (kDebugMode) {
        print('💬 SupportService: Отправка сообщения в тикет $ticketId');
      }

      final body = <String, dynamic>{
        'message': message,
      };
      if (attachments != null) {
        body['attachments'] = attachments;
      }

      final response = await apiClient.post(
        '/api/v1/support/$ticketId/messages',
        body: body,
      );

      if (kDebugMode) {
        print('✅ SupportService: Сообщение отправлено');
        print('   Status Code: ${response.statusCode}');
        print('   Response Body: ${response.body}');
      }

      return _handleResponse<SupportMessage>(
        response,
        (json) => SupportMessage.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ SupportService: Ошибка при отправке сообщения');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Отметить тикет как прочитанный
  Future<void> markAsRead(int ticketId) async {
    try {
      if (kDebugMode) {
        print('👁️ SupportService: Отметка тикета $ticketId как прочитанного');
      }

      final response = await apiClient.post(
        '/api/v1/support/$ticketId/read',
        body: {},
      );

      if (kDebugMode) {
        print('✅ SupportService: Тикет отмечен как прочитанный');
        print('   Status Code: ${response.statusCode}');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError(response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SupportService: Ошибка при отметке тикета');
        print('   Error: $e');
      }
      rethrow;
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
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ SupportService: JSON Parse Error: $e');
          print('📥 Response Body: ${response.body}');
        }
        throw UnknownException('Ошибка парсинга ответа сервера: $e');
      }
    } else {
      throw _mapHttpError(response);
    }
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
        return const NotFoundException('Тикет не найден');
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

