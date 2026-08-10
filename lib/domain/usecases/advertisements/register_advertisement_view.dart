import '../../repositories/advertisement_repository.dart';

/// Use case для регистрации просмотра рекламы
class RegisterAdvertisementView {
  RegisterAdvertisementView({
    required AdvertisementRepository repository,
  }) : _repository = repository;

  final AdvertisementRepository _repository;

  /// Регистрация просмотра рекламы
  Future<void> call({
    required int advertisementId,
    String? deviceType,
    String? appVersion,
  }) async {
    await _repository.registerView(
      advertisementId: advertisementId,
      deviceType: deviceType,
      appVersion: appVersion,
    );
  }
}









