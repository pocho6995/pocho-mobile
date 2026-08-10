import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../../entities/gas_station.dart';
import '../../repositories/gas_station_repository.dart';

/// Use case для создания новой заправочной станции
class CreateGasStation
    implements UseCase<GasStation, CreateGasStationParams> {
  final GasStationRepository repository;

  CreateGasStation(this.repository);

  @override
  Future<Either<Failure, GasStation>> call(
    CreateGasStationParams params,
  ) async {
    return await repository.createGasStation(params);
  }
}










