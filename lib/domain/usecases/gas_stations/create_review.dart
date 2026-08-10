import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../../entities/gas_station.dart';
import '../../repositories/gas_station_repository.dart';

/// Use case для создания отзыва
class CreateReview implements UseCase<Review, CreateReviewParams> {
  final GasStationRepository repository;

  CreateReview(this.repository);

  @override
  Future<Either<Failure, Review>> call(CreateReviewParams params) async {
    return await repository.createReview(params);
  }
}










