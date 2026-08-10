import 'package:equatable/equatable.dart';
import '../../../domain/entities/gas_station.dart';

/// Базовый класс для состояний детальной страницы станции
abstract class GasStationDetailState extends Equatable {
  const GasStationDetailState();

  @override
  List<Object?> get props => [];
}

/// Начальное состояние
class GasStationDetailInitial extends GasStationDetailState {
  const GasStationDetailInitial();
}

/// Состояние загрузки
class GasStationDetailLoading extends GasStationDetailState {
  const GasStationDetailLoading();
}

/// Состояние успешной загрузки
class GasStationDetailLoaded extends GasStationDetailState {
  final GasStation station;

  const GasStationDetailLoaded(this.station);

  @override
  List<Object> get props => [station];
}

/// Состояние ошибки
class GasStationDetailError extends GasStationDetailState {
  final String message;

  const GasStationDetailError(this.message);

  @override
  List<Object> get props => [message];
}

/// Состояние обновления цен
class GasStationDetailUpdatingPrices extends GasStationDetailState {
  final GasStation station;

  const GasStationDetailUpdatingPrices(this.station);

  @override
  List<Object> get props => [station];
}

/// Состояние создания отзыва
class GasStationDetailCreatingReview extends GasStationDetailState {
  final GasStation station;

  const GasStationDetailCreatingReview(this.station);

  @override
  List<Object> get props => [station];
}

/// Состояние загрузки фотографии
class GasStationDetailUploadingPhoto extends GasStationDetailState {
  final GasStation station;

  const GasStationDetailUploadingPhoto(this.station);

  @override
  List<Object> get props => [station];
}










