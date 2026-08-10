import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/repositories/gas_station_repository.dart';
import '../../../domain/usecases/gas_stations/get_gas_station_by_id.dart';
import '../../../domain/usecases/gas_stations/update_fuel_prices.dart';
import '../../../domain/usecases/gas_stations/create_review.dart';
import 'gas_station_detail_event.dart';
import 'gas_station_detail_state.dart';

/// BLoC для управления детальной страницей заправочной станции
class GasStationDetailBloc
    extends Bloc<GasStationDetailEvent, GasStationDetailState> {
  final GetGasStationById getGasStationById;
  final UpdateFuelPrices updateFuelPrices;
  final CreateReview createReview;
  final GasStationRepository repository;

  GasStationDetailBloc({
    required this.getGasStationById,
    required this.updateFuelPrices,
    required this.createReview,
    required this.repository,
  }) : super(const GasStationDetailInitial()) {
    on<LoadGasStationDetailEvent>(_onLoadGasStationDetail);
    on<UpdateFuelPricesEvent>(_onUpdateFuelPrices);
    on<CreateReviewEvent>(_onCreateReview);
    on<UpdateReviewEvent>(_onUpdateReview);
    on<DeleteReviewEvent>(_onDeleteReview);
    on<UploadPhotoEvent>(_onUploadPhoto);
    on<DeletePhotoEvent>(_onDeletePhoto);
    on<RefreshGasStationDetailEvent>(_onRefresh);
  }

  Future<void> _onLoadGasStationDetail(
    LoadGasStationDetailEvent event,
    Emitter<GasStationDetailState> emit,
  ) async {
    emit(const GasStationDetailLoading());
    final result = await getGasStationById(
      GetGasStationByIdParams(id: event.stationId),
    );

    result.fold(
      (failure) => emit(GasStationDetailError(_mapFailureToMessage(failure))),
      (station) => emit(GasStationDetailLoaded(station)),
    );
  }

  Future<void> _onUpdateFuelPrices(
    UpdateFuelPricesEvent event,
    Emitter<GasStationDetailState> emit,
  ) async {
    if (state is GasStationDetailLoaded) {
      final currentState = state as GasStationDetailLoaded;
      emit(GasStationDetailUpdatingPrices(currentState.station));

      final result = await updateFuelPrices(
        UpdateFuelPricesParams(
          gasStationId: event.stationId,
          fuelPrices: event.fuelPrices,
        ),
      );

      if (result.isLeft) {
        if (!emit.isDone) {
          emit(GasStationDetailError(_mapFailureToMessage(result.left!)));
          emit(GasStationDetailLoaded(currentState.station));
        }
      } else {
        // Обновляем станцию после успешного обновления цен
        final refreshResult = await getGasStationById(
          GetGasStationByIdParams(id: event.stationId),
        );
        if (!emit.isDone) {
          refreshResult.fold(
            (failure) => emit(GasStationDetailLoaded(currentState.station)),
            (updatedStation) => emit(GasStationDetailLoaded(updatedStation)),
          );
        }
      }
    }
  }

  Future<void> _onCreateReview(
    CreateReviewEvent event,
    Emitter<GasStationDetailState> emit,
  ) async {
    if (state is GasStationDetailLoaded) {
      final currentState = state as GasStationDetailLoaded;
      emit(GasStationDetailCreatingReview(currentState.station));

      final result = await createReview(
        CreateReviewParams(
          gasStationId: event.stationId,
          rating: event.rating,
          comment: event.comment,
        ),
      );

      if (result.isLeft) {
        if (!emit.isDone) {
          emit(GasStationDetailError(_mapFailureToMessage(result.left!)));
          emit(GasStationDetailLoaded(currentState.station));
        }
      } else {
        // Обновляем станцию после успешного создания отзыва
        final refreshResult = await getGasStationById(
          GetGasStationByIdParams(id: event.stationId),
        );
        if (!emit.isDone) {
          refreshResult.fold(
            (failure) => emit(GasStationDetailLoaded(currentState.station)),
            (updatedStation) => emit(GasStationDetailLoaded(updatedStation)),
          );
        }
      }
    }
  }

  Future<void> _onUpdateReview(
    UpdateReviewEvent event,
    Emitter<GasStationDetailState> emit,
  ) async {
    if (state is GasStationDetailLoaded) {
      final currentState = state as GasStationDetailLoaded;

      final result = await repository.updateReview(
        event.stationId,
        event.reviewId,
        event.rating,
        event.comment,
      );

      if (result.isLeft) {
        if (!emit.isDone) {
          emit(GasStationDetailError(_mapFailureToMessage(result.left!)));
        }
      } else {
        // Обновляем станцию после успешного обновления отзыва
        final refreshResult = await getGasStationById(
          GetGasStationByIdParams(id: event.stationId),
        );
        if (!emit.isDone) {
          refreshResult.fold(
            (failure) => emit(GasStationDetailLoaded(currentState.station)),
            (updatedStation) => emit(GasStationDetailLoaded(updatedStation)),
          );
        }
      }
    }
  }

  Future<void> _onDeleteReview(
    DeleteReviewEvent event,
    Emitter<GasStationDetailState> emit,
  ) async {
    if (state is GasStationDetailLoaded) {
      final currentState = state as GasStationDetailLoaded;

      final result = await repository.deleteReview(
        event.stationId,
        event.reviewId,
      );

      if (result.isLeft) {
        if (!emit.isDone) {
          emit(GasStationDetailError(_mapFailureToMessage(result.left!)));
        }
      } else {
        // Обновляем станцию после успешного удаления отзыва
        final refreshResult = await getGasStationById(
          GetGasStationByIdParams(id: event.stationId),
        );
        if (!emit.isDone) {
          refreshResult.fold(
            (failure) => emit(GasStationDetailLoaded(currentState.station)),
            (updatedStation) => emit(GasStationDetailLoaded(updatedStation)),
          );
        }
      }
    }
  }

  Future<void> _onUploadPhoto(
    UploadPhotoEvent event,
    Emitter<GasStationDetailState> emit,
  ) async {
    if (state is GasStationDetailLoaded) {
      final currentState = state as GasStationDetailLoaded;
      emit(GasStationDetailUploadingPhoto(currentState.station));

      final result = await repository.uploadPhoto(
        event.stationId,
        event.filePath,
        isMain: event.isMain,
        order: event.order,
      );

      if (result.isLeft) {
        if (!emit.isDone) {
          emit(GasStationDetailError(_mapFailureToMessage(result.left!)));
          emit(GasStationDetailLoaded(currentState.station));
        }
      } else {
        // Обновляем станцию после успешной загрузки фотографии
        final refreshResult = await getGasStationById(
          GetGasStationByIdParams(id: event.stationId),
        );
        if (!emit.isDone) {
          refreshResult.fold(
            (failure) => emit(GasStationDetailLoaded(currentState.station)),
            (updatedStation) => emit(GasStationDetailLoaded(updatedStation)),
          );
        }
      }
    }
  }

  Future<void> _onDeletePhoto(
    DeletePhotoEvent event,
    Emitter<GasStationDetailState> emit,
  ) async {
    if (state is GasStationDetailLoaded) {
      final currentState = state as GasStationDetailLoaded;

      final result = await repository.deletePhoto(
        event.stationId,
        event.photoId,
      );

      if (result.isLeft) {
        if (!emit.isDone) {
          emit(GasStationDetailError(_mapFailureToMessage(result.left!)));
        }
      } else {
        // Обновляем станцию после успешного удаления фотографии
        final refreshResult = await getGasStationById(
          GetGasStationByIdParams(id: event.stationId),
        );
        if (!emit.isDone) {
          refreshResult.fold(
            (failure) => emit(GasStationDetailLoaded(currentState.station)),
            (updatedStation) => emit(GasStationDetailLoaded(updatedStation)),
          );
        }
      }
    }
  }

  Future<void> _onRefresh(
    RefreshGasStationDetailEvent event,
    Emitter<GasStationDetailState> emit,
  ) async {
    add(LoadGasStationDetailEvent(event.stationId));
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return failure.message;
      case NetworkFailure:
        return 'Ошибка сети. Проверьте подключение к интернету.';
      case ValidationFailure:
        return failure.message;
      default:
        return 'Произошла ошибка. Попробуйте еще раз.';
    }
  }
}
