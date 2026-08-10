import 'package:equatable/equatable.dart';
import '../../../domain/entities/gas_station.dart';
import '../../../domain/repositories/gas_station_repository.dart';

/// Базовый класс для состояний списка заправочных станций
abstract class GasStationsState extends Equatable {
  const GasStationsState();

  @override
  List<Object?> get props => [];
}

/// Начальное состояние
class GasStationsInitial extends GasStationsState {
  const GasStationsInitial();
}

/// Состояние загрузки
class GasStationsLoading extends GasStationsState {
  const GasStationsLoading();
}

/// Состояние успешной загрузки
class GasStationsLoaded extends GasStationsState {
  final List<GasStation> stations;
  final GasStationFilterParams filterParams;
  final int total;
  final bool hasMore;
  final bool isLoadingMore;

  const GasStationsLoaded({
    required this.stations,
    required this.filterParams,
    required this.total,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  List<Object> get props => [stations, filterParams, total, hasMore, isLoadingMore];

  GasStationsLoaded copyWith({
    List<GasStation>? stations,
    GasStationFilterParams? filterParams,
    int? total,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return GasStationsLoaded(
      stations: stations ?? this.stations,
      filterParams: filterParams ?? this.filterParams,
      total: total ?? this.total,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Состояние ошибки
class GasStationsError extends GasStationsState {
  final String message;

  const GasStationsError(this.message);

  @override
  List<Object> get props => [message];
}










