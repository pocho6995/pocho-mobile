import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../../entities/gas_station.dart';
import '../../repositories/gas_station_repository.dart';

/// Use case для получения списка заправочных станций
class GetGasStations implements UseCase<List<GasStation>, GetGasStationsParams> {
  final GasStationRepository repository;

  GetGasStations(this.repository);

  @override
  Future<Either<Failure, List<GasStation>>> call(
    GetGasStationsParams params,
  ) async {
    return await repository.getGasStations(params.filterParams);
  }
}

class GetGasStationsParams {
  final GasStationFilterParams filterParams;

  GetGasStationsParams({required this.filterParams});
}










