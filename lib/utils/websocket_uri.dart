/// Сборка URI для WebSocket без ломающих правок порта.
///
/// Dart показывает `https://` в тексте ошибки даже для `wss://` —
/// это нормально (upgrade идёт по TLS). Явный `:443` часто ломает handshake.
class WebSocketUriBuilder {
  /// [baseUrl] — `wss://host` / `ws://host` / ошибочный `https://host`.
  /// [path] — например `/api/v1/global-chat/ws`.
  static Uri build({
    required String baseUrl,
    required String path,
    Map<String, String>? queryParameters,
  }) {
    var normalized = baseUrl.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    // Частая ошибка в .env: указали https вместо wss
    if (normalized.startsWith('https://')) {
      normalized = 'wss://${normalized.substring('https://'.length)}';
    } else if (normalized.startsWith('http://')) {
      normalized = 'ws://${normalized.substring('http://'.length)}';
    }

    final pathPart = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$normalized$pathPart');

    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        ...?queryParameters,
      },
    );
  }

  static bool isPermanentFailure(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('not upgraded to websocket') ||
        text.contains('was not upgraded') ||
        text.contains('404') ||
        text.contains('not found');
  }
}
