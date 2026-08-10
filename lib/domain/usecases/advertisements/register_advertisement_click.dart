import '../../repositories/advertisement_repository.dart';

/// Use case для регистрации клика по рекламе
class RegisterAdvertisementClick {
  RegisterAdvertisementClick({
    required AdvertisementRepository repository,
  }) : _repository = repository;

  final AdvertisementRepository _repository;

  /// Регистрация клика по рекламе
  Future<void> call({
    required int advertisementId,
    String? deviceType,
  }) async {
    await _repository.registerClick(
      advertisementId: advertisementId,
      deviceType: deviceType,
    );
  }
}









