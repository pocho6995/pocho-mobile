import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../exceptions/auth_exceptions.dart';
import '../models/auth/check_registration_request.dart';
import '../models/auth/check_registration_response.dart';
import '../models/auth/send_code_request.dart';
import '../models/auth/send_code_response.dart';
import '../models/auth/verify_code_request.dart';
import '../models/auth/verify_code_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';
import '../models/auth/logout_response.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient apiClient;

  AuthService({required this.apiClient});

  /// Логирование запроса
  void _logRequest(String endpoint, Map<String, dynamic>? body) {
    if (kDebugMode) {
      final url = '${ApiClient.baseUrl}$endpoint';
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔵 AUTH REQUEST');
      print('📍 URL: $url');
      print('📤 Endpoint: $endpoint');
      print('📤 Request Body: ${body != null ? jsonEncode(body) : 'null'}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  /// Логирование успешного ответа
  void _logSuccessResponse(String endpoint, int statusCode, String body) {
    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ AUTH RESPONSE: $endpoint');
      print('📥 Status Code: $statusCode');
      print('📥 Response Body: $body');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  /// Логирование ошибки
  void _logError(String endpoint, dynamic error) {
    if (kDebugMode) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ AUTH ERROR: $endpoint');
      print('💥 Error: $error');
      print('💥 Error Type: ${error.runtimeType}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  /// Проверка, зарегистрирован ли пользователь
  Future<CheckRegistrationResponse> checkRegistration(
    CheckRegistrationRequest request,
  ) async {
    const endpoint = '/api/v1/auth/check-registration';
    final requestBody = request.toJson();

    _logRequest(endpoint, requestBody);

    try {
      final response = await apiClient.post(endpoint, body: requestBody);

      _logSuccessResponse(endpoint, response.statusCode, response.body);

      return _handleResponse<CheckRegistrationResponse>(
        response,
        (json) => CheckRegistrationResponse.fromJson(json),
      );
    } catch (e) {
      _logError(endpoint, e);
      throw _handleError(e);
    }
  }

  /// Отправка кода подтверждения
  Future<SendCodeResponse> sendCode(SendCodeRequest request) async {
    const endpoint = '/api/v1/auth/send-code';
    final requestBody = request.toJson();
    final phoneNumber = request.phone;

    _logRequest(endpoint, requestBody);

    // Проверка тестового номера
    if (kDebugMode) {
      print('📱 Отправка запроса на отправку кода...');
      print('   URL: ${ApiClient.baseUrl}$endpoint');
      print('   Phone: $phoneNumber');
      
      // Информация о тестовом режиме
      if (phoneNumber == '+998900000000') {
        print('🔑 ТЕСТОВЫЙ РЕЖИМ: Для этого номера используйте код 1234');
        print('   💡 Код всегда будет 1234 для тестового номера');
      }
    }

    try {
      final response = await apiClient.post(endpoint, body: requestBody);

      if (kDebugMode) {
        print('📡 Ответ сервера:');
        print('   Status Code: ${response.statusCode}');
        print('   Body: ${response.body}');
      }

      _logSuccessResponse(endpoint, response.statusCode, response.body);

      final result = _handleResponse<SendCodeResponse>(
        response,
        (json) => SendCodeResponse.fromJson(json),
      );

      if (kDebugMode) {
        print('✅ Код отправлен успешно!');
        print('   Message: ${result.message}');
        print('   Phone: ${result.phoneNumber}');
        print('   Expires in: ${result.expiresIn} seconds');
        
        // Напоминание о тестовом режиме
        if (phoneNumber == '+998900000000') {
          print('🔑 ТЕСТОВЫЙ РЕЖИМ: Используйте код 1234');
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Исключение при отправке запроса:');
        print('   Error: $e');
        print('   Error Type: ${e.runtimeType}');
      }
      _logError(endpoint, e);
      throw _handleError(e);
    }
  }

  /// Верификация кода (для регистрации)
  Future<VerifyCodeResponse> verifyCode(VerifyCodeRequest request) async {
    const endpoint = '/api/v1/auth/verify-code';
    final phoneNumber = request.phone;
    final code = request.code;

    // Проверка входных данных
    if (phoneNumber.isEmpty || phoneNumber.trim().isEmpty) {
      throw ValidationException('Номер телефона не может быть пустым');
    }
    if (code.isEmpty || code.trim().isEmpty) {
      throw ValidationException('Код не может быть пустым');
    }

    final requestBody = request.toJson();

    // Проверка, что requestBody содержит phone_number
    if (kDebugMode) {
      print('🔍 Проверка requestBody перед отправкой:');
      print('   phone_number в body: ${requestBody['phone_number']}');
      print('   phone_number пустой: ${requestBody['phone_number']?.toString().isEmpty ?? true}');
      print('   code в body: ${requestBody['code'] != null ? '***' : 'null'}');
    }

    // Логируем без кода для безопасности
    final logBody = Map<String, dynamic>.from(requestBody);
    logBody['code'] = '***';
    _logRequest(endpoint, logBody);

    if (kDebugMode) {
      print('🔐 Верификация кода...');
      print('   Phone: $phoneNumber');
      print('   Code: ${code.length} digits');
      
      // Напоминание о тестовом режиме
      if (phoneNumber == '+998900000000') {
        print('🔑 ТЕСТОВЫЙ РЕЖИМ: Ожидается код 1234');
      }
    }

    try {
      final response = await apiClient.post(endpoint, body: requestBody);

      if (kDebugMode) {
        print('📡 Ответ сервера:');
        print('   Status Code: ${response.statusCode}');
        print('   Body: ${response.body}');
      }

      _logSuccessResponse(endpoint, response.statusCode, response.body);

      final result = _handleResponse<VerifyCodeResponse>(
        response,
        (json) => VerifyCodeResponse.fromJson(json),
      );

      if (kDebugMode) {
        print('✅ Код подтвержден!');
        final token = result.accessToken;
        print('   Token получен: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Исключение при верификации:');
        print('   Error: $e');
        print('   Error Type: ${e.runtimeType}');
        
        // Подсказка для тестового режима
        if (phoneNumber == '+998900000000' && e.toString().toLowerCase().contains('неверный')) {
          print('💡 ПОДСКАЗКА: Для тестового номера +998900000000 используйте код 1234');
        }
      }
      _logError(endpoint, e);
      throw _handleError(e);
    }
  }

  /// Вход (для зарегистрированных пользователей)
  Future<LoginResponse> login(LoginRequest request) async {
    const endpoint = '/api/v1/auth/login';
    final phoneNumber = request.phone;
    final code = request.code;

    // Проверка входных данных
    if (phoneNumber.isEmpty || phoneNumber.trim().isEmpty) {
      throw ValidationException('Номер телефона не может быть пустым');
    }
    if (code.isEmpty || code.trim().isEmpty) {
      throw ValidationException('Код не может быть пустым');
    }

    final requestBody = request.toJson();

    // Проверка, что requestBody содержит phone_number
    if (kDebugMode) {
      print('🔍 Проверка requestBody перед отправкой:');
      print('   phone_number в body: ${requestBody['phone_number']}');
      print('   phone_number пустой: ${requestBody['phone_number']?.toString().isEmpty ?? true}');
      print('   code в body: ${requestBody['code'] != null ? '***' : 'null'}');
    }

    // Логируем без кода для безопасности
    final logBody = Map<String, dynamic>.from(requestBody);
    logBody['code'] = '***';
    _logRequest(endpoint, logBody);

    if (kDebugMode) {
      print('🔐 Вход в систему...');
      print('   Phone: $phoneNumber');
      print('   Code: ${code.length} digits');
      
      // Напоминание о тестовом режиме
      if (phoneNumber == '+998900000000') {
        print('🔑 ТЕСТОВЫЙ РЕЖИМ: Ожидается код 1234');
      }
    }

    try {
      final response = await apiClient.post(endpoint, body: requestBody);

      if (kDebugMode) {
        print('📡 Ответ сервера:');
        print('   Status Code: ${response.statusCode}');
        print('   Body: ${response.body}');
      }

      _logSuccessResponse(endpoint, response.statusCode, response.body);

      final result = _handleResponse<LoginResponse>(
        response,
        (json) => LoginResponse.fromJson(json),
      );

      if (kDebugMode) {
        print('✅ Вход выполнен успешно!');
        final token = result.accessToken;
        print('   Token получен: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Исключение при входе:');
        print('   Error: $e');
        print('   Error Type: ${e.runtimeType}');
        
        // Подсказка для тестового режима
        if (phoneNumber == '+998900000000' && e.toString().toLowerCase().contains('неверный')) {
          print('💡 ПОДСКАЗКА: Для тестового номера +998900000000 используйте код 1234');
        }
      }
      _logError(endpoint, e);
      throw _handleError(e);
    }
  }

  /// Выход из системы
  Future<LogoutResponse> logout() async {
    const endpoint = '/api/v1/auth/logout';

    _logRequest(endpoint, null);

    try {
      final response = await apiClient.post(endpoint, body: null);

      _logSuccessResponse(endpoint, response.statusCode, response.body);

      return _handleResponse<LogoutResponse>(
        response,
        (json) => LogoutResponse.fromJson(json),
      );
    } catch (e) {
      _logError(endpoint, e);
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
        if (kDebugMode) {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('⚠️ JSON Parse Error: $e');
          print('📥 Response Body: ${response.body}');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        }
        throw const UnknownException('Ошибка парсинга ответа сервера');
      }
    } else {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('⚠️ HTTP Error Response');
        print('📥 Status Code: ${response.statusCode}');
        print('📥 Response Body: ${response.body}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      throw _mapHttpError(response);
    }
  }

  AuthException _handleError(dynamic error) {
    if (error is AuthException) {
      return error;
    }

    // Обработка сетевых ошибок
    if (error is SocketException) {
      return const NetworkException();
    }
    if (error is HttpException) {
      return const NetworkException();
    }
    if (error is FormatException) {
      return const UnknownException('Ошибка формата ответа сервера');
    }

    final errorString = error.toString().toLowerCase();
    if (errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('connection refused') ||
        errorString.contains('connection timed out') ||
        errorString.contains('timeout') ||
        errorString.contains('no address associated with hostname')) {
      return const NetworkException();
    }

    if (kDebugMode) {
      print('Auth Service Error: $error');
      print('Error type: ${error.runtimeType}');
    }
    return UnknownException(error.toString());
  }

  AuthException _mapHttpError(http.Response response) {
    final statusCode = response.statusCode;

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      final message =
          json?['detail'] as String? ??
          json?['message'] as String? ??
          response.body;

      switch (statusCode) {
        case 400:
          final messageStr = message.toString();
          if (messageStr.toLowerCase().contains('code') ||
              messageStr.toLowerCase().contains('неверный')) {
            return InvalidCodeException(messageStr);
          }
          return ValidationException(messageStr);
        case 401:
          return const UnauthorizedException();
        case 404:
          return const NotFoundException();
        case 409:
          return const UserExistsException();
        case 500:
        case 502:
        case 503:
          return const ServerException();
        default:
          return UnknownException(message.toString());
      }
    } catch (e) {
      switch (statusCode) {
        case 400:
          return const ValidationException();
        case 401:
          return const UnauthorizedException();
        case 404:
          return const NotFoundException();
        case 500:
        case 502:
        case 503:
          return const ServerException();
        default:
          return UnknownException('Ошибка сервера: $statusCode');
      }
    }
  }
}
