import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для работы с токенами авторизации
class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _tokenTypeKey = 'token_type';

  /// Сохранение токена
  Future<void> saveToken(String accessToken, String tokenType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_tokenTypeKey, tokenType);
      if (kDebugMode) {
        print('✅ Token saved: type=$tokenType, token=${accessToken.substring(0, accessToken.length > 20 ? 20 : accessToken.length)}...');
      }
    } catch (e) {
      // Если не удалось сохранить, пробуем еще раз через небольшую задержку
      await Future.delayed(const Duration(milliseconds: 100));
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, accessToken);
        await prefs.setString(_tokenTypeKey, tokenType);
        if (kDebugMode) {
          print('✅ Token saved (retry): type=$tokenType, token=${accessToken.substring(0, accessToken.length > 20 ? 20 : accessToken.length)}...');
        }
      } catch (e2) {
        if (kDebugMode) {
          print('❌ Failed to save token: $e2');
        }
        throw Exception('Не удалось сохранить токен: $e2');
      }
    }
  }

  /// Получение токена
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  /// Получение типа токена
  Future<String?> getTokenType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenTypeKey);
  }

  /// Проверка наличия токена
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Удаление токена
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_tokenTypeKey);
  }

  /// Получение полного токена для заголовка Authorization
  Future<String?> getAuthorizationHeader() async {
    final token = await getAccessToken();
    final type = await getTokenType();
    if (kDebugMode) {
      print('🔑 Getting auth header: token=${token != null ? "${token.substring(0, token.length > 20 ? 20 : token.length)}..." : "null"}, type=$type');
    }
    if (token != null && type != null) {
      final header = '$type $token';
      if (kDebugMode) {
        print('✅ Auth header created: ${header.substring(0, header.length > 30 ? 30 : header.length)}...');
      }
      return header;
    }
    if (kDebugMode) {
      print('ℹ️ No auth header - user not authenticated (this is normal for unauthenticated requests)');
    }
    return null;
  }

  /// Проверка валидности токена (проверяет exp в JWT)
  Future<bool> isTokenValid() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      // JWT токен состоит из трех частей: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        return false;
      }

      // Декодируем payload (вторая часть)
      final payload = parts[1];
      
      // Добавляем padding если нужно (base64 требует padding)
      var normalizedPayload = payload;
      switch (payload.length % 4) {
        case 1:
          normalizedPayload += '===';
          break;
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      // Декодируем base64
      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      final payloadJson = jsonDecode(decodedString) as Map<String, dynamic>;

      // Проверяем exp (expiration time в Unix timestamp)
      final exp = payloadJson['exp'] as int?;
      if (exp == null) {
        return false;
      }

      // Проверяем, не истек ли токен (добавляем небольшой запас в 60 секунд)
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final isValid = expirationTime.isAfter(now.add(const Duration(seconds: 60)));

      return isValid;
    } catch (e) {
      // Если не удалось декодировать токен, считаем его невалидным
      return false;
    }
  }
}

