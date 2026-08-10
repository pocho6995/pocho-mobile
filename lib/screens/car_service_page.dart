import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/car_service.dart';
import '../services/car_service_service.dart';
import '../di/injection_container.dart' as di;
import '../state/app_state.dart';
import '../widgets/modern_bottom_sheet.dart';
import 'car_wash_page.dart';
import 'charging_stations_page.dart';
import 'favorites_car_service_page.dart';
import 'main_shell.dart';
import 'car_service_detail_page.dart';
import 'widgets/category_bottom_sheet.dart';

class CarServicePage extends StatefulWidget {
  const CarServicePage({super.key});

  static const String routeName = '/car-service';

  @override
  State<CarServicePage> createState() => _CarServicePageState();
}

class _CarServicePageState extends State<CarServicePage> {
  late final CarServiceService _carServiceService;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isLoading = true;
  List<CarService> _carServices = [];
  List<CarService> _filteredCarServices = [];

  String? _selectedCategory;
  String? _selectedService;
  double? _minRating;

  // Категории для фильтрации СТО (используем ключи для сравнений)
  String _selectedFilterCategory = 'all';
  final List<String> _filterCategoryKeys = [
    'all',
    'nearby',
    'with_promotions',
    'high_rating',
    'with_parking',
    'with_wifi',
    '24_7',
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

  // Вспомогательная функция для проверки, является ли значение "Все"
  bool _isAllValue(String? value, AppState appState) {
    if (value == null) return true;
    return value == appState.t('filter_all');
  }

  final List<String> _categories = ['Все', 'СТО', 'Автосервис', 'Шиномонтаж'];

  final List<String> _services = [
    'Все',
    'Ремонт двигателя',
    'Замена масла',
    'Диагностика',
    'Ремонт подвески',
    'Шиномонтаж',
    'Балансировка',
    'Ремонт кузова',
    'Покраска',
    'Ремонт электроники',
  ];

  @override
  void initState() {
    super.initState();
    _carServiceService = di.getIt<CarServiceService>();
    _loadCarServices();
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
    if (_selectedCategory != null) count++;
    if (_selectedService != null) count++;
    if (_minRating != null) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedService = null;
      _minRating = null;
      _selectedFilterCategory = 'all';
      _searchController.clear();
    });
    _applyFilters();
  }

  void _showFiltersModal(BuildContext context) {
    // Сохраняем текущие значения фильтров для модального окна
    String? tempCategory = _selectedCategory;
    String? tempService = _selectedService;
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
                  // Тип услуги
                  Text(
                    appState.t('service_type'),
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
                    children: _services.map((service) {
                      final isSelected =
                          tempService == service ||
                          (tempService == null && service == 'Все');
                      return FilterChip(
                        label: Text(service),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            tempService = selected
                                ? (service == 'Все' ? null : service)
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
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: tempFilterCategory == '24_7',
                    onChanged: (value) {
                      setModalState(() {
                        tempFilterCategory = value == true ? '24_7' : 'all';
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
                    value: tempFilterCategory == 'with_promotions',
                    onChanged: (value) {
                      setModalState(() {
                        tempFilterCategory = value == true
                            ? 'with_promotions'
                            : 'all';
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
                                  tempCategory = null;
                                  tempService = null;
                                  tempMinRating = null;
                                  tempFilterCategory = 'all';
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
                                  _selectedCategory = tempCategory;
                                  _selectedService = tempService;
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

  Future<void> _loadCarServices() async {
    setState(() => _isLoading = true);
    try {
      // Загружаем данные только с сервера
      final response = await _carServiceService.getCarServices(
        skip: 0,
        limit: 100,
        serviceType: _selectedService != null && _selectedService != 'Все'
            ? _selectedService
            : null,
        minRating: _minRating,
        searchQuery: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        hasParking: _selectedFilterCategory == 'with_parking' ? true : null,
      );

      // Проверяем статус избранного для каждого СТО
      for (final carService in response.carServices) {
        if (!carService.isFavorite) {
          try {
            final isFavorite = await _carServiceService.checkIsFavorite(
              carService.id,
            );
            carService.isFavorite = isFavorite;
          } catch (e) {
            // Игнорируем ошибки проверки
          }
        }
      }

      setState(() {
        _carServices = response.carServices;
        _filteredCarServices = _carServices;
        _isLoading = false;
      });
    } catch (e) {
      // При ошибке показываем пустой список
      if (mounted) {
        setState(() {
          _carServices = [];
          _filteredCarServices = [];
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredCarServices = _carServices.where((carService) {
        // Поиск
        final searchQuery = _searchController.text.toLowerCase();
        if (searchQuery.isNotEmpty) {
          if (!carService.name.toLowerCase().contains(searchQuery) &&
              !carService.address.toLowerCase().contains(searchQuery) &&
              !carService.services.any(
                (s) => s.toLowerCase().contains(searchQuery),
              )) {
            return false;
          }
        }

        // Фильтр по категории
        if (_selectedCategory != null && _selectedCategory != 'Все') {
          if (carService.category != _selectedCategory) {
            return false;
          }
        }

        // Фильтр по услуге
        if (_selectedService != null && _selectedService != 'Все') {
          if (!carService.services.contains(_selectedService)) {
            return false;
          }
        }

        // Фильтр по рейтингу
        if (_minRating != null) {
          if (carService.rating < _minRating!) {
            return false;
          }
        }

        // Фильтр по категории фильтра
        if (_selectedFilterCategory == 'nearby') {
          if (carService.distance == null || carService.distance! > 2.0) {
            return false;
          }
        } else if (_selectedFilterCategory == 'high_rating') {
          if (carService.rating < 4.5) {
            return false;
          }
        } else if (_selectedFilterCategory == 'with_parking') {
          if (!carService.features.contains('Парковка')) {
            return false;
          }
        } else if (_selectedFilterCategory == 'with_wifi') {
          if (!carService.features.contains('Wi-Fi')) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  Future<void> _toggleFavorite(CarService carService) async {
    final currentStatus = carService.isFavorite;

    // Оптимистичное обновление UI
    setState(() {
      carService.isFavorite = !currentStatus;
    });

    try {
      bool success;
      if (currentStatus) {
        success = await _carServiceService.removeFromFavorites(carService.id);
      } else {
        success = await _carServiceService.addToFavorites(carService.id);
      }

      if (!success && mounted) {
        // Откатываем изменения при ошибке
        setState(() {
          carService.isFavorite = currentStatus;
        });
      }
    } catch (e) {
      // Откатываем изменения при ошибке
      if (mounted) {
        setState(() {
          carService.isFavorite = currentStatus;
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
                        ).pushNamed(FavoritesCarServicePage.routeName);
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
                      Color(0xFF10B981),
                      Color(0xFF34D399),
                      Color(0xFF059669),
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
                                            appState.t('category_car_service'),
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
                                      hintText: appState.t(
                                        'search_car_service',
                                      ),
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.search_rounded,
                                        color: Color(0xFF10B981),
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
                                                          Color(0xFF10B981),
                                                          Color(0xFF34D399),
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
                                      if (_selectedCategory != null)
                                        _ActiveFilterChip(
                                          label: _selectedCategory!,
                                          onRemove: () {
                                            setState(() {
                                              _selectedCategory = null;
                                              _applyFilters();
                                            });
                                          },
                                        ),
                                      if (_selectedService != null)
                                        _ActiveFilterChip(
                                          label: _selectedService!,
                                          onRemove: () {
                                            setState(() {
                                              _selectedService = null;
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
                      child: Builder(
                        builder: (context) {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          final categories = _getFilterCategories(appState);
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _filterCategoryKeys.length,
                            itemBuilder: (ctx, index) {
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
                                              _selectedFilterCategory =
                                                  categoryKey;
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
                      color: Color(0xFF10B981),
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
                          appState.t('loading_car_service'),
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
          else if (_filteredCarServices.isEmpty)
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
                            Icons.build_rounded,
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
                              appState.t('no_car_service_found'),
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
                    Builder(
                          builder: (context) {
                            final appState = Provider.of<AppState>(
                              context,
                              listen: false,
                            );
                            return Text(
                              appState.t('try_changing_filters'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
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
                  final carService = _filteredCarServices[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _ModernCarServiceCard(
                      carService: carService,
                      onFavoriteTap: () => _toggleFavorite(carService),
                      isSmallScreen: isSmallScreen,
                      index: index,
                    ),
                  );
                }, childCount: _filteredCarServices.length),
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
      '', // Нет выбранной категории, так как мы на странице СТО
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
          Navigator.of(context).pushNamed('/restaurants');
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
                            colors: [Color(0xFF10B981), Color(0xFF34D399)],
                          )
                        : null,
                    color: isSelected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
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
                        ? (isSelected ? 20 : 18)
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
                          ? const Color(0xFF10B981)
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

// Современная карточка СТО
class _ModernCarServiceCard extends StatelessWidget {
  const _ModernCarServiceCard({
    required this.carService,
    required this.onFavoriteTap,
    required this.isSmallScreen,
    required this.index,
  });

  final CarService carService;
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
                  builder: (_) => CarServiceDetailPage(carService: carService),
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
                          carService.imageUrl,
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
                                  Icons.build_rounded,
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
                                    carService.isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: carService.isFavorite
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
                      // Категория
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
                                carService.category,
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
                                carService.name,
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
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    carService.rating.toStringAsFixed(1),
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
                        // Услуги
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.build_rounded,
                                size: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                carService.services.take(2).join(', '),
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
                              '${carService.reviewCount} отзывов',
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
                                carService.address,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (carService.distance != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${carService.distance!.toStringAsFixed(1)} км',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (carService.features.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: carService.features.take(4).map((
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
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
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
            : const Color(0xFF10B981).withOpacity(0.1),
        highlightColor: isSelected
            ? Colors.white.withOpacity(0.1)
            : const Color(0xFF10B981).withOpacity(0.05),
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
                      Color(0xFF10B981),
                      Color(0xFF34D399),
                      Color(0xFF059669),
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
