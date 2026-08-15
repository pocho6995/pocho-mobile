import '../config/app_config.dart';
import '../services/api_client.dart';

/// Преобразует URL изображений с API в рабочие полные URL.
class ImageUrlHelper {
  /// Относительный путь → `https://olmatech.uz/...`
  /// `http://localhost:8000/uploads/...` → тот же path на текущем API host.
  static String? getFullImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return null;
    }

    final trimmed = url.trim();

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _rewriteLoopbackToApiBase(trimmed);
    }

    final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    return '${_apiBase()}/$cleanPath';
  }

  static String getFullImageUrlOrEmpty(String? url) {
    return getFullImageUrl(url) ?? '';
  }

  static String _rewriteLoopbackToApiBase(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      return url;
    }

    final host = uri.host.toLowerCase();
    final isLoopback = host == 'localhost' || host == '127.0.0.1';
    if (!isLoopback) {
      return url;
    }

    final apiBase = Uri.parse(_apiBase());
    // Uri.replace(port: null) keeps the old port — rebuild so :8000 is dropped.
    return Uri(
      scheme: apiBase.scheme,
      host: apiBase.host,
      port: apiBase.hasPort ? apiBase.port : null,
      path: uri.path,
      query: uri.hasQuery ? uri.query : null,
      fragment: uri.hasFragment ? uri.fragment : null,
    ).toString();
  }

  static String _apiBase() {
    var base = ApiClient.baseUrl.trim();
    if (base.isEmpty || AppConfig.isLoopback(base)) {
      base = AppConfig.productionApiBaseUrl;
    }
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return base;
  }
}
