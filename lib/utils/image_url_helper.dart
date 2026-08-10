import '../services/api_client.dart';

/// Утилита для преобразования относительных URL изображений в полные
class ImageUrlHelper {
  /// Преобразует относительный URL в полный
  /// Если URL уже полный (начинается с http:// или https://), возвращает его как есть
  /// Если URL относительный, добавляет базовый URL API
  static String? getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null;
    }

    // Если URL уже полный, возвращаем как есть
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Если URL начинается с /, убираем его
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;

    // Добавляем базовый URL API
    final baseUrl = ApiClient.baseUrl;
    // Убираем завершающий слэш из baseUrl, если есть
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    return '$cleanBaseUrl/$cleanUrl';
  }
}









