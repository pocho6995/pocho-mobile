import '../../entities/advertisement.dart';
import '../../repositories/advertisement_repository.dart';

/// Use case для получения рекламных блоков
class GetAdvertisements {
  GetAdvertisements({
    required AdvertisementRepository repository,
  }) : _repository = repository;

  final AdvertisementRepository _repository;

  /// Получение активных рекламных блоков для определенной позиции
  Future<List<AdvertisementEntity>> call({
    required String position,
  }) async {
    return await _repository.getAdvertisements(position: position);
  }
}









