import '../entities/advertisement.dart';

/// Репозиторий для работы с рекламой
abstract class AdvertisementRepository {
  /// Получение активных рекламных блоков для определенной позиции
  Future<List<AdvertisementEntity>> getAdvertisements({
    required String position,
  });

  /// Регистрация просмотра рекламы
  Future<void> registerView({
    required int advertisementId,
    String? deviceType,
    String? appVersion,
  });

  /// Регистрация клика по рекламе
  Future<void> registerClick({
    required int advertisementId,
    String? deviceType,
  });
}









