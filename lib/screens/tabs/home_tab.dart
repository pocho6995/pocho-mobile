import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../domain/repositories/gas_station_repository.dart';
import '../../presentation/bloc/gas_stations/gas_stations_bloc.dart';
import '../../presentation/bloc/gas_stations/gas_stations_event.dart';
import '../../presentation/bloc/gas_stations/gas_stations_state.dart';
import '../../presentation/widgets/gas_station_card.dart';
import '../../state/app_state.dart';
import '../../utils/theme_utils.dart';
import '../../di/injection_container.dart' as di;
import '../../presentation/pages/gas_station_detail_page.dart';
import '../gas_stations_map_page.dart';
import '../../widgets/modern_bottom_sheet.dart';
import '../../widgets/dropdown_action_button.dart';
import '../../services/advertisement_service.dart';
import '../../services/stations_service.dart';
import '../../services/delivery_service.dart';
import '../../widgets/modern_snackbar.dart';
import '../../domain/entities/advertisement.dart';
import '../../presentation/widgets/advertisement_banner.dart';
import '../../presentation/widgets/advertisement_placeholder.dart';
import '../ai_assistant_page.dart';

/// HomeTab с использованием BLoC и реальных данных
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _promoPageController = PageController();
  VoidCallback? _searchListener;
  late final AdvertisementService _advertisementService;
  late final StationsService _stationsService;
  late final DeliveryService _deliveryService;
  List<AdvertisementEntity> _homeTopAds = [];
  List<AdvertisementEntity> _homeBottomAds = [];
  bool _isLoadingAds = false;
  bool _isDriver = false;
  bool _isCheckingDriver = true;
  final Map<int, bool> _favoriteStatuses = {}; // Кэш статусов избранного

  // Фильтры
  String? _selectedFuelType;
  double? _minRating;
  double? _maxPrice;
  bool? _is24_7;
  bool? _hasPromotions;

  // Рекламные баннеры (будут заполнены в build с учетом локализации)
  List<Map<String, dynamic>> _getPromoBanners(AppState appState) {
    return [
      {
        'title': appState.t('promo_discount_10'),
        'subtitle': appState.t('promo_until_weekend'),
        'icon': Icons.local_offer,
        'color': [0xFF1565C0, 0xFF42A5F5],
      },
      {
        'title': appState.t('promo_free_wash'),
        'subtitle': appState.t('promo_from_50_liters'),
        'icon': Icons.local_car_wash,
        'color': [0xFF4CAF50, 0xFF81C784],
      },
      {
        'title': appState.t('promo_bonus_points'),
        'subtitle': appState.t('promo_accumulate_exchange'),
        'icon': Icons.stars,
        'color': [0xFFFF9800, 0xFFFFB74D],
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    // Listener будет добавлен в Builder после создания BlocProvider
    _advertisementService = AdvertisementService();
    _stationsService = di.getIt<StationsService>();
    _deliveryService = di.getIt<DeliveryService>();
    _checkIfDriver();
    _loadAdvertisements();
  }

  Future<void> _checkIfDriver() async {
    try {
      await _deliveryService.getMyDriverProfile();
      if (mounted) {
        setState(() {
          _isDriver = true;
          _isCheckingDriver = false;
        });
      }
    } catch (e) {
      // Если ошибка 404 или другая - пользователь не водитель
      if (mounted) {
        setState(() {
          _isDriver = false;
          _isCheckingDriver = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(int stationId) async {
    final currentStatus = _favoriteStatuses[stationId] ?? false;

    // Оптимистичное обновление UI
    setState(() {
      _favoriteStatuses[stationId] = !currentStatus;
    });

    try {
      bool success;
      final appState = Provider.of<AppState>(context, listen: false);
      if (currentStatus) {
        success = await _stationsService.removeFromFavorites(stationId);
        if (success && mounted) {
          ModernSnackBar.showSuccess(
            context,
            message: appState.t('removed_from_favorites'),
          );
        }
      } else {
        success = await _stationsService.addToFavorites(stationId);
        if (success && mounted) {
          ModernSnackBar.showSuccess(
            context,
            message: appState.t('added_to_favorites'),
          );
        }
      }

      if (!success && mounted) {
        // Откатываем изменения при ошибке
        setState(() {
          _favoriteStatuses[stationId] = currentStatus;
        });
        ModernSnackBar.showError(
          context,
          message: appState.t('failed_to_change_favorite'),
        );
      }
    } catch (e) {
      // Откатываем изменения при ошибке
      if (mounted) {
        setState(() {
          _favoriteStatuses[stationId] = currentStatus;
        });
        final appState = Provider.of<AppState>(context, listen: false);
        ModernSnackBar.showError(
          context,
          message: appState.t('error_changing_favorite'),
        );
      }
    }
  }

  Future<void> _loadAdvertisements() async {
    setState(() {
      _isLoadingAds = true;
    });

    try {
      final topAds = await _advertisementService.getAdvertisementsForPosition(
        'home_top',
      );
      final bottomAds = await _advertisementService
          .getAdvertisementsForPosition('home_bottom');

      if (mounted) {
        setState(() {
          _homeTopAds = topAds;
          _homeBottomAds = bottomAds;
          _isLoadingAds = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAds = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_searchListener != null) {
      _searchController.removeListener(_searchListener!);
    }
    _searchController.dispose();
    _scrollController.dispose();
    _promoPageController.dispose();
    super.dispose();
  }

  void _loadInitialData(BuildContext context) {
    final filterParams = GasStationFilterParams(
      skip: 0,
      limit: 100,
      fuelType: _selectedFuelType,
      minRating: _minRating,
      maxPrice: _maxPrice,
      is24_7: _is24_7,
      hasPromotions: _hasPromotions,
      searchQuery: _searchController.text.isEmpty
          ? null
          : _searchController.text,
    );

    context.read<GasStationsBloc>().add(
      LoadGasStationsEvent(filterParams: filterParams),
    );
  }

  void _onSearchChanged(BuildContext context) {
    _applyFilters(context);
  }

  void _applyFilters(BuildContext context) {
    final filterParams = GasStationFilterParams(
      skip: 0,
      limit: 100,
      fuelType: _selectedFuelType,
      minRating: _minRating,
      maxPrice: _maxPrice,
      is24_7: _is24_7,
      hasPromotions: _hasPromotions,
      searchQuery: _searchController.text.isEmpty
          ? null
          : _searchController.text,
    );

    context.read<GasStationsBloc>().add(
      UpdateFiltersEvent(filterParams: filterParams),
    );
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedFuelType != null) count++;
    if (_minRating != null) count++;
    if (_maxPrice != null) count++;
    if (_is24_7 == true) count++;
    if (_hasPromotions == true) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return BlocProvider(
      create: (context) {
        final bloc = di.getIt<GasStationsBloc>();
        // Загружаем данные после создания провайдера
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Используем новый контекст из builder
        });
        return bloc;
      },
      child: Builder(
        builder: (blocContext) {
          // Добавляем listener для поиска с правильным контекстом
          // Удаляем старый listener, если он есть
          if (_searchListener != null) {
            _searchController.removeListener(_searchListener!);
          }
          _searchListener = () => _onSearchChanged(blocContext);
          _searchController.addListener(_searchListener!);

          // Загружаем данные при первом построении виджета
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _loadInitialData(blocContext);
            }
          });
          return SizedBox.expand(
            child: Stack(
              children: [
                Container(
                  color: getBackgroundColor(context),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Заголовок и поиск
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Заголовок с кнопкой действий
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child:
                                        Text(
                                              appState.t('stations_nearby'),
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w700,
                                                color: getTitleColor(context),
                                                letterSpacing: -0.5,
                                              ),
                                            )
                                            .animate()
                                            .fadeIn(duration: 400.ms)
                                            .slideY(begin: -0.2, end: 0),
                                  ),
                                  const SizedBox(width: 12),
                                  DropdownActionButton(
                                        onFiltersTap: () =>
                                            _showFiltersModal(blocContext),
                                        onMapTap: _showMap,
                                        onAiAssistantTap: () {
                                          Navigator.of(blocContext).pushNamed(
                                            AiAssistantPage.routeName,
                                          );
                                        },
                                        hideDelivery:
                                            _isDriver || _isCheckingDriver,
                                      )
                                      .animate()
                                      .fadeIn(duration: 400.ms, delay: 200.ms)
                                      .scale(delay: 200.ms),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Поле поиска
                              TextField(
                                controller: _searchController,
                                style: TextStyle(color: getTitleColor(context)),
                                decoration: InputDecoration(
                                  hintText: appState.t('search_stations_hint'),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xFF1565C0),
                                  ),
                                  hintStyle: TextStyle(
                                    color: getSecondaryTextColor(context),
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_searchController.text.isNotEmpty)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      InkWell(
                                        onTap: () =>
                                            _showFiltersModal(blocContext),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: _activeFiltersCount > 0
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color(0xFF1565C0),
                                                      Color(0xFF42A5F5),
                                                    ],
                                                  )
                                                : null,
                                            color: _activeFiltersCount > 0
                                                ? null
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.tune,
                                                size: 16,
                                                color: _activeFiltersCount > 0
                                                    ? Colors.white
                                                    : Colors.grey.shade600,
                                              ),
                                              if (_activeFiltersCount > 0) ...[
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$_activeFiltersCount',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  filled: true,
                                  fillColor: getCardColor(context),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Рекламные блоки сверху (из API)
                      if (_homeTopAds.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: Column(
                              children: _homeTopAds.asMap().entries.map((
                                entry,
                              ) {
                                final index = entry.key;
                                final ad = entry.value;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index < _homeTopAds.length - 1
                                        ? 12
                                        : 0,
                                  ),
                                  child:
                                      AdvertisementBanner(
                                            advertisement: ad,
                                            height: 120,
                                          )
                                          .animate()
                                          .fadeIn(
                                            duration: 400.ms,
                                            delay: (500 + index * 100).ms,
                                          )
                                          .scale(
                                            begin: const Offset(0.95, 0.95),
                                            delay: (500 + index * 100).ms,
                                          ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      // Placeholder для рекламы (если нет рекламы из API)
                      if (_homeTopAds.isEmpty && !_isLoadingAds)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: AdvertisementPlaceholder(height: 120)
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 500.ms)
                                .scale(begin: const Offset(0.95, 0.95)),
                          ),
                        ),
                      // Список станций
                      BlocBuilder<GasStationsBloc, GasStationsState>(
                        builder: (context, state) {
                          if (state is GasStationsLoading) {
                            return const SliverFillRemaining(
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1565C0),
                                ),
                              ),
                            );
                          } else if (state is GasStationsError) {
                            return SliverFillRemaining(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      state.message,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _loadInitialData(blocContext),
                                      child: Text(appState.t('retry')),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else if (state is GasStationsLoaded) {
                            if (state.stations.isEmpty) {
                              return SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.local_gas_station_outlined,
                                        size: 64,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        appState.t('no_stations_found'),
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return SliverPadding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                100,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final station = state.stations[index];
                                  final isLastStation =
                                      index == state.stations.length - 1;

                                  return Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: GasStationCard(
                                          station: station,
                                          index: index,
                                          isFavorite:
                                              _favoriteStatuses[station.id] ??
                                              false,
                                          onTap: () {
                                            // Переход на детальную страницу
                                            Navigator.of(context).pushNamed(
                                              GasStationDetailPage.routeName,
                                              arguments: station.id,
                                            );
                                          },
                                          onFavoriteTap: () =>
                                              _toggleFavorite(station.id),
                                        ),
                                      ),
                                      // Рекламные блоки снизу (после последней карточки)
                                      if (isLastStation)
                                        if (_homeBottomAds.isNotEmpty)
                                          ..._homeBottomAds.map((ad) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child:
                                                  AdvertisementBanner(
                                                        advertisement: ad,
                                                        height: 120,
                                                      )
                                                      .animate()
                                                      .fadeIn(
                                                        duration: 400.ms,
                                                        delay: 200.ms,
                                                      )
                                                      .scale(
                                                        begin: const Offset(
                                                          0.95,
                                                          0.95,
                                                        ),
                                                      ),
                                            );
                                          })
                                        else
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            child:
                                                AdvertisementPlaceholder(
                                                      height: 120,
                                                    )
                                                    .animate()
                                                    .fadeIn(
                                                      duration: 400.ms,
                                                      delay: 200.ms,
                                                    )
                                                    .scale(
                                                      begin: const Offset(
                                                        0.95,
                                                        0.95,
                                                      ),
                                                    ),
                                          ),
                                    ],
                                  );
                                }, childCount: state.stations.length),
                              ),
                            );
                          }

                          return const SliverToBoxAdapter(
                            child: SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMap() {
    Navigator.of(context).pushNamed(GasStationsMapPage.routeName);
  }

  void _showFiltersModal(BuildContext context) {
    // Сохраняем текущие значения фильтров для модального окна
    String? tempFuelType = _selectedFuelType;
    double? tempMinRating = _minRating;
    double? tempMaxPrice = _maxPrice;
    bool? tempIs24_7 = _is24_7;
    bool? tempHasPromotions = _hasPromotions;

    final appState = Provider.of<AppState>(context, listen: false);
    ModernBottomSheet.show(
      context: context,
      title: appState.t('filters'),
      showCloseButton: true,
      isScrollControlled: true,
      maxHeight: MediaQuery.of(context).size.height * 0.75,
      child: StatefulBuilder(
        builder: (modalContext, setModalState) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Тип топлива
                  Text(
                    appState.t('fuel_type'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          'AI-80',
                          'AI-91',
                          'AI-95',
                          'AI-98',
                          'Дизель',
                          'Газ',
                        ].map((fuelType) {
                          final isSelected = tempFuelType == fuelType;
                          return FilterChip(
                            label: Text(fuelType),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                tempFuelType = selected ? fuelType : null;
                              });
                            },
                            selectedColor: const Color(0xFF1565C0),
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Минимальный рейтинг
                  Text(
                    appState.t('min_rating'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [appState.t('all'), '3.0+', '3.5+', '4.0+', '4.5+'].map(
                          (rating) {
                            final ratingValue = rating == appState.t('all')
                                ? null
                                : double.tryParse(rating.replaceAll('+', ''));
                            final isSelected = tempMinRating == ratingValue;
                            return FilterChip(
                              label: Text(rating),
                              selected: isSelected,
                              onSelected: (selected) {
                                setModalState(() {
                                  tempMinRating = selected ? ratingValue : null;
                                });
                              },
                              selectedColor: const Color(0xFF1565C0),
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Максимальная цена
                  Text(
                    appState.t('max_price'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final allText = appState.t('all');
                      final priceOptions = [
                        {'label': allText, 'value': null},
                        {
                          'label': appState.t('price_up_to_10000'),
                          'value': 10000.0,
                        },
                        {
                          'label': appState.t('price_up_to_12000'),
                          'value': 12000.0,
                        },
                        {
                          'label': appState.t('price_up_to_15000'),
                          'value': 15000.0,
                        },
                        {
                          'label': appState.t('price_up_to_20000'),
                          'value': 20000.0,
                        },
                      ];
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: priceOptions.map((option) {
                          final price = option['label'] as String;
                          final priceValue = option['value'] as double?;
                          final isSelected = tempMaxPrice == priceValue;
                          return FilterChip(
                            label: Text(price),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                tempMaxPrice = selected ? priceValue : null;
                              });
                            },
                            selectedColor: const Color(0xFF1565C0),
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Дополнительные фильтры
                  Text(
                    appState.t('additional'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Круглосуточно
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      appState.t('open_24_7'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: tempIs24_7 == true,
                    onChanged: (value) {
                      setModalState(() {
                        tempIs24_7 = value == true ? true : null;
                      });
                    },
                    activeColor: const Color(0xFF1565C0),
                  ),
                  // Есть акции
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      appState.t('has_promotions'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: tempHasPromotions == true,
                    onChanged: (value) {
                      setModalState(() {
                        tempHasPromotions = value == true ? true : null;
                      });
                    },
                    activeColor: const Color(0xFF1565C0),
                  ),
                  const SizedBox(height: 32),
                  // Кнопки действий
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 8,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Сброс всех фильтров
                                setModalState(() {
                                  tempFuelType = null;
                                  tempMinRating = null;
                                  tempMaxPrice = null;
                                  tempIs24_7 = null;
                                  tempHasPromotions = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                'Сбросить',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                // Применяем фильтры
                                setState(() {
                                  _selectedFuelType = tempFuelType;
                                  _minRating = tempMinRating;
                                  _maxPrice = tempMaxPrice;
                                  _is24_7 = tempIs24_7;
                                  _hasPromotions = tempHasPromotions;
                                });
                                _applyFilters(context);
                                Navigator.pop(modalContext);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                appState.t('apply'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
