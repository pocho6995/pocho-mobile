import '../models/charging_station.dart';
import 'api_client.dart';

// ChargingStationResponse определен в models/charging_station.dart

class ChargingStationService {
  final ApiClient apiClient;

  ChargingStationService({required this.apiClient});

  /// Получить список электрозаправок с фильтрацией
  Future<ChargingStationResponse> getChargingStations({
    int skip = 0,
    int limit = 100,
    String? connectorType,
    double? minPowerKw,
    double? maxPowerKw,
    double? minPricePerKwh,
    double? maxPricePerKwh,
    double? minRating,
    bool? is24_7,
    bool? hasPromotions,
    bool? hasParking,
    bool? hasWaitingRoom,
    bool? hasCafe,
    bool? hasRestroom,
    bool? acceptsCards,
    bool? hasMobileApp,
    bool? requiresMembership,
    bool? hasAvailablePoints,
    String? operator,
    String? network,
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

      if (connectorType != null && connectorType.isNotEmpty) {
        queryParams['connector_type'] = connectorType;
      }
      if (minPowerKw != null) {
        queryParams['min_power_kw'] = minPowerKw.toString();
      }
      if (maxPowerKw != null) {
        queryParams['max_power_kw'] = maxPowerKw.toString();
      }
      if (minPricePerKwh != null) {
        queryParams['min_price_per_kwh'] = minPricePerKwh.toString();
      }
      if (maxPricePerKwh != null) {
        queryParams['max_price_per_kwh'] = maxPricePerKwh.toString();
      }
      if (minRating != null) {
        queryParams['min_rating'] = minRating.toString();
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
      if (hasRestroom != null) {
        queryParams['has_restroom'] = hasRestroom.toString();
      }
      if (acceptsCards != null) {
        queryParams['accepts_cards'] = acceptsCards.toString();
      }
      if (hasMobileApp != null) {
        queryParams['has_mobile_app'] = hasMobileApp.toString();
      }
      if (requiresMembership != null) {
        queryParams['requires_membership'] = requiresMembership.toString();
      }
      if (hasAvailablePoints != null) {
        queryParams['has_available_points'] = hasAvailablePoints.toString();
      }
      if (operator != null && operator.isNotEmpty) {
        queryParams['operator'] = operator;
      }
      if (network != null && network.isNotEmpty) {
        queryParams['network'] = network;
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
        '/api/v1/electric-stations/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = apiClient.parseResponse(response);
        if (jsonData != null) {
          // Если ответ - это список электрозаправок напрямую
          if (jsonData is List) {
            return ChargingStationResponse(
              stations: (jsonData as List<dynamic>)
                  .map(
                    (e) => ChargingStation.fromJson(e as Map<String, dynamic>),
                  )
                  .toList(),
            );
          }
          // Если ответ - это объект с полем stations
          return ChargingStationResponse.fromJson(jsonData);
        } else {
          throw Exception('Failed to parse response');
        }
      } else {
        throw Exception(
          'Failed to load charging stations: ${response.statusCode}',
        );
      }
    } catch (e) {
      // При ошибке возвращаем пустой список
      return ChargingStationResponse(stations: []);
    }
  }

  /// Получить детали электрозаправки
  Future<ChargingStation?> getChargingStationById(int stationId) async {
    try {
      final response = await apiClient.get(
        '/api/v1/electric-stations/$stationId',
      );

      if (response.statusCode == 200) {
        final jsonData = apiClient.parseResponse(response);
        if (jsonData != null) {
          return ChargingStation.fromJson(jsonData);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Получить список избранных электрозаправок
  Future<ChargingStationResponse> getFavoriteChargingStations({
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      final response = await apiClient.get(
        '/api/v1/electric-stations/favorites',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = apiClient.parseResponse(response);
        if (jsonData != null) {
          ChargingStationResponse chargingStationResponse;

          // Если ответ - это список электрозаправок напрямую
          if (jsonData is List) {
            chargingStationResponse = ChargingStationResponse(
              stations: (jsonData as List<dynamic>)
                  .map(
                    (e) => ChargingStation.fromJson(e as Map<String, dynamic>),
                  )
                  .toList(),
            );
          } else {
            // Если ответ - это объект с полем stations
            chargingStationResponse = ChargingStationResponse.fromJson(
              jsonData,
            );
          }

          // Помечаем все электрозаправки как избранные
          for (final station in chargingStationResponse.stations) {
            station.isFavorite = true;
          }
          return chargingStationResponse;
        } else {
          throw Exception('Failed to parse response');
        }
      } else {
        throw Exception(
          'Failed to load favorite charging stations: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Возвращаем пустой список при ошибке
      return ChargingStationResponse(stations: []);
    }
  }

  /// Добавить электрозаправку в избранное
  Future<bool> addToFavorites(int stationId) async {
    try {
      final response = await apiClient.post(
        '/api/v1/electric-stations/$stationId/favorite',
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

  /// Удалить электрозаправку из избранного
  Future<bool> removeFromFavorites(int stationId) async {
    try {
      final response = await apiClient.delete(
        '/api/v1/electric-stations/$stationId/favorite',
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

  /// Проверить, находится ли электрозаправка в избранном
  Future<bool> checkIsFavorite(int stationId) async {
    try {
      final response = await apiClient.get(
        '/api/v1/favorites/check/charging_station/$stationId',
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
