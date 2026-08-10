import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../../entities/gas_station.dart';
import '../../repositories/gas_station_repository.dart';

/// Use case для получения детальной информации о станции
class GetGasStationById
    implements UseCase<GasStation, GetGasStationByIdParams> {
  final GasStationRepository repository;

  GetGasStationById(this.repository);

  @override
  Future<Either<Failure, GasStation>> call(
    GetGasStationByIdParams params,
  ) async {
    return await repository.getGasStationById(params.id);
  }
}

class GetGasStationByIdParams {
  final int id;

  GetGasStationByIdParams({required this.id});
}










