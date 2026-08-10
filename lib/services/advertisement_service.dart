import '../domain/entities/advertisement.dart';
import '../domain/usecases/advertisements/get_advertisements.dart';
import '../di/injection_container.dart' as di;

/// Сервис для работы с рекламой
class AdvertisementService {
  AdvertisementService() : _getAdvertisements = di.getIt<GetAdvertisements>();

  final GetAdvertisements _getAdvertisements;

  /// Получение рекламных блоков для позиции
  Future<List<AdvertisementEntity>> getAdvertisementsForPosition(
    String position,
  ) async {
    try {
      final advertisements = await _getAdvertisements.call(position: position);
      // Фильтруем только активные рекламы
      return advertisements.where((ad) => ad.isCurrentlyActive).toList();
    } catch (e) {
      // Возвращаем пустой список при ошибке
      return [];
    }
  }
}









