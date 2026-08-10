import '../../domain/entities/advertisement.dart';
import '../../domain/repositories/advertisement_repository.dart';
import '../datasources/advertisement_remote_datasource.dart';
import '../models/advertisement/advertisement_model.dart';

/// Реализация репозитория рекламы
class AdvertisementRepositoryImpl implements AdvertisementRepository {
  AdvertisementRepositoryImpl({
    required AdvertisementRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final AdvertisementRemoteDataSource _remoteDataSource;

  @override
  Future<List<AdvertisementEntity>> getAdvertisements({
    required String position,
  }) async {
    try {
      final advertisements = await _remoteDataSource.getAdvertisements(
        position: position,
      );
      return advertisements.map(_mapToEntity).toList();
    } catch (e) {
      // Возвращаем пустой список при ошибке
      return [];
    }
  }

  @override
  Future<void> registerView({
    required int advertisementId,
    String? deviceType,
    String? appVersion,
  }) async {
    await _remoteDataSource.registerView(
      advertisementId: advertisementId,
      deviceType: deviceType,
      appVersion: appVersion,
    );
  }

  @override
  Future<void> registerClick({
    required int advertisementId,
    String? deviceType,
  }) async {
    await _remoteDataSource.registerClick(
      advertisementId: advertisementId,
      deviceType: deviceType,
    );
  }

  AdvertisementEntity _mapToEntity(Advertisement model) {
    return AdvertisementEntity(
      id: model.id,
      title: model.title,
      description: model.description,
      imageUrl: model.imageUrl,
      linkUrl: model.linkUrl,
      linkType: model.linkType,
      adType: model.adType,
      position: model.position,
      status: model.status,
      isActive: model.isActive,
      startDate: model.startDate,
      endDate: model.endDate,
      priority: model.priority,
      displayOrder: model.displayOrder,
      targetAudience: model.targetAudience,
      showConditions: model.showConditions,
      viewsCount: model.viewsCount,
      clicksCount: model.clicksCount,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }
}









