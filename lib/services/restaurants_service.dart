import '../models/restaurant.dart';
import 'api_client.dart';

class RestaurantsResponse {
  RestaurantsResponse({
    required this.total,
    required this.totalFiltered,
    required this.limit,
    required this.offset,
    required this.restaurants,
  });

  final int total;
  final int totalFiltered;
  final int limit;
  final int offset;
  final List<Restaurant> restaurants;

  factory RestaurantsResponse.fromJson(Map<String, dynamic> json) {
    return RestaurantsResponse(
      total: json['total'] as int? ?? 0,
      totalFiltered: json['total_filtered'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
      offset: json['offset'] as int? ?? 0,
      restaurants:
          (json['restaurants'] as List<dynamic>?)
              ?.map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class RestaurantsService {
  final ApiClient apiClient;

  RestaurantsService({required this.apiClient});

  /// Получить список ресторанов с фильтрацией
  Future<RestaurantsResponse> getRestaurants({
    int skip = 0,
    int limit = 100,
    String? cuisineType,
    double? minRating,
    double? minAverageCheck,
    double? maxAverageCheck,
    bool? is24_7,
    bool? hasPromotions,
    bool? hasBooking,
    bool? hasDelivery,
    bool? hasParking,
    bool? hasWifi,
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

      if (cuisineType != null && cuisineType.isNotEmpty) {
        queryParams['cuisine_type'] = cuisineType;
      }
      if (minRating != null) {
        queryParams['min_rating'] = minRating.toString();
      }
      if (minAverageCheck != null) {
        queryParams['min_average_check'] = minAverageCheck.toString();
      }
      if (maxAverageCheck != null) {
        queryParams['max_average_check'] = maxAverageCheck.toString();
      }
      if (is24_7 != null) {
        queryParams['is_24_7'] = is24_7.toString();
      }
      if (hasPromotions != null) {
        queryParams['has_promotions'] = hasPromotions.toString();
      }
      if (hasBooking != null) {
        queryParams['has_booking'] = hasBooking.toString();
      }
      if (hasDelivery != null) {
        queryParams['has_delivery'] = hasDelivery.toString();
      }
      if (hasParking != null) {
        queryParams['has_parking'] = hasParking.toString();
      }
      if (hasWifi != null) {
        queryParams['has_wifi'] = hasWifi.toString();
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
        '/api/v1/restaurants/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = apiClient.parseResponse(response);
        if (jsonData != null) {
          // Если ответ - это список ресторанов напрямую
          if (jsonData is List) {
            return RestaurantsResponse(
              total: jsonData.length,
              totalFiltered: jsonData.length,
              limit: limit,
              offset: skip,
              restaurants: (jsonData as List<dynamic>)
                  .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
                  .toList(),
            );
          }
          // Если ответ - это объект с полем restaurants
          return RestaurantsResponse.fromJson(jsonData);
        } else {
          throw Exception('Failed to parse response');
        }
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e) {
      // При ошибке возвращаем пустой список
      return RestaurantsResponse(
        total: 0,
        totalFiltered: 0,
        limit: limit,
        offset: skip,
        restaurants: [],
      );
    }
  }

  /// Получить детали ресторана
  Future<Restaurant?> getRestaurantById(int restaurantId) async {
    try {
      final response = await apiClient.get('/api/v1/restaurants/$restaurantId');

      if (response.statusCode == 200) {
        final jsonData = apiClient.parseResponse(response);
        if (jsonData != null) {
          return Restaurant.fromJson(jsonData);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить список избранных ресторанов
  Future<RestaurantsResponse> getFavoriteRestaurants({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      final response = await apiClient.get(
        '/api/v1/restaurants/favorites',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = apiClient.parseResponse(response);
        if (jsonData != null) {
          RestaurantsResponse restaurantsResponse;

          // Если ответ - это список ресторанов напрямую
          if (jsonData is List) {
            final listData = jsonData as List<dynamic>;
            restaurantsResponse = RestaurantsResponse(
              total: listData.length,
              totalFiltered: listData.length,
              limit: limit,
              offset: skip,
              restaurants: listData
                  .map((e) => Restaurant.fromJson(e as Map<String, dynamic>))
                  .toList(),
            );
          } else {
            // Если ответ - это объект с полем restaurants
            restaurantsResponse = RestaurantsResponse.fromJson(jsonData);
          }

          // Помечаем все рестораны как избранные
          for (final restaurant in restaurantsResponse.restaurants) {
            restaurant.isFavorite = true;
          }
          return restaurantsResponse;
        } else {
          throw Exception('Failed to parse response');
        }
      } else {
        throw Exception(
          'Failed to load favorite restaurants: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Возвращаем пустой список при ошибке
      return RestaurantsResponse(
        total: 0,
        totalFiltered: 0,
        limit: limit,
        offset: skip,
        restaurants: [],
      );
    }
  }

  /// Добавить ресторан в избранное
  Future<bool> addToFavorites(int restaurantId) async {
    try {
      final response = await apiClient.post(
        '/api/v1/restaurants/$restaurantId/favorite',
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

  /// Удалить ресторан из избранного
  Future<bool> removeFromFavorites(int restaurantId) async {
    try {
      final response = await apiClient.delete(
        '/api/v1/restaurants/$restaurantId/favorite',
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

  /// Проверить, находится ли ресторан в избранном
  Future<bool> checkIsFavorite(int restaurantId) async {
    try {
      final response = await apiClient.get(
        '/api/v1/favorites/check/restaurant/$restaurantId',
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

  // Мок данные удалены - используются только данные с сервера
}
