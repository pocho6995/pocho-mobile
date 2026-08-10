import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/repositories/gas_station_repository.dart';
import '../../../domain/usecases/gas_stations/get_gas_stations.dart';
import 'gas_stations_event.dart';
import 'gas_stations_state.dart';

/// BLoC для управления списком заправочных станций
class GasStationsBloc extends Bloc<GasStationsEvent, GasStationsState> {
  final GetGasStations getGasStations;

  GasStationsBloc({required this.getGasStations})
      : super(const GasStationsInitial()) {
    on<LoadGasStationsEvent>(_onLoadGasStations);
    on<UpdateFiltersEvent>(_onUpdateFilters);
    on<LoadMoreGasStationsEvent>(_onLoadMore);
    on<RefreshGasStationsEvent>(_onRefresh);
  }

  Future<void> _onLoadGasStations(
    LoadGasStationsEvent event,
    Emitter<GasStationsState> emit,
  ) async {
    emit(const GasStationsLoading());
    final result = await getGasStations(
      GetGasStationsParams(filterParams: event.filterParams),
    );

    result.fold(
      (failure) => emit(GasStationsError(_mapFailureToMessage(failure))),
      (stations) {
        final hasMore = stations.length >= event.filterParams.limit;
        emit(GasStationsLoaded(
          stations: stations,
          filterParams: event.filterParams,
          total: stations.length, // TODO: Получить total из ответа API
          hasMore: hasMore,
        ));
      },
    );
  }

  Future<void> _onUpdateFilters(
    UpdateFiltersEvent event,
    Emitter<GasStationsState> emit,
  ) async {
    // Сбрасываем фильтры и загружаем заново
    add(LoadGasStationsEvent(filterParams: event.filterParams));
  }

  Future<void> _onLoadMore(
    LoadMoreGasStationsEvent event,
    Emitter<GasStationsState> emit,
  ) async {
    if (state is GasStationsLoaded) {
      final currentState = state as GasStationsLoaded;
      if (currentState.isLoadingMore || !currentState.hasMore) {
        return;
      }

      emit(currentState.copyWith(isLoadingMore: true));

      final nextParams = GasStationFilterParams(
        skip: currentState.stations.length,
        limit: currentState.filterParams.limit,
        fuelType: currentState.filterParams.fuelType,
        minRating: currentState.filterParams.minRating,
        maxPrice: currentState.filterParams.maxPrice,
        is24_7: currentState.filterParams.is24_7,
        hasPromotions: currentState.filterParams.hasPromotions,
        searchQuery: currentState.filterParams.searchQuery,
        latitude: currentState.filterParams.latitude,
        longitude: currentState.filterParams.longitude,
        radiusKm: currentState.filterParams.radiusKm,
        status: currentState.filterParams.status,
      );

      final result = await getGasStations(
        GetGasStationsParams(filterParams: nextParams),
      );

      result.fold(
        (failure) {
          emit(currentState.copyWith(isLoadingMore: false));
          emit(GasStationsError(_mapFailureToMessage(failure)));
        },
        (newStations) {
          final allStations = [...currentState.stations, ...newStations];
          final hasMore = newStations.length >= nextParams.limit;
          emit(GasStationsLoaded(
            stations: allStations,
            filterParams: currentState.filterParams,
            total: currentState.total + newStations.length,
            hasMore: hasMore,
            isLoadingMore: false,
          ));
        },
      );
    }
  }

  Future<void> _onRefresh(
    RefreshGasStationsEvent event,
    Emitter<GasStationsState> emit,
  ) async {
    if (state is GasStationsLoaded) {
      final currentState = state as GasStationsLoaded;
      final refreshParams = GasStationFilterParams(
        skip: 0,
        limit: currentState.filterParams.limit,
        fuelType: currentState.filterParams.fuelType,
        minRating: currentState.filterParams.minRating,
        maxPrice: currentState.filterParams.maxPrice,
        is24_7: currentState.filterParams.is24_7,
        hasPromotions: currentState.filterParams.hasPromotions,
        searchQuery: currentState.filterParams.searchQuery,
        latitude: currentState.filterParams.latitude,
        longitude: currentState.filterParams.longitude,
        radiusKm: currentState.filterParams.radiusKm,
        status: currentState.filterParams.status,
      );
      add(LoadGasStationsEvent(filterParams: refreshParams));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return failure.message;
      case NetworkFailure:
        return 'Ошибка сети. Проверьте подключение к интернету.';
      default:
        return 'Произошла ошибка. Попробуйте еще раз.';
    }
  }
}

