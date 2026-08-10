import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/errors/failures.dart';
import '../../../domain/entities/gas_station.dart';
import '../../../domain/repositories/gas_station_repository.dart';
import '../models/gas_station/gas_station_model.dart';
import '../../../services/api_client.dart';

/// Интерфейс удаленного источника данных для заправочных станций
abstract class GasStationRemoteDataSource {
  Future<List<GasStation>> getGasStations(GasStationFilterParams params);
  Future<GasStation> getGasStationById(int id);
  Future<GasStation> createGasStation(CreateGasStationParams params);
  Future<GasStation> updateGasStation(int id, Map<String, dynamic> updates);
  Future<void> deleteGasStation(int id);
  Future<GasStation> approveGasStation(int id);
  Future<GasStation> rejectGasStation(int id);
  Future<GasStationPhoto> uploadPhoto(
    int gasStationId,
    String filePath, {
    bool? isMain,
    int? order,
  });
  Future<void> deletePhoto(int gasStationId, int photoId);
  Future<void> setMainPhoto(int gasStationId, int photoId);
  Future<List<FuelPrice>> updateFuelPrices(
    int gasStationId,
    List<FuelPriceInput> fuelPrices,
  );
  Future<Review> createReview(CreateReviewParams params);
  Future<Review> updateReview(
    int gasStationId,
    int reviewId,
    int rating,
    String? comment,
  );
  Future<void> deleteReview(int gasStationId, int reviewId);
}

/// Реализация удаленного источника данных
class GasStationRemoteDataSourceImpl implements GasStationRemoteDataSource {
  final ApiClient apiClient;

  GasStationRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<GasStation>> getGasStations(GasStationFilterParams params) async {
    try {
      final queryParams = <String, String>{
        'skip': params.skip.toString(),
        'limit': params.limit.toString(),
      };

      if (params.fuelType != null) {
        queryParams['fuel_type'] = params.fuelType!;
      }
      if (params.minRating != null) {
        queryParams['min_rating'] = params.minRating!.toString();
      }
      if (params.maxPrice != null) {
        queryParams['max_price'] = params.maxPrice!.toString();
      }
      if (params.is24_7 != null) {
        queryParams['is_24_7'] = params.is24_7!.toString();
      }
      if (params.hasPromotions != null) {
        queryParams['has_promotions'] = params.hasPromotions!.toString();
      }
      if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
        queryParams['search_query'] = params.searchQuery!;
      }
      if (params.latitude != null && params.longitude != null) {
        queryParams['latitude'] = params.latitude!.toString();
        queryParams['longitude'] = params.longitude!.toString();
        if (params.radiusKm != null) {
          queryParams['radius_km'] = params.radiusKm!.toString();
        }
      }
      if (params.status != null) {
        queryParams['status'] = params.status!;
      }

      final response = await apiClient.get(
        '/api/v1/gas-stations/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final listResponse = GasStationsListResponse.fromJson(json);
        return listResponse.stations;
      } else {
        throw ServerFailure(
          'Ошибка при получении станций: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure('Ошибка при получении станций: ${e.toString()}');
    }
  }

  @override
  Future<GasStation> getGasStationById(int id) async {
    try {
      final response = await apiClient.get('/api/v1/gas-stations/$id');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        // В новом API детальная информация приходит напрямую как объект станции
        return GasStationModel.fromJson(json);
      } else {
        throw ServerFailure(
          'Ошибка при получении станции: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure('Ошибка при получении станции: ${e.toString()}');
    }
  }

  @override
  Future<GasStation> createGasStation(CreateGasStationParams params) async {
    try {
      final body = {
        'name': params.name,
        'address': params.address,
        'latitude': params.latitude,
        'longitude': params.longitude,
        'is_24_7': params.is24_7,
        if (params.phone != null) 'phone': params.phone,
        if (params.workingHours != null) 'working_hours': params.workingHours,
        if (params.category != null) 'category': params.category,
        'fuel_prices': params.fuelPrices
            .map((fp) => {'fuel_type': fp.fuelType, 'price': fp.price})
            .toList(),
      };

      final response = await apiClient.post(
        '/api/v1/gas-stations/',
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return GasStationModel.fromJson(json);
      } else {
        throw ServerFailure(
          'Ошибка при создании станции: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure('Ошибка при создании станции: ${e.toString()}');
    }
  }

  @override
  Future<GasStation> updateGasStation(
    int id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await apiClient.put(
        '/api/v1/admin/gas-stations/$id',
        body: updates,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return GasStationModel.fromJson(json);
      } else {
        throw ServerFailure(
          'Ошибка при обновлении станции: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure('Ошибка при обновлении станции: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteGasStation(int id) async {
    try {
      final response = await apiClient.delete('/api/v1/admin/gas-stations/$id');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure(
          'Ошибка при удалении станции: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure('Ошибка при удалении станции: ${e.toString()}');
    }
  }

  @override
  Future<GasStation> approveGasStation(int id) async {
    try {
      final response = await apiClient.post(
        '/api/v1/admin/gas-stations/$id/approve',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return GasStationModel.fromJson(json);
      } else {
        throw ServerFailure(
          'Ошибка при одобрении станции: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure('Ошибка при одобрении станции: ${e.toString()}');
    }
  }

  @override
  Future<GasStation> rejectGasStation(int id) async {
    try {
      final response = await apiClient.post(
        '/api/v1/admin/gas-stations/$id/reject',
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return GasStationModel.fromJson(json);
      } else {
        throw ServerFailure(
          'Ошибка при отклонении станции: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure('Ошибка при отклонении станции: ${e.toString()}');
    }
  }

  @override
  Future<GasStationPhoto> uploadPhoto(
    int gasStationId,
    String filePath, {
    bool? isMain,
    int? order,
  }) async {
    try {
      final file = File(filePath);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${ApiClient.baseUrl}/api/v1/gas-stations/$gasStationId/photos',
        ),
      );

      // Добавляем токен авторизации через ApiClient
      // ApiClient автоматически добавляет токен в заголовки
      // Для multipart запросов нужно получить токен вручную
      if (apiClient.tokenStorage != null) {
        final token = await apiClient.tokenStorage!.getAuthorizationHeader();
        if (token != null) {
          request.headers['Authorization'] = token;
        }
      }

      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['is_main'] = (isMain ?? false).toString();
      request.fields['order'] = (order ?? 0).toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return GasStationPhotoModel.fromJson(json);
      } else {
        throw ServerFailure(
          'Ошибка при загрузке фотографии: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure('Ошибка при загрузке фотографии: ${e.toString()}');
    }
  }

  @override
  Future<void> deletePhoto(int gasStationId, int photoId) async {
    try {
      final response = await apiClient.delete(
        '/api/v1/gas-stations/$gasStationId/photos/$photoId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure(
          'Ошибка при удалении фотографии: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure('Ошибка при удалении фотографии: ${e.toString()}');
    }
  }

  @override
  Future<void> setMainPhoto(int gasStationId, int photoId) async {
    try {
      final response = await apiClient.post(
        '/api/v1/admin/gas-stations/$gasStationId/photos/$photoId/set-main',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure(
          'Ошибка при установке главной фотографии: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure(
        'Ошибка при установке главной фотографии: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<FuelPrice>> updateFuelPrices(
    int gasStationId,
    List<FuelPriceInput> fuelPrices,
  ) async {
    const maxAttempts = 3;
    const retryDelay = Duration(milliseconds: 1500);

    final body = {
      'fuel_prices': fuelPrices
          .map((fp) => {'fuel_type': fp.fuelType, 'price': fp.price})
          .toList(),
    };

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await apiClient.post(
          '/api/v1/gas-stations/$gasStationId/fuel-prices',
          body: body,
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as List<dynamic>;
          return json.map((e) {
            final item = e as Map<String, dynamic>;
            if (item.containsKey('id')) {
              return FuelPriceModel.fromJson(item);
            } else {
              return FuelPriceModel(
                id: 0,
                gasStationId: gasStationId,
                fuelType: item['fuel_type'] as String,
                price: (item['price'] as num).toDouble(),
              );
            }
          }).toList();
        }
        if (response.statusCode == 403) {
          throw ServerFailure(
            'Нет прав на обновление цен. Обновлять цены могут только авторизованные пользователи (владелец АЗС или администратор).',
          );
        }
        throw ServerFailure(
          'Ошибка при обновлении цен: ${response.statusCode}',
        );
      } catch (e) {
        if (e is ServerFailure) rethrow;
        final msg = e.toString().toLowerCase();
        final isConnectionError =
            msg.contains('connection closed') ||
            msg.contains('connection refused') ||
            msg.contains('connection reset') ||
            msg.contains('socketexception') ||
            msg.contains('clientexception');
        if (isConnectionError && attempt < maxAttempts) {
          await Future<void>.delayed(retryDelay);
          continue;
        }
        final userMessage = isConnectionError
            ? 'Не удалось обновить цены. Проверьте подключение и повторите.'
            : 'Ошибка при обновлении цен: ${e.toString()}';
        throw ServerFailure(userMessage);
      }
    }
    throw ServerFailure(
      'Не удалось обновить цены. Проверьте подключение и повторите.',
    );
  }

  @override
  Future<Review> createReview(CreateReviewParams params) async {
    try {
      final body = {
        'rating': params.rating,
        if (params.comment != null) 'comment': params.comment,
      };

      final response = await apiClient.post(
        '/api/v1/gas-stations/${params.gasStationId}/reviews',
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ReviewModel.fromJson(json);
      } else {
        throw ServerFailure(
          'Ошибка при создании отзыва: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure('Ошибка при создании отзыва: ${e.toString()}');
    }
  }

  @override
  Future<Review> updateReview(
    int gasStationId,
    int reviewId,
    int rating,
    String? comment,
  ) async {
    try {
      final body = {'rating': rating, if (comment != null) 'comment': comment};

      final response = await apiClient.put(
        '/api/v1/gas-stations/$gasStationId/reviews/$reviewId',
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return ReviewModel.fromJson(json);
      } else {
        throw ServerFailure(
          'Ошибка при обновлении отзыва: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure('Ошибка при обновлении отзыва: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteReview(int gasStationId, int reviewId) async {
    try {
      final response = await apiClient.delete(
        '/api/v1/gas-stations/$gasStationId/reviews/$reviewId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure(
          'Ошибка при удалении отзыва: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure('Ошибка при удалении отзыва: ${e.toString()}');
    }
  }
}
