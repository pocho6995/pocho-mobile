import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Централизованная конфигурация API.
///
/// `.env` в git не коммитится, поэтому на iOS/CI часто нет файла или там localhost.
/// Продакшен-URL — дефолт; локальный бэкенд только через явный LAN override.
class AppConfig {
  static const String productionApiBaseUrl = 'https://olmatech.uz';
  static const String productionWsBaseUrl = 'wss://olmatech.uz';

  /// Для тестов можно подменить флаги платформы.
  @visibleForTesting
  static bool? debugIsAndroid;

  @visibleForTesting
  static bool? debugIsIOS;

  @visibleForTesting
  static bool? debugIsDebugMode;

  static bool get _isAndroid => debugIsAndroid ?? Platform.isAndroid;
  static bool get _isIOS => debugIsIOS ?? Platform.isIOS;
  static bool get _isDebugMode => debugIsDebugMode ?? kDebugMode;

  static String get apiBaseUrl => resolveApiBaseUrl(
        envUrl: dotenv.isInitialized ? dotenv.env['API_BASE_URL'] : null,
        compileUrl: const String.fromEnvironment('API_BASE_URL'),
        isAndroid: _isAndroid,
        isIOS: _isIOS,
        isDebugMode: _isDebugMode,
      );

  static String get wsBaseUrl => resolveWsBaseUrl(
        envUrl: dotenv.isInitialized ? dotenv.env['WS_BASE_URL'] : null,
        compileUrl: const String.fromEnvironment('WS_BASE_URL'),
        apiBaseUrl: apiBaseUrl,
        isAndroid: _isAndroid,
      );

  /// Чистая логика выбора HTTP base URL (удобно тестировать).
  static String resolveApiBaseUrl({
    required String? envUrl,
    required String compileUrl,
    required bool isAndroid,
    required bool isIOS,
    required bool isDebugMode,
  }) {
    final raw = (envUrl != null && envUrl.trim().isNotEmpty)
        ? envUrl.trim()
        : (compileUrl.isNotEmpty ? compileUrl : productionApiBaseUrl);

    if (isLoopback(raw)) {
      // Release всегда на прод.
      if (!isDebugMode) {
        return productionApiBaseUrl;
      }
      // iOS (device/simulator с битым localhost) → прод.
      if (isIOS) {
        return productionApiBaseUrl;
      }
    }

    return normalizeLocalDevHost(raw, isAndroid: isAndroid);
  }

  static String resolveWsBaseUrl({
    required String? envUrl,
    required String compileUrl,
    required String apiBaseUrl,
    required bool isAndroid,
  }) {
    final fromEnv = envUrl?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty && !isLoopback(fromEnv)) {
      return normalizeLocalDevHost(fromEnv, isAndroid: isAndroid);
    }

    if (compileUrl.isNotEmpty && !isLoopback(compileUrl)) {
      return normalizeLocalDevHost(compileUrl, isAndroid: isAndroid);
    }

    if (apiBaseUrl.startsWith('https://')) {
      return apiBaseUrl.replaceFirst('https://', 'wss://');
    }
    if (apiBaseUrl.startsWith('http://')) {
      return apiBaseUrl.replaceFirst('http://', 'ws://');
    }
    return productionWsBaseUrl;
  }

  static bool isLoopback(String url) {
    return url.contains('localhost') || url.contains('127.0.0.1');
  }

  static String normalizeLocalDevHost(
    String url, {
    required bool isAndroid,
  }) {
    var result = url;
    if (isAndroid && isLoopback(result)) {
      result = result
          .replaceAll('127.0.0.1', '10.0.2.2')
          .replaceAll('localhost', '10.0.2.2');
    }
    return result.endsWith('/') ? result.substring(0, result.length - 1) : result;
  }

  @visibleForTesting
  static void resetDebugOverrides() {
    debugIsAndroid = null;
    debugIsIOS = null;
    debugIsDebugMode = null;
  }
}
