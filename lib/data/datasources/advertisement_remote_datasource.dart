import 'dart:convert';
import '../models/advertisement/advertisement_model.dart';
import '../../services/api_client.dart';

/// Абстрактный класс для удаленного источника данных рекламы
abstract class AdvertisementRemoteDataSource {
  /// Получение активных рекламных блоков для определенной позиции
  Future<List<Advertisement>> getAdvertisements({
    required String position,
  });

  /// Регистрация просмотра рекламы
  Future<void> registerView({
    required int advertisementId,
    String? deviceType,
    String? appVersion,
  });

  /// Регистрация клика по рекламе
  Future<void> registerClick({
    required int advertisementId,
    String? deviceType,
  });
}

/// Реализация удаленного источника данных рекламы
class AdvertisementRemoteDataSourceImpl
    implements AdvertisementRemoteDataSource {
  AdvertisementRemoteDataSourceImpl({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<Advertisement>> getAdvertisements({
    required String position,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/advertisements/',
        queryParameters: {
          'position': position,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        return data
            .map((json) => Advertisement.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load advertisements: ${response.statusCode}');
      }
    } catch (e) {
      // Возвращаем пустой список при ошибке, чтобы не блокировать UI
      return [];
    }
  }

  @override
  Future<void> registerView({
    required int advertisementId,
    String? deviceType,
    String? appVersion,
  }) async {
    try {
      // Формируем URL с query параметрами
      var endpoint = '/api/v1/advertisements/$advertisementId/view';
      final queryParams = <String, String>{};
      if (deviceType != null) queryParams['device_type'] = deviceType;
      if (appVersion != null) queryParams['app_version'] = appVersion;

      if (queryParams.isNotEmpty) {
        final uri = Uri.parse('${ApiClient.baseUrl}$endpoint')
            .replace(queryParameters: queryParams);
        endpoint = uri.path + (uri.query.isNotEmpty ? '?${uri.query}' : '');
      }

      await _apiClient.post(endpoint);
    } catch (e) {
      // Игнорируем ошибки регистрации просмотра
      // чтобы не блокировать работу приложения
    }
  }

  @override
  Future<void> registerClick({
    required int advertisementId,
    String? deviceType,
  }) async {
    try {
      // Формируем URL с query параметрами
      var endpoint = '/api/v1/advertisements/$advertisementId/click';
      if (deviceType != null) {
        final uri = Uri.parse('${ApiClient.baseUrl}$endpoint')
            .replace(queryParameters: {'device_type': deviceType});
        endpoint = uri.path + (uri.query.isNotEmpty ? '?${uri.query}' : '');
      }

      await _apiClient.post(endpoint);
    } catch (e) {
      // Игнорируем ошибки регистрации клика
      // чтобы не блокировать работу приложения
    }
  }
}

