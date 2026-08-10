import 'package:equatable/equatable.dart';
import '../../../domain/repositories/gas_station_repository.dart';

/// Базовый класс для событий детальной страницы станции
abstract class GasStationDetailEvent extends Equatable {
  const GasStationDetailEvent();

  @override
  List<Object> get props => [];
}

/// Событие загрузки детальной информации о станции
class LoadGasStationDetailEvent extends GasStationDetailEvent {
  final int stationId;

  const LoadGasStationDetailEvent(this.stationId);

  @override
  List<Object> get props => [stationId];
}

/// Событие обновления цен на топливо
class UpdateFuelPricesEvent extends GasStationDetailEvent {
  final int stationId;
  final List<FuelPriceInput> fuelPrices;

  const UpdateFuelPricesEvent({
    required this.stationId,
    required this.fuelPrices,
  });

  @override
  List<Object> get props => [stationId, fuelPrices];
}

/// Событие создания отзыва
class CreateReviewEvent extends GasStationDetailEvent {
  final int stationId;
  final int rating;
  final String? comment;

  const CreateReviewEvent({
    required this.stationId,
    required this.rating,
    this.comment,
  });

  @override
  List<Object> get props => [stationId, rating, comment ?? ''];
}

/// Событие обновления отзыва
class UpdateReviewEvent extends GasStationDetailEvent {
  final int stationId;
  final int reviewId;
  final int rating;
  final String? comment;

  const UpdateReviewEvent({
    required this.stationId,
    required this.reviewId,
    required this.rating,
    this.comment,
  });

  @override
  List<Object> get props => [stationId, reviewId, rating, comment ?? ''];
}

/// Событие удаления отзыва
class DeleteReviewEvent extends GasStationDetailEvent {
  final int stationId;
  final int reviewId;

  const DeleteReviewEvent({
    required this.stationId,
    required this.reviewId,
  });

  @override
  List<Object> get props => [stationId, reviewId];
}

/// Событие загрузки фотографии
class UploadPhotoEvent extends GasStationDetailEvent {
  final int stationId;
  final String filePath;
  final bool isMain;
  final int order;

  const UploadPhotoEvent({
    required this.stationId,
    required this.filePath,
    this.isMain = false,
    this.order = 0,
  });

  @override
  List<Object> get props => [stationId, filePath, isMain, order];
}

/// Событие удаления фотографии
class DeletePhotoEvent extends GasStationDetailEvent {
  final int stationId;
  final int photoId;

  const DeletePhotoEvent({
    required this.stationId,
    required this.photoId,
  });

  @override
  List<Object> get props => [stationId, photoId];
}

/// Событие обновления станции
class RefreshGasStationDetailEvent extends GasStationDetailEvent {
  final int stationId;

  const RefreshGasStationDetailEvent(this.stationId);

  @override
  List<Object> get props => [stationId];
}










