import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/restaurant.dart';
import '../services/restaurants_service.dart';
import '../di/injection_container.dart' as di;
import '../state/app_state.dart';
import '../widgets/modern_bottom_sheet.dart';
import 'car_service_page.dart';
import 'car_wash_page.dart';
import 'charging_stations_page.dart';
import 'favorites_restaurants_page.dart';
import 'main_shell.dart';
import 'restaurant_detail_page.dart';
import 'widgets/category_bottom_sheet.dart';

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  static const String routeName = '/restaurants';

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  late final RestaurantsService _restaurantsService;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];

  String? _selectedCuisine; // Хранит переведенное значение для отображения
  String? _selectedPriceRange; // Хранит переведенное значение для отображения
  double? _minRating;

  // Категории для фильтрации ресторанов (используем ключи для сравнений)
  String _selectedCategory = 'all'; // Хранит ключ
  final List<String> _filterCategoryKeys = [
    'all',
    'nearby',
    'with_promotions',
    'high_rating',
    'cheap',
    'premium',
  ];

  // Функции для получения переведенных списков
  List<String> _getFilterCategories(AppState appState) {
    return [
      appState.t('filter_all'),
      appState.t('filter_nearby'),
      appState.t('filter_with_promotions'),
      appState.t('filter_high_rating'),
      appState.t('filter_cheap'),
      appState.t('filter_premium'),
    ];
  }

  List<Map<String, dynamic>> _getOtherCategories(AppState appState) {
    return [
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
      {
        'name': appState.t('category_charging_stations'),
        'nameKey': 'charging',
        'icon': Icons.ev_station_rounded,
        'color': 0xFF8B5CF6,
        'route': 'charging',
      },
    ];
  }

  final List<String> _cuisineKeys = [
    'all',
    'uzbek',
    'european',
    'japanese',
    'italian',
    'chinese',
    'american',
    'french',
    'indian',
    'georgian',
  ];

  List<String> _getCuisines(AppState appState) {
    return [
      appState.t('filter_all'),
      appState.t('cuisine_uzbek'),
      appState.t('cuisine_european'),
      appState.t('cuisine_japanese'),
      appState.t('cuisine_italian'),
      appState.t('cuisine_chinese'),
      appState.t('cuisine_american'),
      appState.t('cuisine_french'),
      appState.t('cuisine_indian'),
      appState.t('cuisine_georgian'),
    ];
  }

  final List<String> _priceRangeKeys = [
    'all',
    '\$',
    '\$\$',
    '\$\$\$',
    '\$\$\$\$',
  ];

  List<String> _getPriceRanges(AppState appState) {
    return [appState.t('filter_all'), '\$', '\$\$', '\$\$\$', '\$\$\$\$'];
  }

  // Вспомогательные функции для преобразования между ключами и значениями
  String? _getCuisineKeyByValue(String? value, AppState appState) {
    if (value == null) return 'all';
    final cuisines = _getCuisines(appState);
    final index = cuisines.indexOf(value);
    return index >= 0 ? _cuisineKeys[index] : null;
  }

  String? _getCuisineValueByKey(String? key, AppState appState) {
    if (key == null || key == 'all') return null;
    final index = _cuisineKeys.indexOf(key);
    return index >= 0 ? _getCuisines(appState)[index] : null;
  }

  String? _getPriceRangeKeyByValue(String? value, AppState appState) {
    if (value == null) return 'all';
    final priceRanges = _getPriceRanges(appState);
    final index = priceRanges.indexOf(value);
    return index >= 0 ? _priceRangeKeys[index] : null;
  }

  String? _getPriceRangeValueByKey(String? key, AppState appState) {
    if (key == null || key == 'all') return null;
    final index = _priceRangeKeys.indexOf(key);
    return index >= 0 ? _getPriceRanges(appState)[index] : null;
  }

  String _getFilterCategoryKeyByValue(String value, AppState appState) {
    final categories = _getFilterCategories(appState);
    final index = categories.indexOf(value);
    return index >= 0 ? _filterCategoryKeys[index] : 'all';
  }

  String _getFilterCategoryValueByKey(String key, AppState appState) {
    final index = _filterCategoryKeys.indexOf(key);
    return index >= 0
        ? _getFilterCategories(appState)[index]
        : appState.t('filter_all');
  }

  // Вспомогательная функция для проверки, является ли значение "Все"
  bool _isAllValue(String? value, AppState appState) {
    if (value == null) return true;
    return value == appState.t('filter_all');
  }

  @override
  void initState() {
    super.initState();
    _restaurantsService = di.getIt<RestaurantsService>();
    _loadRestaurants();
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
    if (_selectedCuisine != null) count++;
    if (_selectedPriceRange != null) count++;
    if (_minRating != null) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCuisine = null;
      _selectedPriceRange = null;
      _minRating = null;
      _selectedCategory = 'all';
      _searchController.clear();
    });
    _applyFilters();
  }

  void _showFiltersModal(BuildContext context) {
    // Сохраняем текущие значения фильтров для модального окна
    String? tempCuisine = _selectedCuisine;
    String? tempPriceRange = _selectedPriceRange;
    double? tempMinRating = _minRating;

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
                  // Тип кухни
                  Builder(
                    builder: (context) {
                      final modalAppState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      final cuisines = _getCuisines(modalAppState);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            modalAppState.t('cuisine_type'),
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
                            children: cuisines.asMap().entries.map((entry) {
                              final index = entry.key;
                              final cuisine = entry.value;
                              final cuisineKey = _cuisineKeys[index];
                              final isSelected =
                                  (tempCuisine == null &&
                                      cuisineKey == 'all') ||
                                  (tempCuisine != null &&
                                      _getCuisineKeyByValue(
                                            tempCuisine,
                                            modalAppState,
                                          ) ==
                                          cuisineKey);
                              return FilterChip(
                                label: Text(cuisine),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setModalState(() {
                                    tempCuisine = selected
                                        ? (cuisineKey == 'all' ? null : cuisine)
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
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Ценовой диапазон
                  Builder(
                    builder: (context) {
                      final modalAppState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      final priceRanges = _getPriceRanges(modalAppState);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            modalAppState.t('price_range'),
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
                          ),
                        ],
                      );
                    },
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
                    children: [appState.t('all'), '4.0+', '4.5+', '4.7+'].map((
                      rating,
                    ) {
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
                    }).toList(),
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
                                  tempCuisine = null;
                                  tempPriceRange = null;
                                  tempMinRating = null;
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
                                // Применяем фильтры
                                setState(() {
                                  _selectedCuisine = tempCuisine;
                                  _selectedPriceRange = tempPriceRange;
                                  _minRating = tempMinRating;
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

  Future<void> _loadRestaurants() async {
    setState(() => _isLoading = true);
    try {
      // Загружаем данные только с сервера
      final appState = Provider.of<AppState>(context, listen: false);
      final response = await _restaurantsService.getRestaurants(
        skip: 0,
        limit: 100,
        cuisineType:
            _selectedCuisine != null && !_isAllValue(_selectedCuisine, appState)
            ? _selectedCuisine
            : null,
        minRating: _minRating,
        searchQuery: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
      );

      // Проверяем статус избранного для каждого ресторана
      for (final restaurant in response.restaurants) {
        if (!restaurant.isFavorite) {
          try {
            final isFavorite = await _restaurantsService.checkIsFavorite(
              restaurant.id,
            );
            restaurant.isFavorite = isFavorite;
          } catch (e) {
            // Игнорируем ошибки проверки
          }
        }
      }

      setState(() {
        _restaurants = response.restaurants;
        _filteredRestaurants = _restaurants;
        _isLoading = false;
      });
    } catch (e) {
      // При ошибке показываем пустой список
      if (mounted) {
        setState(() {
          _restaurants = [];
          _filteredRestaurants = [];
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final appState = Provider.of<AppState>(context, listen: false);
    // Если есть активные фильтры, перезагружаем через API
    if (_selectedCuisine != null && !_isAllValue(_selectedCuisine, appState) ||
        _selectedPriceRange != null &&
            !_isAllValue(_selectedPriceRange, appState) ||
        _minRating != null ||
        _searchController.text.isNotEmpty ||
        _selectedCategory != 'all') {
      _loadRestaurants();
      return;
    }

    // Локальная фильтрация для быстрого отклика
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        // Поиск
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          if (!restaurant.name.toLowerCase().contains(searchQuery) &&
              !restaurant.address.toLowerCase().contains(searchQuery) &&
              !restaurant.cuisine.toLowerCase().contains(searchQuery)) {
            return false;
          }
        }

        // Фильтр по кухне
        final appState = Provider.of<AppState>(context, listen: false);
        if (_selectedCuisine != null &&
            !_isAllValue(_selectedCuisine, appState)) {
          if (restaurant.cuisine != _selectedCuisine) {
            return false;
          }
        }

        // Фильтр по ценовому диапазону
        if (_selectedPriceRange != null &&
            !_isAllValue(_selectedPriceRange, appState)) {
          if (restaurant.priceRange != _selectedPriceRange) {
            return false;
          }
        }

        // Фильтр по рейтингу
        if (_minRating != null) {
          if (restaurant.rating < _minRating!) {
            return false;
          }
        }

        // Фильтр по категории
        if (_selectedCategory == 'nearby') {
          if (restaurant.distance == null || restaurant.distance! > 2.0) {
            return false;
          }
        } else if (_selectedCategory == 'high_rating') {
          if (restaurant.rating < 4.5) {
            return false;
          }
        } else if (_selectedCategory == 'cheap') {
          if (restaurant.priceRange == '\$\$\$' ||
              restaurant.priceRange == '\$\$\$\$') {
            return false;
          }
        } else if (_selectedCategory == 'premium') {
          if (restaurant.priceRange != '\$\$\$\$') {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _toggleFavorite(Restaurant restaurant) async {
    final currentStatus = restaurant.isFavorite;

    // Оптимистичное обновление UI
    setState(() {
      restaurant.isFavorite = !currentStatus;
    });

    try {
      bool success;
      if (currentStatus) {
        success = await _restaurantsService.removeFromFavorites(restaurant.id);
      } else {
        success = await _restaurantsService.addToFavorites(restaurant.id);
      }

      if (!success && mounted) {
        // Откатываем изменения при ошибке
        setState(() {
          restaurant.isFavorite = currentStatus;
        });
      }
    } catch (e) {
      // Откатываем изменения при ошибке
      if (mounted) {
        setState(() {
          restaurant.isFavorite = currentStatus;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth >= 600;
    final isLargeScreen = screenWidth >= 900;

    // Адаптивные значения
    final cardSpacing = isSmallScreen ? 16.0 : (isTablet ? 20.0 : 20.0);
    final imageHeight = isSmallScreen ? 200.0 : (isTablet ? 240.0 : 220.0);

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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ModernNavItem(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: 'Главная',
                  isSelected: false,
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      MainShell.routeName,
                      (route) => false,
                    );
                  },
                ),
                // Кнопка категорий с выпадающим списком (без текущей категории)
                _ModernNavItem(
                  icon: Icons.apps_outlined,
                  selectedIcon: Icons.apps_rounded,
                  label: 'Категории',
                  isSelected: false,
                  onTap: () => _handleCategoriesTap(context),
                ),
                _ModernNavItem(
                  icon: Icons.favorite_border_rounded,
                  selectedIcon: Icons.favorite_rounded,
                  label: 'Избранное',
                  isSelected: false,
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(FavoritesRestaurantsPage.routeName);
                  },
                ),
              ],
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
            expandedHeight: isSmallScreen ? 240 : (isTablet ? 280 : 260),
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
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                      Color(0xFFEC4899),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isSmallScreen ? 16 : (isTablet ? 32 : 20),
                      isSmallScreen ? 12 : (isTablet ? 20 : 16),
                      isSmallScreen ? 16 : (isTablet ? 32 : 20),
                      isSmallScreen ? 16 : (isTablet ? 24 : 20),
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
                                            appState.t('category_restaurants'),
                                            style: TextStyle(
                                              fontSize: isSmallScreen
                                                  ? 26
                                                  : (isTablet ? 36 : 30),
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
                                      hintText: appState.t(
                                        'search_restaurants',
                                      ),
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: isSmallScreen
                                            ? 14
                                            : (isTablet ? 18 : 16),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: const Color(0xFF6366F1),
                                        size: isTablet ? 28 : 24,
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
                                                          Color(0xFF6366F1),
                                                          Color(0xFF8B5CF6),
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
                                        horizontal: isSmallScreen
                                            ? 16
                                            : (isTablet ? 24 : 20),
                                        vertical: isSmallScreen
                                            ? 14
                                            : (isTablet ? 20 : 18),
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: isSmallScreen
                                          ? 15
                                          : (isTablet ? 19 : 17),
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
                                      if (_selectedCuisine != null)
                                        _ActiveFilterChip(
                                          label: _selectedCuisine!,
                                          onRemove: () {
                                            setState(() {
                                              _selectedCuisine = null;
                                              _applyFilters();
                                            });
                                          },
                                        ),
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
                      margin: EdgeInsets.only(top: 8, bottom: 4),
                      height: isTablet ? 64 : 56,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : (isTablet ? 32 : 20),
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
                          final isSelected = categoryKey == _selectedCategory;
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
                                      isTablet: isTablet,
                                      onTap: () {
                                        setState(() {
                                          _selectedCategory = categoryKey;
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
          // Список ресторанов
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Color(0xFF6366F1),
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
                          appState.t('loading_restaurants'),
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
          else if (_filteredRestaurants.isEmpty)
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
                            Icons.restaurant_menu_rounded,
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
                              appState.t('no_restaurants_found'),
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
                isSmallScreen ? 16 : (isTablet ? 24 : 20),
                16, // Отступ сверху между категориями и списком
                isSmallScreen ? 16 : (isTablet ? 24 : 20),
                isSmallScreen ? 20 : (isTablet ? 32 : 24),
              ),
              sliver: isTablet && _filteredRestaurants.length > 0
                  ? SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isLargeScreen ? 3 : 2,
                        crossAxisSpacing: cardSpacing,
                        mainAxisSpacing: cardSpacing,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final restaurant = _filteredRestaurants[index];
                        return _ModernRestaurantCard(
                          restaurant: restaurant,
                          onFavoriteTap: () => _toggleFavorite(restaurant),
                          isSmallScreen: isSmallScreen,
                          isTablet: isTablet,
                          index: index,
                          imageHeight: imageHeight,
                        );
                      }, childCount: _filteredRestaurants.length),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final restaurant = _filteredRestaurants[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: cardSpacing),
                          child: _ModernRestaurantCard(
                            restaurant: restaurant,
                            onFavoriteTap: () => _toggleFavorite(restaurant),
                            isSmallScreen: isSmallScreen,
                            isTablet: isTablet,
                            index: index,
                            imageHeight: imageHeight,
                          ),
                        );
                      }, childCount: _filteredRestaurants.length),
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
      '', // Нет выбранной категории, так как мы на странице ресторанов
    );

    if (selected == null || !mounted) return;

    // Находим ключ выбранной категории
    final selectedCategory = otherCategories.firstWhere(
      (cat) => cat['name'] == selected,
      orElse: () => otherCategories[0],
    );
    final selectedKey = selectedCategory['nameKey'] as String;

    switch (selectedKey) {
      case 'car_service':
        if (mounted) {
          Navigator.of(context).pushNamed(CarServicePage.routeName);
        }
        break;
      case 'car_wash':
        if (mounted) {
          Navigator.of(context).pushNamed(CarWashPage.routeName);
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

// Виджет навигационного элемента (копия из main_shell.dart)
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
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
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
                          ? const Color(0xFF6366F1)
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

// Современная карточка ресторана
class _ModernRestaurantCard extends StatelessWidget {
  const _ModernRestaurantCard({
    required this.restaurant,
    required this.onFavoriteTap,
    required this.isSmallScreen,
    required this.index,
    this.isTablet = false,
    this.imageHeight = 220,
  });

  final Restaurant restaurant;
  final VoidCallback onFavoriteTap;
  final bool isSmallScreen;
  final bool isTablet;
  final int index;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RestaurantDetailPage(restaurant: restaurant),
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
                  // Изображение с улучшенным дизайном
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: Image.network(
                          restaurant.imageUrl,
                          height: imageHeight,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: imageHeight,
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
                                  Icons.restaurant_rounded,
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
                      // Избранное с анимацией
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
                                    restaurant.isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: restaurant.isFavorite
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
                                restaurant.priceRange,
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
                    padding: EdgeInsets.all(
                      isSmallScreen ? 18 : (isTablet ? 24 : 20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                restaurant.name,
                                style: TextStyle(
                                  fontSize: isSmallScreen
                                      ? 20
                                      : (isTablet ? 24 : 22),
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                                maxLines: isTablet ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Рейтинг с улучшенным дизайном
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 14 : 12,
                                vertical: isTablet ? 10 : 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF34D399),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: isTablet ? 20 : 18,
                                  ),
                                  SizedBox(width: isTablet ? 6 : 4),
                                  Text(
                                    restaurant.rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Кухня
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.restaurant_menu_rounded,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                restaurant.cuisine,
                                style: TextStyle(
                                  fontSize: isSmallScreen
                                      ? 14
                                      : (isTablet ? 16 : 15),
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: isTablet ? 16 : 12),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: isTablet ? 16 : 12),
                            Flexible(
                              child: Text(
                                '${restaurant.reviewCount} отзывов',
                                style: TextStyle(
                                  fontSize: isSmallScreen
                                      ? 13
                                      : (isTablet ? 15 : 14),
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
                                restaurant.address,
                                style: TextStyle(
                                  fontSize: isSmallScreen
                                      ? 14
                                      : (isTablet ? 16 : 15),
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: isTablet ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (restaurant.distance != null) ...[
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
                                  '${restaurant.distance!.toStringAsFixed(1)} км',
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
                        if (restaurant.features.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: restaurant.features.take(4).map((
                              feature,
                            ) {
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
                                      size: isTablet ? 16 : 14,
                                      color: Colors.grey.shade700,
                                    ),
                                    SizedBox(width: isTablet ? 8 : 6),
                                    Text(
                                      feature,
                                      style: TextStyle(
                                        fontSize: isTablet ? 13 : 12,
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
      case 'Доставка':
        return Icons.delivery_dining_rounded;
      case 'Терраса':
        return Icons.deck_rounded;
      case 'Живая музыка':
        return Icons.music_note_rounded;
      case 'Детское меню':
        return Icons.child_care_rounded;
      case 'VIP-зал':
        return Icons.workspace_premium_rounded;
      case 'Бар':
        return Icons.local_bar_rounded;
      case 'Вегетарианское меню':
        return Icons.eco_rounded;
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
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
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
    this.isTablet = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: isSelected
            ? Colors.white.withOpacity(0.2)
            : const Color(0xFF6366F1).withOpacity(0.1),
        highlightColor: isSelected
            ? Colors.white.withOpacity(0.1)
            : const Color(0xFF6366F1).withOpacity(0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 20,
            vertical: isTablet ? 14 : 12,
          ),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                      Color(0xFFEC4899),
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
                  fontSize: isTablet ? 16 : 14,
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
