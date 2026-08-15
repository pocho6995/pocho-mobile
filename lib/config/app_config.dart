import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Централизованная конфигурация API.
///
/// `.env` в git не коммитится, поэтому на iOS/CI часто нет файла или там localhost.
/// Продакшен-URL — дефолт; локальный бэкенд только через явный override в `.env`.
class AppConfig {
  static const String productionApiBaseUrl = 'https://olmatech.uz';
  static const String productionWsBaseUrl = 'wss://olmatech.uz';

  static String get apiBaseUrl => _resolveHttpBaseUrl(
        dotenv.env['API_BASE_URL'],
        const String.fromEnvironment('API_BASE_URL'),
      );

  static String get wsBaseUrl {
    final fromEnv = dotenv.env['WS_BASE_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty && !_isLoopback(fromEnv)) {
      return _normalizeLocalDevHost(fromEnv);
    }

    const fromCompile = String.fromEnvironment('WS_BASE_URL');
    if (fromCompile.isNotEmpty && !_isLoopback(fromCompile)) {
      return _normalizeLocalDevHost(fromCompile);
    }

    final api = apiBaseUrl;
    if (api.startsWith('https://')) {
      return api.replaceFirst('https://', 'wss://');
    }
    if (api.startsWith('http://')) {
      return api.replaceFirst('http://', 'ws://');
    }
    return productionWsBaseUrl;
  }

  static String _resolveHttpBaseUrl(String? envUrl, String compileUrl) {
    final raw = (envUrl != null && envUrl.trim().isNotEmpty)
        ? envUrl.trim()
        : (compileUrl.isNotEmpty ? compileUrl : productionApiBaseUrl);

    // localhost / 127.0.0.1 на реальном iPhone не работают — берём прод.
    // В debug на симуляторе можно явно оставить loopback через .env.
    if (_isLoopback(raw)) {
      if (!kDebugMode) {
        return productionApiBaseUrl;
      }
      // Debug + iOS device: loopback тоже бесполезен (это не Mac).
      // Оставляем loopback только если явно нужен симулятор.
      // На практике безопаснее всегда уходить на прод, если нет LAN IP.
      if (Platform.isIOS) {
        return productionApiBaseUrl;
      }
    }

    return _normalizeLocalDevHost(raw);
  }

  static bool _isLoopback(String url) {
    return url.contains('localhost') || url.contains('127.0.0.1');
  }

  static String _normalizeLocalDevHost(String url) {
    if (Platform.isAndroid && _isLoopback(url)) {
      return url
          .replaceAll('127.0.0.1', '10.0.2.2')
          .replaceAll('localhost', '10.0.2.2');
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
