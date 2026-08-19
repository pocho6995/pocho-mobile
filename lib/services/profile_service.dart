import 'dart:convert';
import 'dart:io';

import '../models/profile/user_profile_response.dart';
import 'api_client.dart';
import '../exceptions/auth_exceptions.dart';
import 'package:http/http.dart' as http;

class ProfileService {
  final ApiClient apiClient;

  ProfileService({required this.apiClient});

  /// Получение профиля пользователя
  Future<UserProfileResponse> getProfile() async {
    const endpoint = '/api/v1/profile';

    try {
      final response = await apiClient.get(endpoint);

      return _handleResponse<UserProfileResponse>(
        response,
        (json) => UserProfileResponse.fromJson(json),
      );
    } catch (e) {
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
      } catch (e) {
        throw UnknownException('Ошибка парсинга ответа сервера: $e');
      }
    } else {
      throw _mapHttpError(response);
    }
  }

  /// Обновление имени пользователя
  Future<void> updateName(String name) async {
    const endpoint = '/api/v1/profile/name';

    try {
      final response = await apiClient.patch(
        endpoint,
        body: jsonEncode({'name': name}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError(response);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Обновление email пользователя
  Future<void> updateEmail(String email) async {
    const endpoint = '/api/v1/profile/email';

    try {
      final response = await apiClient.patch(
        endpoint,
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError(response);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Обновление настроек уведомлений
  Future<void> updateNotifications(bool enabled) async {
    const endpoint = '/api/v1/profile/notifications';

    try {
      final response = await apiClient.patch(
        endpoint,
        body: jsonEncode({'notifications_enabled': enabled}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError(response);
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Загрузка фото паспорта
  Future<void> uploadPassport(File imageFile) async {
    const endpoint = '/api/v1/profile/passport';

    try {
      // Проверяем размер файла (5 MB = 5 * 1024 * 1024 bytes)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw const ValidationException('Размер файла превышает 5 MB');
      }

      final response = await apiClient.patchMultipart(endpoint, imageFile);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError(response);
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw _handleError(e);
    }
  }

  /// Загрузка фото водительских прав
  Future<void> uploadDrivingLicense(File imageFile) async {
    const endpoint = '/api/v1/profile/driving-license';

    try {
      // Проверяем размер файла (5 MB = 5 * 1024 * 1024 bytes)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw const ValidationException('Размер файла превышает 5 MB');
      }

      final response = await apiClient.patchMultipart(endpoint, imageFile);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError(response);
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw _handleError(e);
    }
  }

  /// Загрузка аватара пользователя
  Future<void> uploadAvatar(File imageFile) async {
    const endpoint = '/api/v1/profile/avatar';

    try {
      // Проверяем размер файла (5 MB = 5 * 1024 * 1024 bytes)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw const ValidationException('Размер файла превышает 5 MB');
      }

      final response = await apiClient.patchMultipart(endpoint, imageFile);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _mapHttpError(response);
      }
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw _handleError(e);
    }
  }

  /// Удаление аккаунта пользователя
  Future<void> deleteAccount() async {
    const endpoints = [
      '/api/v1/profile',
      '/api/v1/users/me',
      '/api/v1/auth/account',
    ];

    try {
      http.Response? lastResponse;
      for (final endpoint in endpoints) {
        final response = await apiClient.delete(endpoint);
        lastResponse = response;
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return;
        }
        if (response.statusCode == 404 || response.statusCode == 405) {
          continue;
        }
        throw _mapHttpError(response);
      }
      throw lastResponse == null
          ? const UnknownException('Не удалось удалить аккаунт')
          : _mapHttpError(lastResponse);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw _handleError(e);
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

  AuthException _mapHttpError(response) {
    final statusCode = response.statusCode;
    final body = response.body;

    switch (statusCode) {
      case 400:
        return const ValidationException('Неверный запрос');
      case 401:
        return const UnauthorizedException('Не авторизован');
      case 404:
        return const NotFoundException('Профиль не найден');
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
