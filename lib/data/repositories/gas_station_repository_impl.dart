import '../../../core/errors/failures.dart';
import '../../../core/utils/either.dart';
import '../../../domain/entities/gas_station.dart';
import '../../../domain/repositories/gas_station_repository.dart';
import '../datasources/gas_station_remote_datasource.dart';

/// Реализация репозитория заправочных станций
class GasStationRepositoryImpl implements GasStationRepository {
  final GasStationRemoteDataSource remoteDataSource;

  GasStationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<GasStation>>> getGasStations(
    GasStationFilterParams params,
  ) async {
    try {
      final stations = await remoteDataSource.getGasStations(params);
      return Right(stations);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, GasStation>> getGasStationById(int id) async {
    try {
      final station = await remoteDataSource.getGasStationById(id);
      return Right(station);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, GasStation>> createGasStation(
    CreateGasStationParams params,
  ) async {
    try {
      final station = await remoteDataSource.createGasStation(params);
      return Right(station);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, GasStation>> updateGasStation(
    int id,
    Map<String, dynamic> updates,
  ) async {
    try {
      final station = await remoteDataSource.updateGasStation(id, updates);
      return Right(station);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGasStation(int id) async {
    try {
      await remoteDataSource.deleteGasStation(id);
      return const Right(null);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, GasStation>> approveGasStation(int id) async {
    try {
      final station = await remoteDataSource.approveGasStation(id);
      return Right(station);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, GasStation>> rejectGasStation(int id) async {
    try {
      final station = await remoteDataSource.rejectGasStation(id);
      return Right(station);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, GasStationPhoto>> uploadPhoto(
    int gasStationId,
    String filePath, {
    bool? isMain,
    int? order,
  }) async {
    try {
      final photo = await remoteDataSource.uploadPhoto(
        gasStationId,
        filePath,
        isMain: isMain,
        order: order,
      );
      return Right(photo);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePhoto(
    int gasStationId,
    int photoId,
  ) async {
    try {
      await remoteDataSource.deletePhoto(gasStationId, photoId);
      return const Right(null);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> setMainPhoto(
    int gasStationId,
    int photoId,
  ) async {
    try {
      await remoteDataSource.setMainPhoto(gasStationId, photoId);
      return const Right(null);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<FuelPrice>>> updateFuelPrices(
    int gasStationId,
    List<FuelPriceInput> fuelPrices,
  ) async {
    try {
      final prices = await remoteDataSource.updateFuelPrices(
        gasStationId,
        fuelPrices,
      );
      return Right(prices);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Review>> createReview(
    CreateReviewParams params,
  ) async {
    try {
      final review = await remoteDataSource.createReview(params);
      return Right(review);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Review>> updateReview(
    int gasStationId,
    int reviewId,
    int rating,
    String? comment,
  ) async {
    try {
      final review = await remoteDataSource.updateReview(
        gasStationId,
        reviewId,
        rating,
        comment,
      );
      return Right(review);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteReview(
    int gasStationId,
    int reviewId,
  ) async {
    try {
      await remoteDataSource.deleteReview(gasStationId, reviewId);
      return const Right(null);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }
}

