import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для работы с токенами авторизации
class TokenStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _tokenTypeKey = 'token_type';

  String? _cachedAccessToken;
  String? _cachedTokenType;
  bool _memoryLoaded = false;

  /// Сохранение токена
  Future<void> saveToken(String accessToken, String tokenType) async {
    _cachedAccessToken = accessToken;
    _cachedTokenType = tokenType;
    _memoryLoaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_tokenTypeKey, tokenType);
    } catch (e) {
      await Future.delayed(const Duration(milliseconds: 100));
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, accessToken);
        await prefs.setString(_tokenTypeKey, tokenType);
      } catch (e2) {
        if (kDebugMode) {
          print('❌ Failed to save token: $e2');
        }
        throw Exception('Не удалось сохранить токен: $e2');
      }
    }
  }

  Future<void> _ensureMemoryCache() async {
    if (_memoryLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _cachedAccessToken = prefs.getString(_accessTokenKey);
    _cachedTokenType = prefs.getString(_tokenTypeKey);
    _memoryLoaded = true;
  }

  /// Получение токена
  Future<String?> getAccessToken() async {
    await _ensureMemoryCache();
    return _cachedAccessToken;
  }

  /// Получение типа токена
  Future<String?> getTokenType() async {
    await _ensureMemoryCache();
    return _cachedTokenType;
  }

  /// Проверка наличия токена
  Future<bool> hasToken() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Удаление токена
  Future<void> clearToken() async {
    _cachedAccessToken = null;
    _cachedTokenType = null;
    _memoryLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_tokenTypeKey);
  }

  /// Получение полного токена для заголовка Authorization
  Future<String?> getAuthorizationHeader() async {
    await _ensureMemoryCache();
    final token = _cachedAccessToken;
    final type = _cachedTokenType;
    if (token != null && type != null) {
      return '$type $token';
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
      final parts = token.split('.');
      if (parts.length != 3) {
        return false;
      }

      final payload = parts[1];
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

      final decodedBytes = base64Url.decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      final payloadJson = jsonDecode(decodedString) as Map<String, dynamic>;

      final exp = payloadJson['exp'] as int?;
      if (exp == null) {
        return false;
      }

      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      return expirationTime.isAfter(now.add(const Duration(seconds: 60)));
    } catch (e) {
      return false;
    }
  }
}
