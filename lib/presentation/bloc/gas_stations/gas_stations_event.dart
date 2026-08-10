import 'package:equatable/equatable.dart';
import '../../../domain/repositories/gas_station_repository.dart';

/// Базовый класс для событий списка заправочных станций
abstract class GasStationsEvent extends Equatable {
  const GasStationsEvent();

  @override
  List<Object> get props => [];
}

/// Событие загрузки списка станций
class LoadGasStationsEvent extends GasStationsEvent {
  final GasStationFilterParams filterParams;

  const LoadGasStationsEvent({required this.filterParams});

  @override
  List<Object> get props => [filterParams];
}

/// Событие обновления фильтров
class UpdateFiltersEvent extends GasStationsEvent {
  final GasStationFilterParams filterParams;

  const UpdateFiltersEvent({required this.filterParams});

  @override
  List<Object> get props => [filterParams];
}

/// Событие загрузки следующей страницы
class LoadMoreGasStationsEvent extends GasStationsEvent {
  const LoadMoreGasStationsEvent();
}

/// Событие обновления списка
class RefreshGasStationsEvent extends GasStationsEvent {
  const RefreshGasStationsEvent();
}










