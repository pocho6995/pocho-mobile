import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../services/api_client.dart';
import '../services/stations_service.dart';
import '../services/restaurants_service.dart';
import '../services/car_service_service.dart';
import '../services/car_wash_service.dart';
import '../services/charging_station_service.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';
import '../services/notification_websocket_service.dart';
import '../services/support_service.dart';
import '../services/support_websocket_service.dart';
import '../services/global_chat_service.dart';
import '../services/global_chat_websocket_service.dart';
import '../services/delivery_service.dart';
import '../services/token_storage.dart';
import '../repositories/auth_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/support_repository.dart';
import '../repositories/global_chat_repository.dart';
import '../repositories/delivery_repository.dart';
import '../state/app_state.dart';

// Gas Stations (Clean Architecture)
import '../data/datasources/gas_station_remote_datasource.dart';
import '../data/repositories/gas_station_repository_impl.dart';
import '../domain/repositories/gas_station_repository.dart';
import '../domain/usecases/gas_stations/get_gas_stations.dart';
import '../domain/usecases/gas_stations/get_gas_station_by_id.dart';
import '../domain/usecases/gas_stations/create_gas_station.dart';
import '../domain/usecases/gas_stations/update_fuel_prices.dart';
import '../domain/usecases/gas_stations/create_review.dart';
import '../presentation/bloc/gas_stations/gas_stations_bloc.dart';
import '../presentation/bloc/gas_station_detail/gas_station_detail_bloc.dart';

// Advertisements (Clean Architecture)
import '../data/datasources/advertisement_remote_datasource.dart';
import '../data/repositories/advertisement_repository_impl.dart';
import '../domain/repositories/advertisement_repository.dart';
import '../domain/usecases/advertisements/get_advertisements.dart';
import '../domain/usecases/advertisements/register_advertisement_view.dart';
import '../domain/usecases/advertisements/register_advertisement_click.dart';

final getIt = GetIt.instance;

/// Инициализация всех зависимостей приложения
Future<void> setupDependencies() async {
  // ========== Core Dependencies ==========
  
  // HTTP Client
  getIt.registerLazySingleton<http.Client>(() => http.Client());

  // Token Storage (нужен для ApiClient)
  getIt.registerLazySingleton<TokenStorage>(() => TokenStorage());

  // API Client
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(
      client: getIt<http.Client>(),
      tokenStorage: getIt<TokenStorage>(),
    ),
  );

  // ========== Services ==========
  
  // Stations Service
  getIt.registerLazySingleton<StationsService>(
    () => StationsService(apiClient: getIt<ApiClient>()),
  );

  // Restaurants Service
  getIt.registerLazySingleton<RestaurantsService>(
    () => RestaurantsService(apiClient: getIt<ApiClient>()),
  );

  // Car Service Service
  getIt.registerLazySingleton<CarServiceService>(
    () => CarServiceService(apiClient: getIt<ApiClient>()),
  );

  // Car Wash Service
  getIt.registerLazySingleton<CarWashService>(
    () => CarWashService(apiClient: getIt<ApiClient>()),
  );

  // Charging Station Service
  getIt.registerLazySingleton<ChargingStationService>(
    () => ChargingStationService(apiClient: getIt<ApiClient>()),
  );

  // Auth Service
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(apiClient: getIt<ApiClient>()),
  );

  // Profile Service
  getIt.registerLazySingleton<ProfileService>(
    () => ProfileService(apiClient: getIt<ApiClient>()),
  );

  // Notification Service
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(apiClient: getIt<ApiClient>()),
  );

  // Notification WebSocket Service
  getIt.registerLazySingleton<NotificationWebSocketService>(
    () => NotificationWebSocketService(tokenStorage: getIt<TokenStorage>()),
  );

  // Support Service
  getIt.registerLazySingleton<SupportService>(
    () => SupportService(apiClient: getIt<ApiClient>()),
  );

  // Support WebSocket Service
  getIt.registerLazySingleton<SupportWebSocketService>(
    () => SupportWebSocketService(tokenStorage: getIt<TokenStorage>()),
  );

  // Global Chat Service
  getIt.registerLazySingleton<GlobalChatService>(
    () => GlobalChatService(apiClient: getIt<ApiClient>()),
  );

  // Global Chat WebSocket Service
  getIt.registerLazySingleton<GlobalChatWebSocketService>(
    () => GlobalChatWebSocketService(tokenStorage: getIt<TokenStorage>()),
  );

  // Delivery Service
  getIt.registerLazySingleton<DeliveryService>(
    () => DeliveryService(apiClient: getIt<ApiClient>()),
  );

  // ========== Repositories ==========

  // Auth Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(authService: getIt<AuthService>()),
  );

  // Notification Repository
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(
      notificationService: getIt<NotificationService>(),
      webSocketService: getIt<NotificationWebSocketService>(),
    ),
  );

  // Support Repository
  getIt.registerLazySingleton<SupportRepository>(
    () => SupportRepository(
      supportService: getIt<SupportService>(),
      webSocketService: getIt<SupportWebSocketService>(),
    ),
  );

  // Global Chat Repository
  getIt.registerLazySingleton<GlobalChatRepository>(
    () => GlobalChatRepository(
      chatService: getIt<GlobalChatService>(),
      webSocketService: getIt<GlobalChatWebSocketService>(),
    ),
  );

  // Delivery Repository
  getIt.registerLazySingleton<DeliveryRepository>(
    () => DeliveryRepository(deliveryService: getIt<DeliveryService>()),
  );

  // ========== Gas Stations (Clean Architecture) ==========

  // Data Sources
  getIt.registerLazySingleton<GasStationRemoteDataSource>(
    () => GasStationRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );

  // Repository
  getIt.registerLazySingleton<GasStationRepository>(
    () => GasStationRepositoryImpl(
      remoteDataSource: getIt<GasStationRemoteDataSource>(),
    ),
  );

  // Use Cases
  getIt.registerLazySingleton<GetGasStations>(
    () => GetGasStations(getIt<GasStationRepository>()),
  );

  getIt.registerLazySingleton<GetGasStationById>(
    () => GetGasStationById(getIt<GasStationRepository>()),
  );

  getIt.registerLazySingleton<CreateGasStation>(
    () => CreateGasStation(getIt<GasStationRepository>()),
  );

  getIt.registerLazySingleton<UpdateFuelPrices>(
    () => UpdateFuelPrices(getIt<GasStationRepository>()),
  );

  getIt.registerLazySingleton<CreateReview>(
    () => CreateReview(getIt<GasStationRepository>()),
  );

  // BLoC (Factory - новый экземпляр для каждой страницы)
  getIt.registerFactory<GasStationsBloc>(
    () => GasStationsBloc(getGasStations: getIt<GetGasStations>()),
  );

  getIt.registerFactory<GasStationDetailBloc>(
    () => GasStationDetailBloc(
      getGasStationById: getIt<GetGasStationById>(),
      updateFuelPrices: getIt<UpdateFuelPrices>(),
      createReview: getIt<CreateReview>(),
      repository: getIt<GasStationRepository>(),
    ),
  );

  // ========== Advertisements (Clean Architecture) ==========

  // Data Sources
  getIt.registerLazySingleton<AdvertisementRemoteDataSource>(
    () => AdvertisementRemoteDataSourceImpl(apiClient: getIt<ApiClient>()),
  );

  // Repositories
  getIt.registerLazySingleton<AdvertisementRepository>(
    () => AdvertisementRepositoryImpl(
      remoteDataSource: getIt<AdvertisementRemoteDataSource>(),
    ),
  );

  // Use Cases
  getIt.registerLazySingleton<GetAdvertisements>(
    () => GetAdvertisements(repository: getIt<AdvertisementRepository>()),
  );

  getIt.registerLazySingleton<RegisterAdvertisementView>(
    () =>
        RegisterAdvertisementView(repository: getIt<AdvertisementRepository>()),
  );

  getIt.registerLazySingleton<RegisterAdvertisementClick>(
    () => RegisterAdvertisementClick(
      repository: getIt<AdvertisementRepository>(),
    ),
  );

  // ========== State Management ==========
  
  // App State
  getIt.registerLazySingleton<AppState>(() => AppState());

  // ========== Repositories (если будут) ==========
  // Пример:
  // getIt.registerLazySingleton<StationsRepository>(
  //   () => StationsRepositoryImpl(
  //     stationsService: getIt<StationsService>(),
  //   ),
  // );
}

/// Сброс всех зависимостей (полезно для тестирования)
Future<void> resetDependencies() async {
  await getIt.reset();
}
