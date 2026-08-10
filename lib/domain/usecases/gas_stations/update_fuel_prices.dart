import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../../entities/gas_station.dart';
import '../../repositories/gas_station_repository.dart';

/// Use case для обновления цен на топливо
class UpdateFuelPrices
    implements UseCase<List<FuelPrice>, UpdateFuelPricesParams> {
  final GasStationRepository repository;

  UpdateFuelPrices(this.repository);

  @override
  Future<Either<Failure, List<FuelPrice>>> call(
    UpdateFuelPricesParams params,
  ) async {
    return await repository.updateFuelPrices(
      params.gasStationId,
      params.fuelPrices,
    );
  }
}

class UpdateFuelPricesParams {
  final int gasStationId;
  final List<FuelPriceInput> fuelPrices;

  UpdateFuelPricesParams({
    required this.gasStationId,
    required this.fuelPrices,
  });
}










