import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/charging_station.dart';
import '../services/charging_station_service.dart';
import '../di/injection_container.dart' as di;
import '../state/app_state.dart';
import '../widgets/modern_bottom_sheet.dart';
import 'charging_station_detail_page.dart';
import 'favorites_charging_stations_page.dart';
import 'main_shell.dart';
import 'widgets/category_bottom_sheet.dart';

class ChargingStationsPage extends StatefulWidget {
  const ChargingStationsPage({super.key});

  static const String routeName = '/charging-stations';

  @override
  State<ChargingStationsPage> createState() => _ChargingStationsPageState();
}

class _ChargingStationsPageState extends State<ChargingStationsPage> {
  late final ChargingStationService _chargingStationService;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  List<ChargingStation> _stations = [];
  List<ChargingStation> _filteredStations = [];

  String? _selectedConnectorType;
  String? _selectedPowerRange;
  double? _maxPrice;
  double? _minRating;
  bool _onlyAvailable = false;

  // Категории для фильтрации (используем ключи для сравнений)
  String _selectedFilterCategory = 'all';
  final List<String> _filterCategoryKeys = [
    'all',
    'nearby',
    'fast_charging',
    'available',
    '24_7',
    'premium',
  ];

  // Функции для получения переведенных списков
  List<String> _getFilterCategories(AppState appState) {
    return [
      appState.t('filter_all'),
      appState.t('filter_nearby'),
      appState.t('filter_fast_charging'),
      appState.t('filter_available'),
      appState.t('filter_24_7'),
      appState.t('filter_premium'),
    ];
  }

  List<Map<String, dynamic>> _getOtherCategories(AppState appState) {
    return [
      {
        'name': appState.t('category_restaurants'),
        'nameKey': 'restaurants',
        'icon': Icons.restaurant_rounded,
        'color': 0xFFEC4899,
        'route': 'restaurants',
      },
      {
        'name': appState.t('category_car_service'),
        'nameKey': 'car_service',
        'icon': Icons.build_rounded,
        'color': 0xFF10B981,
        'route': 'car_service',
      },
      {
        'name': appState.t('category_car_wash'),
        'nameKey': 'car_wash',
        'icon': Icons.local_car_wash_rounded,
        'color': 0xFF3B82F6,
        'route': 'car_wash',
      },
    ];
  }

  // Вспомогательная функция для проверки, является ли значение "Все"
  bool _isAllValue(String? value, AppState appState) {
    if (value == null) return true;
    return value == appState.t('filter_all');
  }

  final List<String> _connectorTypes = [
    'Все',
    'Type 2',
    'CCS',
    'CHAdeMO',
    'Tesla Supercharger',
  ];

  final List<String> _powerRanges = [
    'Все',
    'До 50 кВт',
    '50-100 кВт',
    '100-150 кВт',
    '150+ кВт',
  ];

  @override
  void initState() {
    super.initState();
    _chargingStationService = di.getIt<ChargingStationService>();
    _loadStations();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  int get _activeFiltersCount {
    int count = 0;
    if (_selectedConnectorType != null) count++;
    if (_selectedPowerRange != null) count++;
    if (_maxPrice != null) count++;
    if (_minRating != null) count++;
    if (_onlyAvailable) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedConnectorType = null;
      _selectedPowerRange = null;
      _maxPrice = null;
      _minRating = null;
      _onlyAvailable = false;
      _selectedFilterCategory = 'all';
      _searchController.clear();
    });
    _applyFilters();
  }

  void _showFiltersModal(BuildContext context) {
    String? tempConnectorType = _selectedConnectorType;
    String? tempPowerRange = _selectedPowerRange;
    double? tempMaxPrice = _maxPrice;
    double? tempMinRating = _minRating;
    bool tempOnlyAvailable = _onlyAvailable;

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
                  Text(
                    'Тип разъема',
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
                    children: _connectorTypes.map((connectorType) {
                      final isSelected =
                          tempConnectorType == connectorType ||
                          (tempConnectorType == null && connectorType == 'Все');
                      return FilterChip(
                        label: Text(connectorType),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            tempConnectorType = selected
                                ? (connectorType == 'Все'
                                      ? null
                                      : connectorType)
                                : null;
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
                  Text(
                    'Мощность',
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
                    children: _powerRanges.map((powerRange) {
                      final isSelected =
                          tempPowerRange == powerRange ||
                          (tempPowerRange == null && powerRange == 'Все');
                      return FilterChip(
                        label: Text(
                          powerRange == 'Все' ? 'Все мощности' : powerRange,
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            tempPowerRange = selected
                                ? (powerRange == 'Все' ? null : powerRange)
                                : null;
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
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Только доступные',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: tempOnlyAvailable,
                    onChanged: (value) {
                      setModalState(() {
                        tempOnlyAvailable = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF1565C0),
                  ),
                  const SizedBox(height: 32),
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
                                setModalState(() {
                                  tempConnectorType = null;
                                  tempPowerRange = null;
                                  tempMaxPrice = null;
                                  tempMinRating = null;
                                  tempOnlyAvailable = false;
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
                                appState.t('reset'),
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
                                setState(() {
                                  _selectedConnectorType = tempConnectorType;
                                  _selectedPowerRange = tempPowerRange;
                                  _maxPrice = tempMaxPrice;
                                  _minRating = tempMinRating;
                                  _onlyAvailable = tempOnlyAvailable;
                                });
                                Navigator.of(context).pop();
                                _applyFilters();
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                backgroundColor: const Color(0xFF1565C0),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                appState.t('apply'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
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

  Future<void> _loadStations() async {
    setState(() => _isLoading = true);
    try {
      // Загружаем данные только с сервера
      final response = await _chargingStationService.getChargingStations(
        skip: 0,
        limit: 100,
        connectorType:
            _selectedConnectorType != null && _selectedConnectorType != 'Все'
            ? _selectedConnectorType
            : null,
        minRating: _minRating,
        maxPricePerKwh: _maxPrice,
        searchQuery: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        hasAvailablePoints: _onlyAvailable ? true : null,
        is24_7: _selectedFilterCategory == '24_7' ? true : null,
      );

      // Проверяем статус избранного для каждой электрозаправки
      for (final station in response.stations) {
        if (!station.isFavorite) {
          try {
            final isFavorite = await _chargingStationService.checkIsFavorite(
              station.id,
            );
            station.isFavorite = isFavorite;
          } catch (e) {
            // Игнорируем ошибки проверки
          }
        }
      }

      setState(() {
        _stations = response.stations;
        _filteredStations = _stations;
        _isLoading = false;
      });
    } catch (e) {
      // При ошибке показываем пустой список
      if (mounted) {
        setState(() {
          _stations = [];
          _filteredStations = [];
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredStations = _stations.where((station) {
        // Поиск
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          if (!station.name.toLowerCase().contains(searchQuery) &&
              !station.address.toLowerCase().contains(searchQuery) &&
              !station.connectorTypes.any(
                (s) => s.toLowerCase().contains(searchQuery),
              )) {
            return false;
          }
        }

        // Фильтр по типу разъема
        if (_selectedConnectorType != null && _selectedConnectorType != 'Все') {
          if (!station.connectorTypes.contains(_selectedConnectorType)) {
            return false;
          }
        }

        // Фильтр по мощности
        if (_selectedPowerRange != null && _selectedPowerRange != 'Все') {
          final powerValue =
              int.tryParse(station.power.replaceAll(RegExp(r'[^0-9]'), '')) ??
              0;
          if (_selectedPowerRange == 'До 50 кВт' && powerValue >= 50)
            return false;
          if (_selectedPowerRange == '50-100 кВт' &&
              (powerValue < 50 || powerValue >= 100))
            return false;
          if (_selectedPowerRange == '100-150 кВт' &&
              (powerValue < 100 || powerValue >= 150))
            return false;
          if (_selectedPowerRange == '150+ кВт' && powerValue < 150)
            return false;
        }

        // Фильтр по максимальной цене
        if (_maxPrice != null) {
          if (station.pricePerKwh > _maxPrice!) {
            return false;
          }
        }

        // Фильтр по рейтингу
        if (_minRating != null) {
          if (station.rating < _minRating!) {
            return false;
          }
        }

        // Фильтр по доступности
        if (_onlyAvailable) {
          if (!station.isAvailable ||
              (station.availableConnectors != null &&
                  station.availableConnectors == 0)) {
            return false;
          }
        }

        // Фильтр по категории фильтра
        if (_selectedFilterCategory == 'nearby') {
          if (station.distance == null || station.distance! > 2.0) {
            return false;
          }
        } else if (_selectedFilterCategory == 'fast_charging') {
          final powerValue =
              int.tryParse(station.power.replaceAll(RegExp(r'[^0-9]'), '')) ??
              0;
          if (powerValue < 100) return false;
        } else if (_selectedFilterCategory == 'available') {
          if (!station.isAvailable ||
              (station.availableConnectors != null &&
                  station.availableConnectors == 0)) {
            return false;
          }
        } else if (_selectedFilterCategory == '24_7') {
          if (station.workingHours != '24/7') return false;
        } else if (_selectedFilterCategory == 'premium') {
          if (station.pricePerKwh < 2.5) return false;
        }

        return true;
      }).toList();
    });
  }

  Future<void> _toggleFavorite(ChargingStation station) async {
    final currentStatus = station.isFavorite;

    // Оптимистичное обновление UI
    setState(() {
      station.isFavorite = !currentStatus;
    });

    try {
      bool success;
      if (currentStatus) {
        success = await _chargingStationService.removeFromFavorites(station.id);
      } else {
        success = await _chargingStationService.addToFavorites(station.id);
      }

      if (!success && mounted) {
        // Откатываем изменения при ошибке
        setState(() {
          station.isFavorite = currentStatus;
        });
      }
    } catch (e) {
      // Откатываем изменения при ошибке
      if (mounted) {
        setState(() {
          station.isFavorite = currentStatus;
        });
      }
    }
  }

  void _handleCategoriesTap() {
    final appState = Provider.of<AppState>(context, listen: false);
    final otherCategories = _getOtherCategories(appState);
    showBottomCategoryMenu(
      context,
      otherCategories,
      '', // Нет выбранной категории, так как мы на странице электрозаправок
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // SliverAppBar с градиентом
          SliverAppBar(
            expandedHeight: isSmallScreen ? 200 : 240,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF8B5CF6),
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFFA78BFA),
                      Color(0xFFC4B5FD),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isSmallScreen ? 16 : 20,
                      isSmallScreen ? 12 : 16,
                      isSmallScreen ? 16 : 20,
                      isSmallScreen ? 16 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.favorite_border_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    FavoritesChargingStationsPage.routeName,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Builder(
                              builder: (context) {
                                final appState = Provider.of<AppState>(
                                  context,
                                  listen: false,
                                );
                                return Text(
                                  appState.t('category_charging_stations'),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 28 : 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                    height: 1.1,
                                  ),
                                );
                              },
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideX(begin: -0.2, end: 0),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        // Поисковая строка
                        Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Builder(
                                builder: (context) {
                                  final appState = Provider.of<AppState>(
                                    context,
                                    listen: false,
                                  );
                                  return TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: appState.t(
                                        'search_charging_stations',
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.search_rounded,
                                        color: Color(0xFF8B5CF6),
                                      ),
                                      suffixIcon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_searchController.text.isNotEmpty)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.clear_rounded,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                              },
                                            ),
                                          Stack(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.tune_rounded,
                                                  color: Color(0xFF8B5CF6),
                                                ),
                                                onPressed: () {
                                                  _showFiltersModal(context);
                                                },
                                              ),
                                              if (_activeFiltersCount > 0)
                                                Positioned(
                                                  right: 8,
                                                  top: 8,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Color(
                                                            0xFFEF4444,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: Text(
                                                      '$_activeFiltersCount',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 16 : 20,
                                        vertical: isSmallScreen ? 14 : 16,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 200.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Активные фильтры
          if (_activeFiltersCount > 0)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.only(
                  left: isSmallScreen ? 16 : 20,
                  top: 12,
                  right: isSmallScreen ? 16 : 20,
                  bottom: 8,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_selectedConnectorType != null)
                      _ActiveFilterChip(
                        label: _selectedConnectorType!,
                        onRemove: () {
                          setState(() {
                            _selectedConnectorType = null;
                          });
                          _applyFilters();
                        },
                      ),
                    if (_selectedPowerRange != null)
                      _ActiveFilterChip(
                        label: _selectedPowerRange!,
                        onRemove: () {
                          setState(() {
                            _selectedPowerRange = null;
                          });
                          _applyFilters();
                        },
                      ),
                    if (_maxPrice != null)
                      _ActiveFilterChip(
                        label: 'До ${_maxPrice!.toStringAsFixed(1)} ₽/кВт·ч',
                        onRemove: () {
                          setState(() {
                            _maxPrice = null;
                          });
                          _applyFilters();
                        },
                      ),
                    if (_minRating != null)
                      _ActiveFilterChip(
                        label: 'Рейтинг ${_minRating!.toStringAsFixed(1)}+',
                        onRemove: () {
                          setState(() {
                            _minRating = null;
                          });
                          _applyFilters();
                        },
                      ),
                    if (_onlyAvailable)
                      _ActiveFilterChip(
                        label: 'Только доступные',
                        onRemove: () {
                          setState(() {
                            _onlyAvailable = false;
                          });
                          _applyFilters();
                        },
                      ),
                    TextButton.icon(
                      onPressed: _clearAllFilters,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Сбросить'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5CF6),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Категории фильтров
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.only(top: 12, bottom: 16),
              child: SizedBox(
                height: 56,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 20,
                  ),
                  itemCount: _filterCategoryKeys.length,
                  itemBuilder: (context, index) {
                    final appState = Provider.of<AppState>(
                      context,
                      listen: false,
                    );
                    final categories = _getFilterCategories(appState);
                    final categoryKey = _filterCategoryKeys[index];
                    final category = categories[index];
                    final isSelected = categoryKey == _selectedFilterCategory;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index < _filterCategoryKeys.length - 1 ? 12 : 0,
                      ),
                      child: _CategoryChip(
                        label: category,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedFilterCategory = categoryKey;
                          });
                          _applyFilters();
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Список станций
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                ),
              ),
            )
          else if (_filteredStations.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.ev_station_rounded,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Станции не найдены',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Попробуйте изменить фильтры',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: 16,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final station = _filteredStations[index];
                  return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < _filteredStations.length - 1 ? 16 : 0,
                        ),
                        child: _ModernChargingStationCard(
                          station: station,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChargingStationDetailPage(station: station),
                              ),
                            );
                          },
                          onFavoriteTap: () => _toggleFavorite(station),
                          isSmallScreen: isSmallScreen,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                      .slideY(begin: 0.2, end: 0, delay: (index * 50).ms);
                }, childCount: _filteredStations.length),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 6,
              bottom: 6,
            ),
            child: Builder(
              builder: (context) {
                final appState = Provider.of<AppState>(context, listen: false);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ModernNavItem(
                      icon: Icons.home_rounded,
                      label: appState.t('home'),
                      isSelected: false,
                      onTap: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          MainShell.routeName,
                          (route) => false,
                        );
                      },
                    ),
                    _ModernNavItem(
                      icon: Icons.category_rounded,
                      label: appState.t('categories'),
                      isSelected: false,
                      onTap: _handleCategoriesTap,
                    ),
                    _ModernNavItem(
                      icon: Icons.favorite_rounded,
                      label: appState.t('favorites'),
                      isSelected: false,
                      gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(FavoritesChargingStationsPage.routeName);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Виджеты для страницы электрозаправок

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernChargingStationCard extends StatelessWidget {
  const _ModernChargingStationCard({
    required this.station,
    required this.onTap,
    required this.onFavoriteTap,
    required this.isSmallScreen,
  });

  final ChargingStation station;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool isSmallScreen;

  IconData _getConnectorIcon(String connectorType) {
    switch (connectorType) {
      case 'Type 2':
        return Icons.power_rounded;
      case 'CCS':
        return Icons.flash_on_rounded;
      case 'CHAdeMO':
        return Icons.bolt_rounded;
      case 'Tesla Supercharger':
        return Icons.electric_car_rounded;
      default:
        return Icons.ev_station_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final powerValue =
        int.tryParse(station.power.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final isFastCharging = powerValue >= 100;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: station.isAvailable
                  ? Colors.grey.shade100
                  : Colors.red.shade100,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Изображение с градиентным оверлеем
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Stack(
                      children: [
                        Image.network(
                          station.imageUrl,
                          width: double.infinity,
                          height: isSmallScreen ? 160 : 180,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: isSmallScreen ? 160 : 180,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.ev_station_rounded,
                                size: 60,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                        // Градиентный оверлей
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.4),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Статус доступности
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: station.isAvailable
                                  ? Colors.green.withOpacity(0.9)
                                  : Colors.red.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  station.isAvailable
                                      ? Icons.check_circle_rounded
                                      : Icons.close_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  station.isAvailable ? 'Доступна' : 'Занята',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Индикатор доступных разъемов
                        if (station.availableConnectors != null &&
                            station.totalConnectors != null)
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.power_rounded,
                                    size: 14,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${station.availableConnectors}/${station.totalConnectors}',
                                    style: const TextStyle(
                                      color: Color(0xFF111827),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Название и рейтинг
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    station.name,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 18 : 20,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF111827),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 6),
                                  Row(
                                    children: [
                                      ...List.generate(5, (index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            right: 2,
                                          ),
                                          child: Icon(
                                            index < station.rating.round()
                                                ? Icons.star_rounded
                                                : Icons.star_border_rounded,
                                            size: isSmallScreen ? 14 : 16,
                                            color: Colors.amber.shade700,
                                          ),
                                        );
                                      }),
                                      SizedBox(width: isSmallScreen ? 6 : 8),
                                      Text(
                                        '${station.rating.toStringAsFixed(1)} (${station.reviewCount})',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 13,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: onFavoriteTap,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: station.isFavorite
                                      ? const Color(0xFF8B5CF6).withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  station.isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size: isSmallScreen ? 20 : 22,
                                  color: station.isFavorite
                                      ? const Color(0xFF8B5CF6)
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        // Мощность зарядки (крупно)
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isFastCharging
                                  ? [
                                      const Color(0xFF8B5CF6),
                                      const Color(0xFFA78BFA),
                                    ]
                                  : [
                                      Colors.grey.shade300,
                                      Colors.grey.shade400,
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.bolt_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 12 : 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Мощность',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 12,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 2 : 4),
                                  Text(
                                    station.power,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 20 : 24,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Цена',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 12,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 2 : 4),
                                  Text(
                                    '${station.pricePerKwh.toStringAsFixed(1)} ₽/кВт·ч',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        // Типы разъемов
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: station.connectorTypes.map((connector) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF8B5CF6,
                                  ).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getConnectorIcon(connector),
                                    size: 14,
                                    color: const Color(0xFF8B5CF6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    connector,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF8B5CF6),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        // Адрес и расстояние
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: isSmallScreen ? 16 : 18,
                              color: Colors.grey.shade600,
                            ),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Expanded(
                              child: Text(
                                station.address,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (station.distance != null) ...[
                              SizedBox(width: isSmallScreen ? 8 : 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${station.distance!.toStringAsFixed(1)} км',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Часы работы
                        if (station.workingHours.isNotEmpty) ...[
                          SizedBox(height: isSmallScreen ? 8 : 10),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: isSmallScreen ? 16 : 18,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 8),
                              Text(
                                station.workingHours,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernNavItem extends StatelessWidget {
  const _ModernNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.gradient,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    final colors = gradient ?? [Colors.grey.shade400, Colors.grey.shade500];

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(colors: colors)
                        : null,
                    color: isSelected ? null : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: MediaQuery.of(context).size.width < 360 ? 18 : 20,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width < 360 ? 9 : 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF8B5CF6)
                        : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
