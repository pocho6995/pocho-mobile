import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'token_storage.dart';
import 'auth_error_handler.dart';

class ApiClient {
  final http.Client client;
  final TokenStorage? tokenStorage;

  ApiClient({http.Client? client, this.tokenStorage})
    : client = client ?? http.Client();
  static String get baseUrl {
    // Сначала проверяем .env файл
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      // Если в .env указан IP адрес сети (192.168.x.x, 10.x.x.x и т.д.), используем его для всех платформ
      if (envUrl.contains('192.168.') ||
          envUrl.contains('10.0.2.2') ||
          (envUrl.contains('10.') && !envUrl.contains('127.0.0.1'))) {
        return envUrl;
      }

      // Если в .env указан localhost или 127.0.0.1, автоматически заменяем для Android эмулятора
      // Бэкенд запущен с HOST=0.0.0.0, поэтому доступен по всем интерфейсам
      if (Platform.isAndroid &&
          (envUrl.contains('127.0.0.1') || envUrl.contains('localhost'))) {
        final correctedUrl = envUrl
            .replaceAll('127.0.0.1', '10.0.2.2')
            .replaceAll('localhost', '10.0.2.2');
        return correctedUrl;
      }

      // Для iOS и Web используем localhost как есть
      return envUrl;
    }

    // Если указан через переменную окружения компиляции, используем его
    const compileEnvUrl = String.fromEnvironment('API_BASE_URL');
    if (compileEnvUrl.isNotEmpty) {
      return compileEnvUrl;
    }

    // Автоматический выбор URL в зависимости от платформы (если .env не настроен)
    String defaultUrl;
    if (Platform.isAndroid) {
      // Для Android эмулятора используем специальный адрес
      defaultUrl = 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      // Для iOS симулятора используем localhost
      defaultUrl = 'http://localhost:8000';
    } else {
      // Для веб и других платформ используем localhost
      defaultUrl = 'http://localhost:8000';
    }

    return defaultUrl;
  }

  /// Проверка подключения к серверу
  static Future<bool> checkServerConnection() async {
    try {
      final testUrl = Uri.parse('$baseUrl/docs');
      final response = await http
          .get(testUrl, headers: {'Accept': 'text/html'})
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Connection timeout');
            },
          );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Добавляем токен авторизации если он есть
    if (tokenStorage != null) {
      try {
        final authHeader = await tokenStorage!.getAuthorizationHeader();
        if (authHeader != null) {
          headers['Authorization'] = authHeader;
        }
      } catch (e) {
        // Игнорируем ошибки при получении токена
      }
    }

    return headers;
  }

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParameters != null && queryParameters.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParameters);
      }

      final headers = await _getHeaders();

      final response = await client
          .get(uri, headers: headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      // Обработка 401 Unauthorized
      if (response.statusCode == 401) {
        await AuthErrorHandler.handleUnauthorized();
      }

      return response;
    } on SocketException catch (e) {
      rethrow;
    } on HttpException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = await _getHeaders();

      final fullUrl = '$baseUrl$endpoint';
      final bodyJson = body != null ? json.encode(body) : null;

      // Проверка на пустой номер телефона перед отправкой
      if (body != null && body.containsKey('phone_number')) {
        final phone = body['phone_number'];
        if (phone == null || phone.toString().trim().isEmpty) {
          throw Exception('Номер телефона не может быть пустым');
        }
      }

      final response = await client
          .post(Uri.parse(fullUrl), headers: headers, body: bodyJson)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      // Обработка 401 Unauthorized
      if (response.statusCode == 401) {
        await AuthErrorHandler.handleUnauthorized();
      }

      return response;
    } on SocketException catch (e) {
      rethrow;
    } on HttpException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await client
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      // Обработка 401 Unauthorized
      if (response.statusCode == 401) {
        await AuthErrorHandler.handleUnauthorized();
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> patch(String endpoint, {String? body}) async {
    try {
      final headers = await _getHeaders();

      final response = await client
          .patch(Uri.parse('$baseUrl$endpoint'), headers: headers, body: body)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      // Обработка 401 Unauthorized
      if (response.statusCode == 401) {
        await AuthErrorHandler.handleUnauthorized();
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> patchMultipart(String endpoint, File file) async {
    try {
      final headers = await _getHeaders();
      // Удаляем Content-Type для multipart, он будет установлен автоматически
      headers.remove('Content-Type');

      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl$endpoint'),
      );

      // Добавляем заголовки авторизации
      request.headers.addAll(headers);

      // Определяем тип файла
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();
      MediaType contentType;

      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          contentType = MediaType('image', 'jpeg');
          break;
        case 'png':
          contentType = MediaType('image', 'png');
          break;
        case 'webp':
          contentType = MediaType('image', 'webp');
          break;
        default:
          contentType = MediaType('image', 'jpeg');
      }

      // Добавляем файл
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
          contentType: contentType,
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60), // Увеличиваем таймаут для загрузки файлов
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      // Обработка 401 Unauthorized
      if (response.statusCode == 401) {
        await AuthErrorHandler.handleUnauthorized();
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();

      final response = await client
          .delete(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      // Обработка 401 Unauthorized
      if (response.statusCode == 401) {
        await AuthErrorHandler.handleUnauthorized();
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic>? parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body) as Map<String, dynamic>?;
      } catch (e) {
        return null;
      }
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  List<dynamic>? parseListResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return json.decode(response.body) as List<dynamic>?;
      } catch (e) {
        return null;
      }
    } else {
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
