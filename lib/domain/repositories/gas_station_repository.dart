import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../entities/gas_station.dart';

/// Параметры фильтрации для поиска станций
class GasStationFilterParams {
  final int skip;
  final int limit;
  final String? fuelType;
  final double? minRating;
  final double? maxPrice;
  final bool? is24_7;
  final bool? hasPromotions;
  final String? searchQuery;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;
  final String? status; // Для админов

  const GasStationFilterParams({
    this.skip = 0,
    this.limit = 100,
    this.fuelType,
    this.minRating,
    this.maxPrice,
    this.is24_7,
    this.hasPromotions,
    this.searchQuery,
    this.latitude,
    this.longitude,
    this.radiusKm,
    this.status,
  });
}

/// Параметры создания станции
class CreateGasStationParams {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final bool is24_7;
  final String? workingHours;
  final String? category;
  final List<FuelPriceInput> fuelPrices;

  const CreateGasStationParams({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.is24_7 = false,
    this.workingHours,
    this.category,
    this.fuelPrices = const [],
  });
}

/// Параметры цены на топливо для создания/обновления
class FuelPriceInput {
  final String fuelType;
  final double price;

  const FuelPriceInput({required this.fuelType, required this.price});
}

/// Параметры создания отзыва
class CreateReviewParams {
  final int gasStationId;
  final int rating;
  final String? comment;

  const CreateReviewParams({
    required this.gasStationId,
    required this.rating,
    this.comment,
  });
}

/// Интерфейс репозитория заправочных станций
abstract class GasStationRepository {
  /// Получение списка станций с фильтрацией
  Future<Either<Failure, List<GasStation>>> getGasStations(
    GasStationFilterParams params,
  );

  /// Получение детальной информации о станции
  Future<Either<Failure, GasStation>> getGasStationById(int id);

  /// Создание новой станции
  Future<Either<Failure, GasStation>> createGasStation(
    CreateGasStationParams params,
  );

  /// Обновление станции (для админов)
  Future<Either<Failure, GasStation>> updateGasStation(
    int id,
    Map<String, dynamic> updates,
  );

  /// Удаление станции (для админов)
  Future<Either<Failure, void>> deleteGasStation(int id);

  /// Одобрение станции (для админов)
  Future<Either<Failure, GasStation>> approveGasStation(int id);

  /// Отклонение станции (для админов)
  Future<Either<Failure, GasStation>> rejectGasStation(int id);

  /// Загрузка фотографии
  Future<Either<Failure, GasStationPhoto>> uploadPhoto(
    int gasStationId,
    String filePath, {
    bool isMain,
    int order,
  });

  /// Удаление фотографии
  Future<Either<Failure, void>> deletePhoto(int gasStationId, int photoId);

  /// Установка главной фотографии (для админов)
  Future<Either<Failure, void>> setMainPhoto(int gasStationId, int photoId);

  /// Обновление цен на топливо
  Future<Either<Failure, List<FuelPrice>>> updateFuelPrices(
    int gasStationId,
    List<FuelPriceInput> fuelPrices,
  );

  /// Создание отзыва
  Future<Either<Failure, Review>> createReview(CreateReviewParams params);

  /// Обновление отзыва
  Future<Either<Failure, Review>> updateReview(
    int gasStationId,
    int reviewId,
    int rating,
    String? comment,
  );

  /// Удаление отзыва
  Future<Either<Failure, void>> deleteReview(int gasStationId, int reviewId);
}
