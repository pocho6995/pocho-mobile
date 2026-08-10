import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/global_chat/global_chat_message.dart';
import '../models/global_chat/global_chat_message_list_response.dart';
import '../models/global_chat/user_block.dart';
import '../models/global_chat/blocked_users_response.dart';
import '../models/global_chat/upload_response.dart';
import '../models/global_chat/attachment.dart';
import 'api_client.dart';
import '../exceptions/auth_exceptions.dart';

/// Сервис для работы с глобальным чатом
class GlobalChatService {
  final ApiClient apiClient;

  GlobalChatService({required this.apiClient});

  /// Отправить сообщение
  Future<GlobalChatMessage> sendMessage({
    required String message,
    required MessageType messageType,
    List<Attachment>? attachments,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (kDebugMode) {
        print('💬 GlobalChatService: Отправка сообщения');
        print('   Type: ${messageType.value}');
      }

      final body = <String, dynamic>{
        'message': message,
        'message_type': messageType.value,
      };
      if (attachments != null) {
        body['attachments'] = attachments.map((a) => a.toJson()).toList();
      }
      if (metadata != null) {
        body['metadata'] = metadata;
      }

      final response = await apiClient.post(
        '/api/v1/global-chat/messages',
        body: body,
      );

      if (kDebugMode) {
        print('✅ GlobalChatService: Сообщение отправлено');
        print('   Status Code: ${response.statusCode}');
      }

      return _handleResponse<GlobalChatMessage>(
        response,
        (json) => GlobalChatMessage.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatService: Ошибка при отправке сообщения');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Загрузить файл
  Future<UploadResponse> uploadFile({
    required File file,
    required String fileType,
  }) async {
    try {
      if (kDebugMode) {
        print('📤 GlobalChatService: Загрузка файла');
        print('   File: ${file.path}');
        print('   Type: $fileType');
      }

      // Проверяем размер файла (максимум 50 MB)
      final fileSize = await file.length();
      if (fileSize > 50 * 1024 * 1024) {
        throw ValidationException('Размер файла превышает 50 MB');
      }

      final uri = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/global-chat/messages/upload?file_type=$fileType',
      );

      final token = await apiClient.tokenStorage?.getAccessToken();
      if (token == null) {
        throw UnauthorizedException('Токен не найден');
      }

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Определяем MediaType
      MediaType? mediaType;
      final extension = file.path.split('.').last.toLowerCase();
      if (fileType == 'image') {
        if (['jpg', 'jpeg'].contains(extension)) {
          mediaType = MediaType('image', 'jpeg');
        } else if (extension == 'png') {
          mediaType = MediaType('image', 'png');
        } else if (extension == 'webp') {
          mediaType = MediaType('image', 'webp');
        } else if (extension == 'gif') {
          mediaType = MediaType('image', 'gif');
        }
      } else if (fileType == 'video') {
        if (extension == 'mp4') {
          mediaType = MediaType('video', 'mp4');
        } else if (extension == 'webm') {
          mediaType = MediaType('video', 'webm');
        }
      } else if (fileType == 'audio') {
        if (extension == 'mp3') {
          mediaType = MediaType('audio', 'mpeg');
        } else if (extension == 'wav') {
          mediaType = MediaType('audio', 'wav');
        }
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: file.path.split('/').last,
          contentType: mediaType,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        print('✅ GlobalChatService: Файл загружен');
        print('   Status Code: ${response.statusCode}');
        print('   Response Body: ${response.body}');
      }

      return _handleResponse<UploadResponse>(
        response,
        (json) => UploadResponse.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatService: Ошибка при загрузке файла');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Получить сообщения
  Future<GlobalChatMessageListResponse> getMessages({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      if (kDebugMode) {
        print('📋 GlobalChatService: Получение сообщений');
        print('   Skip: $skip, Limit: $limit');
      }

      final endpoint = '/api/v1/global-chat/messages?skip=$skip&limit=$limit';
      final response = await apiClient.get(endpoint);

      if (kDebugMode) {
        print('✅ GlobalChatService: Сообщения получены');
        print('   Status Code: ${response.statusCode}');
      }

      return _handleResponse<GlobalChatMessageListResponse>(
        response,
        (json) => GlobalChatMessageListResponse.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatService: Ошибка при получении сообщений');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Поиск сообщений
  Future<GlobalChatMessageListResponse> searchMessages({
    required String query,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      if (kDebugMode) {
        print('🔍 GlobalChatService: Поиск сообщений');
        print('   Query: $query');
      }

      final endpoint =
          '/api/v1/global-chat/messages/search?query=${Uri.encodeComponent(query)}&skip=$skip&limit=$limit';
      final response = await apiClient.get(endpoint);

      if (kDebugMode) {
        print('✅ GlobalChatService: Поиск выполнен');
        print('   Status Code: ${response.statusCode}');
      }

      return _handleResponse<GlobalChatMessageListResponse>(
        response,
        (json) => GlobalChatMessageListResponse.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatService: Ошибка при поиске');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Получить количество онлайн
  Future<int> getOnlineCount() async {
    try {
      final response = await apiClient.get('/api/v1/global-chat/online');

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return (json['online_count'] as num).toInt();
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatService: Ошибка при получении онлайн');
        print('   Error: $e');
      }
      return 0;
    }
  }

  /// Заблокировать пользователя
  Future<UserBlock> blockUser(int blockedUserId) async {
    try {
      if (kDebugMode) {
        print('🚫 GlobalChatService: Блокировка пользователя $blockedUserId');
      }

      final body = {'blocked_user_id': blockedUserId};
      final response = await apiClient.post(
        '/api/v1/global-chat/block',
        body: body,
      );

      if (kDebugMode) {
        print('✅ GlobalChatService: Пользователь заблокирован');
      }

      return _handleResponse<UserBlock>(
        response,
        (json) => UserBlock.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatService: Ошибка при блокировке');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Разблокировать пользователя
  Future<void> unblockUser(int blockedUserId) async {
    try {
      if (kDebugMode) {
        print('✅ GlobalChatService: Разблокировка пользователя $blockedUserId');
      }

      final response = await apiClient.delete(
        '/api/v1/global-chat/block/$blockedUserId',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError(response);
      }

      if (kDebugMode) {
        print('✅ GlobalChatService: Пользователь разблокирован');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatService: Ошибка при разблокировке');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Получить список заблокированных пользователей
  Future<BlockedUsersResponse> getBlockedUsers() async {
    try {
      final response = await apiClient.get('/api/v1/global-chat/blocked');

      return _handleResponse<BlockedUsersResponse>(
        response,
        (json) => BlockedUsersResponse.fromJson(json),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatService: Ошибка при получении заблокированных');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Очистить историю чата (персонально)
  Future<int> clearHistory() async {
    try {
      if (kDebugMode) {
        print('🗑️ GlobalChatService: Очистка истории');
      }

      final response = await apiClient.delete(
        '/api/v1/global-chat/messages/history',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError(response);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return (json['count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatService: Ошибка при очистке истории');
        print('   Error: $e');
      }
      rethrow;
    }
  }

  /// Удалить сообщение (для всех)
  Future<void> deleteMessage(int messageId) async {
    try {
      if (kDebugMode) {
        print('🗑️ GlobalChatService: Удаление сообщения $messageId');
      }

      final response = await apiClient.delete(
        '/api/v1/global-chat/messages/$messageId',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError(response);
      }

      if (kDebugMode) {
        print('✅ GlobalChatService: Сообщение удалено');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ GlobalChatService: Ошибка при удалении сообщения');
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
        if (response.body.isEmpty) {
          throw Exception('Response body is empty');
        }

        final decoded = jsonDecode(response.body);
        if (decoded == null) {
          throw Exception('Decoded JSON is null');
        }

        if (decoded is! Map<String, dynamic>) {
          throw Exception(
            'Expected Map<String, dynamic>, got ${decoded.runtimeType}',
          );
        }

        final json = decoded as Map<String, dynamic>;
        return fromJson(json);
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ GlobalChatService: JSON Parse Error: $e');
          print('   Error Type: ${e.runtimeType}');
          print('📥 Response Status: ${response.statusCode}');
          print('📥 Response Body: ${response.body}');
          print('📥 Response Body Length: ${response.body.length}');
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
        return const NotFoundException('Не найдено');
      case 500:
      case 502:
      case 503:
        return const ServerException('Ошибка сервера');
      default:
        try {
          final json = jsonDecode(body) as Map<String, dynamic>;
          final message =
              json['detail'] as String? ??
              json['message'] as String? ??
              'Неизвестная ошибка';
          return UnknownException(message);
        } catch (e) {
          return UnknownException('Ошибка: $statusCode');
        }
    }
  }
}
