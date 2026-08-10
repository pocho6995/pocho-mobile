import '../models/car_wash.dart';
import 'api_client.dart';

class CarWashResponse {
  CarWashResponse({
    required this.total,
    required this.totalFiltered,
    required this.limit,
    required this.offset,
    required this.carWashes,
  });

  final int total;
  final int totalFiltered;
  final int limit;
  final int offset;
  final List<CarWash> carWashes;

  factory CarWashResponse.fromJson(Map<String, dynamic> json) {
    return CarWashResponse(
      total: json['total'] as int? ?? 0,
      totalFiltered: json['total_filtered'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
      offset: json['offset'] as int? ?? 0,
      carWashes:
          (json['car_washes'] as List<dynamic>?)
              ?.map((e) => CarWash.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class CarWashService {
  final ApiClient apiClient;

  CarWashService({required this.apiClient});

  /// Получить список автомоек с фильтрацией
  Future<CarWashResponse> getCarWashes({
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
    bool? hasVacuum,
    bool? hasDrying,
    bool? hasSelfService,
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
      if (hasVacuum != null) {
        queryParams['has_vacuum'] = hasVacuum.toString();
      }
      if (hasDrying != null) {
        queryParams['has_drying'] = hasDrying.toString();
      }
      if (hasSelfService != null) {
        queryParams['has_self_service'] = hasSelfService.toString();
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
        '/api/v1/car-washes/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = apiClient.parseResponse(response);
        if (jsonData != null) {
          // Если ответ - это список автомоек напрямую
          if (jsonData is List) {
            return CarWashResponse(
              total: jsonData.length,
              totalFiltered: jsonData.length,
              limit: limit,
              offset: skip,
              carWashes: (jsonData as List<dynamic>)
                  .map((e) => CarWash.fromJson(e as Map<String, dynamic>))
                  .toList(),
            );
          }
          // Если ответ - это объект с полем car_washes
          return CarWashResponse.fromJson(jsonData);
        } else {
          throw Exception('Failed to parse response');
        }
      } else {
        throw Exception('Failed to load car washes: ${response.statusCode}');
      }
    } catch (e) {
      // При ошибке возвращаем пустой список
      return CarWashResponse(
        total: 0,
        totalFiltered: 0,
        limit: limit,
        offset: skip,
        carWashes: [],
      );
    }
  }

  /// Получить детали автомойки
  Future<CarWash?> getCarWashById(int carWashId) async {
    try {
      final response = await apiClient.get('/api/v1/car-washes/$carWashId');

      if (response.statusCode == 200) {
        final jsonData = apiClient.parseResponse(response);
        if (jsonData != null) {
          return CarWash.fromJson(jsonData);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить список избранных автомоек
  Future<CarWashResponse> getFavoriteCarWashes({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      final response = await apiClient.get(
        '/api/v1/car-washes/favorites',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = apiClient.parseResponse(response);
        if (jsonData != null) {
          CarWashResponse carWashResponse;

          // Если ответ - это список автомоек напрямую
          if (jsonData is List) {
            carWashResponse = CarWashResponse(
              total: jsonData.length,
              totalFiltered: jsonData.length,
              limit: limit,
              offset: skip,
              carWashes: (jsonData as List<dynamic>)
                  .map((e) => CarWash.fromJson(e as Map<String, dynamic>))
                  .toList(),
            );
          } else {
            // Если ответ - это объект с полем car_washes
            carWashResponse = CarWashResponse.fromJson(jsonData);
          }

          // Помечаем все автомойки как избранные
          for (final carWash in carWashResponse.carWashes) {
            carWash.isFavorite = true;
          }
          return carWashResponse;
        } else {
          throw Exception('Failed to parse response');
        }
      } else {
        throw Exception(
          'Failed to load favorite car washes: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Возвращаем пустой список при ошибке
      return CarWashResponse(
        total: 0,
        totalFiltered: 0,
        limit: limit,
        offset: skip,
        carWashes: [],
      );
    }
  }

  /// Добавить автомойку в избранное
  Future<bool> addToFavorites(int carWashId) async {
    try {
      final response = await apiClient.post(
        '/api/v1/car-washes/$carWashId/favorite',
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

  /// Удалить автомойку из избранного
  Future<bool> removeFromFavorites(int carWashId) async {
    try {
      final response = await apiClient.delete(
        '/api/v1/car-washes/$carWashId/favorite',
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

  /// Проверить, находится ли автомойка в избранном
  Future<bool> checkIsFavorite(int carWashId) async {
    try {
      final response = await apiClient.get(
        '/api/v1/favorites/check/car_wash/$carWashId',
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
