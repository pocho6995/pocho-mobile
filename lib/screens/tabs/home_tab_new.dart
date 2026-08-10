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
  
  // Фильтры
  String? _selectedFuelType;
  double? _minRating;
  double? _maxPrice;
  bool? _is24_7;
  bool? _hasPromotions;
  bool _showFilters = false;

  // Рекламные баннеры
  final List<Map<String, dynamic>> _promoBanners = [
    {
      'title': 'Скидка 10% на все виды топлива',
      'subtitle': 'До конца недели',
      'icon': Icons.local_offer,
      'color': [0xFF1565C0, 0xFF42A5F5],
    },
    {
      'title': 'Бесплатная мойка при заправке',
      'subtitle': 'От 50 литров',
      'icon': Icons.local_car_wash,
      'color': [0xFF4CAF50, 0xFF81C784],
    },
    {
      'title': 'Бонусные баллы за каждую заправку',
      'subtitle': 'Накопи и обменяй',
      'icon': Icons.stars,
      'color': [0xFFFF9800, 0xFFFFB74D],
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _startPromoAutoScroll();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _promoPageController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    final filterParams = GasStationFilterParams(
      skip: 0,
      limit: 100,
      fuelType: _selectedFuelType,
      minRating: _minRating,
      maxPrice: _maxPrice,
      is24_7: _is24_7,
      hasPromotions: _hasPromotions,
      searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
    );
    
    context.read<GasStationsBloc>().add(
      LoadGasStationsEvent(filterParams: filterParams),
    );
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _applyFilters() {
    final filterParams = GasStationFilterParams(
      skip: 0,
      limit: 100,
      fuelType: _selectedFuelType,
      minRating: _minRating,
      maxPrice: _maxPrice,
      is24_7: _is24_7,
      hasPromotions: _hasPromotions,
      searchQuery: _searchController.text.isEmpty ? null : _searchController.text,
    );
    
    context.read<GasStationsBloc>().add(
      UpdateFiltersEvent(filterParams: filterParams),
    );
  }

  void _startPromoAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _promoPageController.hasClients) {
        final currentPage = _promoPageController.page?.round() ?? 0;
        final nextPage = (currentPage + 1) % _promoBanners.length;
        _promoPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startPromoAutoScroll();
      }
    });
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
      create: (context) => di.getIt<GasStationsBloc>(),
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
                        const SizedBox(height: 16),
                        // Поле поиска
                        TextField(
                          controller: _searchController,
                          style: TextStyle(color: getTitleColor(context)),
                          decoration: InputDecoration(
                            hintText: 'Поиск заправок...',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
                            hintStyle: TextStyle(color: getSecondaryTextColor(context)),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                InkWell(
                                  onTap: () {
                                    setState(() => _showFilters = !_showFilters);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: _activeFiltersCount > 0
                                          ? const LinearGradient(
                                              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                                            )
                                          : null,
                                      color: _activeFiltersCount > 0
                                          ? null
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
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
                // Панель фильтров (упрощенная версия)
                if (_showFilters)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: getCardColor(context),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Тип топлива',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                'AI-80',
                                'AI-91',
                                'AI-95',
                                'AI-98',
                                'Дизель',
                                'Газ',
                              ].map((fuelType) {
                                final isSelected = _selectedFuelType == fuelType;
                                return FilterChip(
                                  label: Text(fuelType),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedFuelType = selected ? fuelType : null;
                                      _applyFilters();
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Рекламный слайдер
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: SizedBox(
                      height: 110,
                      child: PageView.builder(
                        controller: _promoPageController,
                        itemCount: _promoBanners.length,
                        itemBuilder: (context, index) {
                          final banner = _promoBanners[index];
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: (banner['color'] as List<int>)
                                    .map((c) => Color(c))
                                    .toList(),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        banner['title'] as String,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        banner['subtitle'] as String,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  banner['icon'] as IconData,
                                  size: 48,
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
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
                                onPressed: () => _loadInitialData(),
                                child: const Text('Повторить'),
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
                                  'Заправки не найдены',
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
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final station = state.stations[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: GasStationCard(
                                  station: station,
                                  index: index,
                                  onTap: () {
                                    // TODO: Переход на детальную страницу с новой entity
                                    // Navigator.of(context).push(
                                    //   MaterialPageRoute(
                                    //     builder: (_) => GasStationDetailPage(stationId: station.id),
                                    //   ),
                                    // );
                                  },
                                ),
                              );
                            },
                            childCount: state.stations.length,
                          ),
                        ),
                      );
                    }
                    
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  },
                ),
              ],
            ),
          ),
          // FloatingActionButton для ИИ помощника
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).pushNamed(AiAssistantPage.routeName);
              },
              backgroundColor: const Color(0xFF1565C0),
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text(
                'ИИ помощник',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 800.ms)
                .scale(delay: 800.ms),
          ),
        ],
      ),
    );
  }
}

