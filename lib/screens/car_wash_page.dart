import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/car_wash.dart';
import '../services/car_wash_service.dart';
import '../di/injection_container.dart' as di;
import '../state/app_state.dart';
import '../widgets/modern_bottom_sheet.dart';
import 'car_service_page.dart';
import 'charging_stations_page.dart';
import 'favorites_car_wash_page.dart';
import 'main_shell.dart';
import 'car_wash_detail_page.dart';
import 'restaurants_page.dart';
import 'widgets/category_bottom_sheet.dart';

class CarWashPage extends StatefulWidget {
  const CarWashPage({super.key});

  static const String routeName = '/car-wash';

  @override
  State<CarWashPage> createState() => _CarWashPageState();
}

class _CarWashPageState extends State<CarWashPage> {
  late final CarWashService _carWashService;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  List<CarWash> _carWashes = [];
  List<CarWash> _filteredCarWashes = [];

  String? _selectedPriceRange;
  String? _selectedWashType;
  double? _minRating;

  // Категории для фильтрации автомоек (используем ключи для сравнений)
  String _selectedFilterCategory = 'all';
  final List<String> _filterCategoryKeys = [
    'all',
    'nearby',
    'with_promotions',
    'high_rating',
    'with_parking',
    'with_wifi',
  ];

  // Функции для получения переведенных списков
  List<String> _getFilterCategories(AppState appState) {
    return [
      appState.t('filter_all'),
      appState.t('filter_nearby'),
      appState.t('filter_with_promotions'),
      appState.t('filter_high_rating'),
      appState.t('filter_with_parking'),
      appState.t('filter_with_wifi'),
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
        'name': appState.t('category_charging_stations'),
        'nameKey': 'charging',
        'icon': Icons.ev_station_rounded,
        'color': 0xFF8B5CF6,
        'route': 'charging',
      },
    ];
  }

  final List<String> _priceRangeKeys = [
    'all',
    'economy',
    'standard',
    'premium',
  ];

  List<String> _getPriceRanges(AppState appState) {
    return [
      appState.t('filter_all'),
      appState.t('price_economy'),
      appState.t('price_standard'),
      appState.t('filter_premium'),
    ];
  }

  // Вспомогательная функция для проверки, является ли значение "Все"
  bool _isAllValue(String? value, AppState appState) {
    if (value == null) return true;
    return value == appState.t('filter_all');
  }

  // Вспомогательная функция для преобразования между ключами и значениями
  String? _getPriceRangeKeyByValue(String? value, AppState appState) {
    if (value == null) return 'all';
    final priceRanges = _getPriceRanges(appState);
    final index = priceRanges.indexOf(value);
    return index >= 0 ? _priceRangeKeys[index] : null;
  }

  final List<String> _washTypes = [
    'Все',
    'Ручная мойка',
    'Автоматическая мойка',
    'Полировка',
    'Химчистка',
    'Воск',
    'Керамическое покрытие',
  ];

  @override
  void initState() {
    super.initState();
    _carWashService = di.getIt<CarWashService>();
    _loadCarWashes();
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
    if (_selectedPriceRange != null) count++;
    if (_selectedWashType != null) count++;
    if (_minRating != null) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedPriceRange = null;
      _selectedWashType = null;
      _minRating = null;
      _selectedFilterCategory = 'all';
      _searchController.clear();
    });
    _applyFilters();
  }

  void _showFiltersModal(BuildContext context) {
    String? tempPriceRange = _selectedPriceRange;
    String? tempWashType = _selectedWashType;
    double? tempMinRating = _minRating;
    String tempFilterCategory = _selectedFilterCategory;

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
                    'Тип мойки',
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
                    children: _washTypes.map((washType) {
                      final isSelected =
                          tempWashType == washType ||
                          (tempWashType == null && washType == 'Все');
                      return FilterChip(
                        label: Text(washType),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            tempWashType = selected
                                ? (washType == 'Все' ? null : washType)
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
                    'Ценовой диапазон',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final modalAppState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      final priceRanges = _getPriceRanges(modalAppState);
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: priceRanges.asMap().entries.map((entry) {
                          final index = entry.key;
                          final priceRange = entry.value;
                          final priceRangeKey = _priceRangeKeys[index];
                          final isSelected =
                              (tempPriceRange == null &&
                                  priceRangeKey == 'all') ||
                              (tempPriceRange != null &&
                                  _getPriceRangeKeyByValue(
                                        tempPriceRange,
                                        modalAppState,
                                      ) ==
                                      priceRangeKey);
                          return FilterChip(
                            label: Text(
                              priceRangeKey == 'all'
                                  ? modalAppState.t('price_all_prices')
                                  : priceRange,
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setModalState(() {
                                tempPriceRange = selected
                                    ? (priceRangeKey == 'all'
                                          ? null
                                          : priceRange)
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
                      );
                    },
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
                                  tempPriceRange = null;
                                  tempWashType = null;
                                  tempMinRating = null;
                                  tempFilterCategory = 'Все';
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
                                  _selectedPriceRange = tempPriceRange;
                                  _selectedWashType = tempWashType;
                                  _minRating = tempMinRating;
                                  _selectedFilterCategory = tempFilterCategory;
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

  Future<void> _loadCarWashes() async {
    setState(() => _isLoading = true);
    try {
      // Загружаем данные только с сервера
      final response = await _carWashService.getCarWashes(
        skip: 0,
        limit: 100,
        serviceType: _selectedWashType != null && _selectedWashType != 'Все'
            ? _selectedWashType
            : null,
        minRating: _minRating,
        searchQuery: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        hasParking: _selectedFilterCategory == 'with_parking' ? true : null,
        hasVacuum: _selectedFilterCategory == 'with_vacuum' ? true : null,
      );

      // Проверяем статус избранного для каждой автомойки
      for (final carWash in response.carWashes) {
        if (!carWash.isFavorite) {
          try {
            final isFavorite = await _carWashService.checkIsFavorite(
              carWash.id,
            );
            carWash.isFavorite = isFavorite;
          } catch (e) {
            // Игнорируем ошибки проверки
          }
        }
      }

      setState(() {
        _carWashes = response.carWashes;
        _filteredCarWashes = _carWashes;
        _isLoading = false;
      });
    } catch (e) {
      // При ошибке показываем пустой список
      if (mounted) {
        setState(() {
          _carWashes = [];
          _filteredCarWashes = [];
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredCarWashes = _carWashes.where((carWash) {
        // Поиск
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          if (!carWash.name.toLowerCase().contains(searchQuery) &&
              !carWash.address.toLowerCase().contains(searchQuery) &&
              !carWash.washTypes.any(
                (s) => s.toLowerCase().contains(searchQuery),
              )) {
            return false;
          }
        }

        // Фильтр по ценовому диапазону
        if (_selectedPriceRange != null && _selectedPriceRange != 'Все') {
          if (carWash.priceRange != _selectedPriceRange) {
            return false;
          }
        }

        // Фильтр по типу мойки
        if (_selectedWashType != null && _selectedWashType != 'Все') {
          if (!carWash.washTypes.contains(_selectedWashType)) {
            return false;
          }
        }

        // Фильтр по рейтингу
        if (_minRating != null) {
          if (carWash.rating < _minRating!) {
            return false;
          }
        }

        // Фильтр по категории фильтра
        if (_selectedFilterCategory == 'nearby') {
          if (carWash.distance == null || carWash.distance! > 2.0) {
            return false;
          }
        } else if (_selectedFilterCategory == 'high_rating') {
          if (carWash.rating < 4.5) {
            return false;
          }
        } else if (_selectedFilterCategory == 'with_parking') {
          if (!carWash.features.contains('Парковка')) {
            return false;
          }
        } else if (_selectedFilterCategory == 'with_wifi') {
          if (!carWash.features.contains('Wi-Fi')) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _toggleFavorite(CarWash carWash) async {
    final currentStatus = carWash.isFavorite;

    // Оптимистичное обновление UI
    setState(() {
      carWash.isFavorite = !currentStatus;
    });

    try {
      bool success;
      if (currentStatus) {
        success = await _carWashService.removeFromFavorites(carWash.id);
      } else {
        success = await _carWashService.addToFavorites(carWash.id);
      }

      if (!success && mounted) {
        // Откатываем изменения при ошибке
        setState(() {
          carWash.isFavorite = currentStatus;
        });
      }
    } catch (e) {
      // Откатываем изменения при ошибке
      if (mounted) {
        setState(() {
          carWash.isFavorite = currentStatus;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 8,
              bottom: 8,
            ),
            child: Builder(
              builder: (context) {
                final appState = Provider.of<AppState>(context, listen: false);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ModernNavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
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
                      icon: Icons.apps_outlined,
                      selectedIcon: Icons.apps_rounded,
                      label: appState.t('categories'),
                      isSelected: false,
                      onTap: () => _handleCategoriesTap(context),
                    ),
                    _ModernNavItem(
                      icon: Icons.favorite_border_rounded,
                      selectedIcon: Icons.favorite_rounded,
                      label: appState.t('favorites'),
                      isSelected: false,
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed(FavoritesCarWashPage.routeName);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // SliverAppBar с поиском и фильтрами
          SliverAppBar(
            expandedHeight: isSmallScreen ? 240 : 260,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF60A5FA),
                      Color(0xFF2563EB),
                    ],
                    stops: [0.0, 0.5, 1.0],
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
                            Material(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child:
                                  Builder(
                                        builder: (context) {
                                          final appState =
                                              Provider.of<AppState>(
                                                context,
                                                listen: false,
                                              );
                                          return Text(
                                            appState.t('category_car_wash'),
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 26 : 30,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: -0.8,
                                              height: 1.2,
                                            ),
                                          );
                                        },
                                      )
                                      .animate()
                                      .fadeIn(duration: 400.ms)
                                      .slideX(
                                        begin: -0.3,
                                        end: 0,
                                        curve: Curves.easeOutCubic,
                                      ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Поле поиска с фильтрами
                        Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                    spreadRadius: 0,
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
                                    onChanged: (_) => setState(() {}),
                                    decoration: InputDecoration(
                                      hintText: appState.t('search_car_wash'),
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.search_rounded,
                                        color: Color(0xFF3B82F6),
                                        size: 24,
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
                                                setState(() {});
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          if (_searchController.text.isNotEmpty)
                                            Container(
                                              width: 1,
                                              height: 24,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              color: Colors.grey.shade300,
                                            ),
                                          InkWell(
                                            onTap: () {
                                              _showFiltersModal(context);
                                            },
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                gradient:
                                                    _activeFiltersCount > 0
                                                    ? const LinearGradient(
                                                        colors: [
                                                          Color(0xFF3B82F6),
                                                          Color(0xFF60A5FA),
                                                        ],
                                                      )
                                                    : null,
                                                color: _activeFiltersCount > 0
                                                    ? null
                                                    : Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: _activeFiltersCount > 0
                                                    ? null
                                                    : Border.all(
                                                        color: Colors
                                                            .grey
                                                            .shade300,
                                                        width: 1,
                                                      ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.tune,
                                                    size: 16,
                                                    color:
                                                        _activeFiltersCount > 0
                                                        ? Colors.white
                                                        : Colors.grey.shade700,
                                                  ),
                                                  if (_activeFiltersCount >
                                                      0) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 5,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.3),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '$_activeFiltersCount',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 16 : 20,
                                        vertical: isSmallScreen ? 14 : 18,
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 15 : 17,
                                      color: const Color(0xFF111827),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  );
                                },
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 200.ms)
                            .scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutCubic,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Активные фильтры и панель фильтров
          SliverToBoxAdapter(
            child:
                Container(
                      color: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Активные фильтры
                          if (_activeFiltersCount > 0) ...[
                            SizedBox(
                                  height: 36,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      if (_selectedPriceRange != null)
                                        _ActiveFilterChip(
                                          label: _selectedPriceRange!,
                                          onRemove: () {
                                            setState(() {
                                              _selectedPriceRange = null;
                                              _applyFilters();
                                            });
                                          },
                                        ),
                                      if (_selectedWashType != null)
                                        _ActiveFilterChip(
                                          label: _selectedWashType!,
                                          onRemove: () {
                                            setState(() {
                                              _selectedWashType = null;
                                              _applyFilters();
                                            });
                                          },
                                        ),
                                      if (_minRating != null)
                                        _ActiveFilterChip(
                                          label:
                                              '${_minRating!.toStringAsFixed(1)}+',
                                          onRemove: () {
                                            setState(() {
                                              _minRating = null;
                                              _applyFilters();
                                            });
                                          },
                                        ),
                                    ],
                                  ),
                                )
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .slideX(begin: -0.2, end: 0),
                          ],
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 300.ms)
                    .slideY(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
          ),
          // Слайдер категорий
          SliverToBoxAdapter(
            child:
                Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      height: 56,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filterCategoryKeys.length,
                        itemBuilder: (context, index) {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          final categories = _getFilterCategories(appState);
                          final categoryKey = _filterCategoryKeys[index];
                          final category = categories[index];
                          final isSelected =
                              categoryKey == _selectedFilterCategory;
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index == _filterCategoryKeys.length - 1
                                  ? 0
                                  : 12,
                            ),
                            child:
                                _CategoryChip(
                                      label: category,
                                      isSelected: isSelected,
                                      onTap: () {
                                        setState(() {
                                          _selectedFilterCategory = categoryKey;
                                          _applyFilters();
                                        });
                                      },
                                    )
                                    .animate()
                                    .fadeIn(
                                      duration: 300.ms,
                                      delay: (index * 50).ms,
                                    )
                                    .scale(
                                      begin: const Offset(0.9, 0.9),
                                      end: const Offset(1, 1),
                                      delay: (index * 50).ms,
                                    ),
                          );
                        },
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 300.ms)
                    .slideY(begin: 0.1, end: 0),
          ),
          // Список СТО
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF3B82F6),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final appState = Provider.of<AppState>(
                          context,
                          listen: false,
                        );
                        return Text(
                          appState.t('loading_car_wash'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredCarWashes.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_car_wash_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                        )
                        .animate()
                        .scale(delay: 200.ms, duration: 400.ms)
                        .fadeIn(delay: 200.ms),
                    const SizedBox(height: 24),
                    Builder(
                          builder: (context) {
                            final appState = Provider.of<AppState>(
                              context,
                              listen: false,
                            );
                            return Text(
                              appState.t('no_car_wash_found'),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade800,
                              ),
                            );
                          },
                        )
                        .animate()
                        .fadeIn(delay: 300.ms)
                        .slideY(begin: 0.2, end: 0, delay: 300.ms),
                    const SizedBox(height: 8),
                    Text(
                          'Попробуйте изменить фильтры',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.2, end: 0, delay: 400.ms),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 16 : 20,
                16,
                isSmallScreen ? 16 : 20,
                isSmallScreen ? 20 : 24,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final carWash = _filteredCarWashes[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _ModernCarWashCard(
                      carWash: carWash,
                      onFavoriteTap: () => _toggleFavorite(carWash),
                      isSmallScreen: isSmallScreen,
                      index: index,
                    ),
                  );
                }, childCount: _filteredCarWashes.length),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleCategoriesTap(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final otherCategories = _getOtherCategories(appState);
    final selected = await showBottomCategoryMenu(
      context,
      otherCategories,
      '', // Нет выбранной категории, так как мы на странице автомоек
    );

    if (selected == null || !mounted) return;

    // Находим ключ выбранной категории
    final selectedCategory = otherCategories.firstWhere(
      (cat) => cat['name'] == selected,
      orElse: () => otherCategories[0],
    );
    final selectedKey = selectedCategory['nameKey'] as String;

    switch (selectedKey) {
      case 'restaurants':
        if (mounted) {
          Navigator.of(context).pushNamed(RestaurantsPage.routeName);
        }
        break;
      case 'car_service':
        if (mounted) {
          Navigator.of(context).pushNamed(CarServicePage.routeName);
        }
        break;
      case 'charging':
        if (mounted) {
          Navigator.of(context).pushNamed(ChargingStationsPage.routeName);
        }
        break;
      default:
        break;
    }
  }
}

// Виджет навигационного элемента
class _ModernNavItem extends StatelessWidget {
  const _ModernNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.all(isSelected ? 7 : 6),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                          )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    size: isSmallScreen
                        ? (isSelected ? 22 : 20)
                        : (isSelected ? 24 : 22),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 3 : 4),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isSmallScreen
                          ? (isSelected ? 10 : 9)
                          : (isSelected ? 11 : 10),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : Colors.grey.shade600,
                      height: 1.0,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Современная карточка автомойки
class _ModernCarWashCard extends StatelessWidget {
  const _ModernCarWashCard({
    required this.carWash,
    required this.onFavoriteTap,
    required this.isSmallScreen,
    required this.index,
  });

  final CarWash carWash;
  final VoidCallback onFavoriteTap;
  final bool isSmallScreen;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CarWashDetailPage(carWash: carWash),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Изображение
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: Image.network(
                          carWash.imageUrl,
                          height: isSmallScreen ? 200 : 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: isSmallScreen ? 200 : 220,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.grey.shade200,
                                      Colors.grey.shade300,
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.local_car_wash_rounded,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
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
                                Colors.black.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                        ),
                      ),
                      // Избранное
                      Positioned(
                            top: 16,
                            right: 16,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onFavoriteTap,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    carWash.isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: carWash.isFavorite
                                        ? Colors.red
                                        : Colors.grey.shade600,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .scale(delay: (index * 50 + 100).ms)
                          .fadeIn(delay: (index * 50 + 100).ms),
                      // Ценовой диапазон
                      Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.black.withOpacity(0.5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                carWash.priceRange,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .scale(delay: (index * 50 + 50).ms)
                          .fadeIn(delay: (index * 50 + 50).ms),
                    ],
                  ),
                  // Информация
                  Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 18 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                carWash.name,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 20 : 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Рейтинг
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF3B82F6),
                                    Color(0xFF60A5FA),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    carWash.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Типы мойки
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.local_car_wash_rounded,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                carWash.washTypes.take(2).join(', '),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${carWash.reviewCount} отзывов',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Адрес
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                carWash.address,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (carWash.distance != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${carWash.distance!.toStringAsFixed(1)} км',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (carWash.features.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: carWash.features.take(4).map((feature) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey.shade50,
                                      Colors.grey.shade100,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getFeatureIcon(feature),
                                      size: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      feature,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          duration: 500.ms,
          delay: (index * 60).ms,
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.3,
          end: 0,
          delay: (index * 60).ms,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          delay: (index * 60).ms,
          curve: Curves.easeOutCubic,
        );
  }

  IconData _getFeatureIcon(String feature) {
    switch (feature) {
      case 'Wi-Fi':
        return Icons.wifi_rounded;
      case 'Парковка':
        return Icons.local_parking_rounded;
      case 'Кафе':
        return Icons.restaurant_rounded;
      case 'Ожидание':
        return Icons.access_time_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }
}

// Виджет активного фильтра
class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    ).animate().scale(duration: 200.ms).fadeIn(duration: 200.ms);
  }
}

// Виджет категории фильтра
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
        splashColor: isSelected
            ? Colors.white.withOpacity(0.2)
            : const Color(0xFF3B82F6).withOpacity(0.1),
        highlightColor: isSelected
            ? Colors.white.withOpacity(0.1)
            : const Color(0xFF3B82F6).withOpacity(0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF60A5FA),
                      Color(0xFF2563EB),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey.shade200,
              width: isSelected ? 0 : 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF374151),
                  letterSpacing: isSelected ? 0.3 : 0.1,
                  height: 1.2,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
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
