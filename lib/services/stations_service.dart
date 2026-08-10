import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/fuel_station.dart';
import 'api_client.dart';

class StationsService {
  final ApiClient apiClient;

  StationsService({required this.apiClient});

  Future<StationsResponse> getStations({
    bool? hasGasoline,
    bool? hasAi80,
    bool? hasAi91,
    bool? hasAi95,
    bool? hasAi98,
    bool? hasDiesel,
    String? name,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      if (hasGasoline != null) {
        queryParams['has_gasoline'] = hasGasoline.toString();
      }
      if (hasAi80 != null) {
        queryParams['has_ai_80'] = hasAi80.toString();
      }
      if (hasAi91 != null) {
        queryParams['has_ai_91'] = hasAi91.toString();
      }
      if (hasAi95 != null) {
        queryParams['has_ai_95'] = hasAi95.toString();
      }
      if (hasAi98 != null) {
        queryParams['has_ai_98'] = hasAi98.toString();
      }
      if (hasDiesel != null) {
        queryParams['has_diesel'] = hasDiesel.toString();
      }
      if (name != null && name.isNotEmpty) {
        queryParams['name'] = name;
      }

      final response = await apiClient.get(
        '/stations',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = apiClient.parseResponse(response);
        if (jsonData != null) {
          return StationsResponse.fromJson(jsonData);
        } else {
          throw Exception('Failed to parse response');
        }
      } else {
        throw Exception('Failed to load stations: ${response.statusCode}');
      }
    } catch (e) {
      return StationsResponse(
        total: 0,
        totalFiltered: 0,
        limit: limit,
        offset: offset,
        places: [],
      );
    }
  }

  /// Получить список избранных заправок
  Future<StationsResponse> getFavoriteStations({
    int limit = 20,
    int skip = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'skip': skip.toString(),
      };

      final response = await apiClient.get(
        '/api/v1/gas-stations/favorites',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // Парсим ответ напрямую, так как parseResponse может вернуть разные типы
        dynamic jsonData;
        try {
          jsonData = json.decode(response.body);
        } catch (e) {
          throw Exception('Failed to parse JSON: $e');
        }

        if (jsonData == null) {
          throw Exception('Failed to parse response: jsonData is null');
        }

        StationsResponse stationsResponse;

        // Если ответ - это список заправок напрямую
        if (jsonData is List) {
          final listData = jsonData
              .map((e) => e as Map<String, dynamic>)
              .toList();
          stationsResponse = StationsResponse(
            total: jsonData.length,
            totalFiltered: jsonData.length,
            limit: limit,
            offset: skip,
            places: listData.map((e) => FuelStation.fromJson(e)).toList(),
          );
        } else if (jsonData is Map) {
          // Если ответ - это объект
          final jsonMap = jsonData as Map<String, dynamic>;

          // Если ответ - это объект с полем places
          if (jsonMap.containsKey('places')) {
            stationsResponse = StationsResponse.fromJson(jsonMap);
          } else if (jsonMap.containsKey('stations')) {
            // Если API возвращает stations вместо places
            final stationsList = jsonMap['stations'] as List<dynamic>? ?? [];
            stationsResponse = StationsResponse(
              total: stationsList.length,
              totalFiltered: stationsList.length,
              limit: limit,
              offset: skip,
              places: stationsList
                  .map((e) => FuelStation.fromJson(e as Map<String, dynamic>))
                  .toList(),
            );
          } else {
            // Пытаемся найти список в любом поле
            List<dynamic>? stationsList;
            for (final key in jsonMap.keys) {
              if (jsonMap[key] is List) {
                stationsList = jsonMap[key] as List<dynamic>;
                break;
              }
            }

            if (stationsList != null) {
              stationsResponse = StationsResponse(
                total: stationsList.length,
                totalFiltered: stationsList.length,
                limit: limit,
                offset: skip,
                places: stationsList
                    .map((e) => FuelStation.fromJson(e as Map<String, dynamic>))
                    .toList(),
              );
            } else {
              throw Exception(
                'Unexpected response format: no places/stations found',
              );
            }
          }
        } else {
          throw Exception('Unexpected response type: ${jsonData.runtimeType}');
        }

        // Помечаем все заправки как избранные
        for (final station in stationsResponse.places) {
          station.isFavorite = true;
        }

        return stationsResponse;
      } else {
        throw Exception(
          'Failed to load favorite stations: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Логируем ошибку для отладки (в debug режиме)
      if (kDebugMode) {
        print('Error loading favorite stations: $e');
      }
      // Возвращаем пустой список при ошибке
      return StationsResponse(
        total: 0,
        totalFiltered: 0,
        limit: limit,
        offset: skip,
        places: [],
      );
    }
  }

  /// Добавить заправку в избранное
  Future<bool> addToFavorites(int stationId) async {
    try {
      final response = await apiClient.post(
        '/api/v1/gas-stations/$stationId/favorite',
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

  /// Удалить заправку из избранного
  Future<bool> removeFromFavorites(int stationId) async {
    try {
      final response = await apiClient.delete(
        '/api/v1/gas-stations/$stationId/favorite',
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

  /// Проверить, находится ли заправка в избранном
  Future<bool> checkIsFavorite(int stationId) async {
    try {
      final response = await apiClient.get(
        '/api/v1/favorites/check/fuel_station/$stationId',
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
