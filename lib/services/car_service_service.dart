import '../models/car_service.dart';
import 'api_client.dart';

class CarServiceResponse {
  CarServiceResponse({
    required this.total,
    required this.totalFiltered,
    required this.limit,
    required this.offset,
    required this.carServices,
  });

  final int total;
  final int totalFiltered;
  final int limit;
  final int offset;
  final List<CarService> carServices;

  factory CarServiceResponse.fromJson(Map<String, dynamic> json) {
    return CarServiceResponse(
      total: json['total'] as int? ?? 0,
      totalFiltered: json['total_filtered'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
      offset: json['offset'] as int? ?? 0,
      carServices:
          (json['car_services'] as List<dynamic>?)
              ?.map((e) => CarService.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CarServiceService {
  final ApiClient apiClient;

  CarServiceService({required this.apiClient});

  /// Получить список СТО с фильтрацией
  Future<CarServiceResponse> getCarServices({
    int skip = 0,
    int limit = 100,
    String? serviceType,
    double? minRating,
    double? minPrice,
    double? maxPrice,
    bool? is24_7,
    bool? hasPromotions,
    bool? hasParking,
    bool? hasWaitingRoom,
    bool? hasCafe,
    bool? acceptsCards,
    String? searchQuery,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      if (serviceType != null && serviceType.isNotEmpty) {
        queryParams['service_type'] = serviceType;
      }
      if (minRating != null) {
        queryParams['min_rating'] = minRating.toString();
      }
      if (minPrice != null) {
        queryParams['min_price'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['max_price'] = maxPrice.toString();
      }
      if (is24_7 != null) {
        queryParams['is_24_7'] = is24_7.toString();
      }
      if (hasPromotions != null) {
        queryParams['has_promotions'] = hasPromotions.toString();
      }
      if (hasParking != null) {
        queryParams['has_parking'] = hasParking.toString();
      }
      if (hasWaitingRoom != null) {
        queryParams['has_waiting_room'] = hasWaitingRoom.toString();
      }
      if (hasCafe != null) {
        queryParams['has_cafe'] = hasCafe.toString();
      }
      if (acceptsCards != null) {
        queryParams['accepts_cards'] = acceptsCards.toString();
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search_query'] = searchQuery;
      }
      if (latitude != null) {
        queryParams['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        queryParams['longitude'] = longitude.toString();
      }
      if (radiusKm != null) {
        queryParams['radius_km'] = radiusKm.toString();
      }

      final response = await apiClient.get(
        '/api/v1/service-stations/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = apiClient.parseResponse(response);
        if (jsonData != null) {
          // Если ответ - это список СТО напрямую
          if (jsonData is List) {
            return CarServiceResponse(
              total: jsonData.length,
              totalFiltered: jsonData.length,
              limit: limit,
              offset: skip,
              carServices: (jsonData as List<dynamic>)
                  .map((e) => CarService.fromJson(e as Map<String, dynamic>))
                  .toList(),
            );
          }
          // Если ответ - это объект с полем car_services
          return CarServiceResponse.fromJson(jsonData);
        } else {
          throw Exception('Failed to parse response');
        }
      } else {
        throw Exception('Failed to load car services: ${response.statusCode}');
      }
    } catch (e) {
      // При ошибке возвращаем пустой список
      return CarServiceResponse(
        total: 0,
        totalFiltered: 0,
        limit: limit,
        offset: skip,
        carServices: [],
      );
    }
  }

  /// Получить детали СТО
  Future<CarService?> getCarServiceById(int stationId) async {
    try {
      final response = await apiClient.get(
        '/api/v1/service-stations/$stationId',
      );

      if (response.statusCode == 200) {
        final jsonData = apiClient.parseResponse(response);
        if (jsonData != null) {
          return CarService.fromJson(jsonData);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить список избранных СТО
  Future<CarServiceResponse> getFavoriteCarServices({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      final response = await apiClient.get(
        '/api/v1/service-stations/favorites',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = apiClient.parseResponse(response);
        if (jsonData != null) {
          CarServiceResponse carServiceResponse;

          // Если ответ - это список СТО напрямую
          if (jsonData is List) {
            carServiceResponse = CarServiceResponse(
              total: jsonData.length,
              totalFiltered: jsonData.length,
              limit: limit,
              offset: skip,
              carServices: (jsonData as List<dynamic>)
                  .map((e) => CarService.fromJson(e as Map<String, dynamic>))
                  .toList(),
            );
          } else {
            // Если ответ - это объект с полем car_services
            carServiceResponse = CarServiceResponse.fromJson(jsonData);
          }

          // Помечаем все СТО как избранные
          for (final carService in carServiceResponse.carServices) {
            carService.isFavorite = true;
          }
          return carServiceResponse;
        } else {
          throw Exception('Failed to parse response');
        }
      } else {
        throw Exception(
          'Failed to load favorite car services: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Возвращаем пустой список при ошибке
      return CarServiceResponse(
        total: 0,
        totalFiltered: 0,
        limit: limit,
        offset: skip,
        carServices: [],
      );
    }
  }

  /// Добавить СТО в избранное
  Future<bool> addToFavorites(int stationId) async {
    try {
      final response = await apiClient.post(
        '/api/v1/service-stations/$stationId/favorite',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to add to favorites: ${response.statusCode}');
      }
    } catch (e) {
      return false;
    }
  }

  /// Удалить СТО из избранного
  Future<bool> removeFromFavorites(int stationId) async {
    try {
      final response = await apiClient.delete(
        '/api/v1/service-stations/$stationId/favorite',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception(
          'Failed to remove from favorites: ${response.statusCode}',
        );
      }
    } catch (e) {
      return false;
    }
  }

  /// Проверить, находится ли СТО в избранном
  Future<bool> checkIsFavorite(int stationId) async {
    try {
      final response = await apiClient.get(
        '/api/v1/favorites/check/car_service/$stationId',
      );

      if (response.statusCode == 200) {
        final jsonData = apiClient.parseResponse(response);
        if (jsonData != null && jsonData.containsKey('is_favorite')) {
          return jsonData['is_favorite'] as bool? ?? false;
        }
        return false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
