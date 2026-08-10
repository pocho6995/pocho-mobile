import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../models/fuel_station.dart';
import '../../services/stations_service.dart';
import '../../di/injection_container.dart' as di;
import '../../state/app_state.dart';
import '../../utils/theme_utils.dart';
import '../../presentation/pages/gas_station_detail_page.dart';

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  late final StationsService _stationsService;
  bool _isLoading = true;
  List<FuelStation> _favorites = [];

  @override
  void initState() {
    super.initState();
    _stationsService = di.getIt<StationsService>();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      // Пытаемся загрузить избранные через API
      final response = await _stationsService.getFavoriteStations(
        limit: 100,
        skip: 0,
      );

      if (response.places.isNotEmpty) {
        // Если получили данные из API, используем их
        setState(() {
          _favorites = response.places;
          _isLoading = false;
        });
        print('Loaded ${_favorites.length} favorite stations from API');
      } else {
        // Если API вернул пустой список, не используем мок данные
        // Возможно, у пользователя действительно нет избранных
        print('No favorite stations found in API response');
        setState(() {
          _favorites = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      // Логируем ошибку
      print('Error loading favorites: $e');
      setState(() {
        _favorites = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      color: getBackgroundColor(context),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // SliverAppBar с градиентом
          SliverAppBar(
            expandedHeight: isSmallScreen ? 240 : 280,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF6366F1),
            automaticallyImplyLeading: false,
            // Весь контент заголовка вынесен во flexibleSpace,
            // чтобы не дублировать небольшой заголовок при трансформации.
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isSmallScreen ? 20 : 24,
                      isSmallScreen ? 16 : 20,
                      isSmallScreen ? 16 : 20,
                      isSmallScreen ? 24 : 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                )
                                .animate()
                                .scale(duration: 400.ms)
                                .then()
                                .shimmer(duration: 2000.ms),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                        appState.t('favorites'),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      )
                                      .animate()
                                      .fadeIn(duration: 400.ms)
                                      .slideX(begin: -0.2, end: 0),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isLoading
                                        ? 'Загрузка...'
                                        : '${_favorites.length} ${_favorites.length == 1
                                              ? 'заправка'
                                              : _favorites.length < 5
                                              ? 'заправки'
                                              : 'заправок'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ).animate().fadeIn(
                                    duration: 400.ms,
                                    delay: 200.ms,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!_isLoading && _favorites.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _StatItem(
                                        icon: Icons.star_rounded,
                                        value: _favorites.isNotEmpty
                                            ? (_favorites
                                                      .map((s) => s.rating)
                                                      .reduce((a, b) => a + b) /
                                                  _favorites.length)
                                            : 0.0,
                                        label: 'Средний рейтинг',
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    ),
                                    Container(
                                      width: 1.5,
                                      height: 50,
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                    Expanded(
                                      child: _StatItem(
                                        icon: Icons.local_gas_station_rounded,
                                        value:
                                            _favorites
                                                .where(
                                                  (s) => s.minPrice != null,
                                                )
                                                .isNotEmpty
                                            ? _favorites
                                                  .where(
                                                    (s) => s.minPrice != null,
                                                  )
                                                  .map((s) => s.minPrice!)
                                                  .reduce(
                                                    (a, b) => a < b ? a : b,
                                                  )
                                            : 0.0,
                                        label: 'Лучшая цена',
                                        isSmallScreen: isSmallScreen,
                                        isPrice: true,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 400.ms)
                              .slideY(begin: 0.2, end: 0)
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1, 1),
                                delay: 400.ms,
                              ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ), // FlexibleSpaceBar
          ),
          // Контент
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          else if (_favorites.isEmpty)
            SliverFillRemaining(child: _EmptyFavoritesState())
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 16 : 20,
                isSmallScreen ? 20 : 24,
                isSmallScreen ? 16 : 20,
                20,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final station = _favorites[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < _favorites.length - 1 ? 16 : 0,
                    ),
                    child:
                        _FavoriteCard(
                              station: station,
                              index: index,
                              onFavoriteChanged: () async {
                                // Удаляем из избранного через API
                                final success = await _stationsService
                                    .removeFromFavorites(station.id);
                                if (success && mounted) {
                                  setState(() {
                                    station.isFavorite = false;
                                    _favorites.remove(station);
                                  });
                                } else if (mounted) {
                                  // Если API не сработал, просто обновляем локально
                                  setState(() {
                                    station.isFavorite = false;
                                    _favorites.remove(station);
                                  });
                                }
                              },
                              isSmallScreen: isSmallScreen,
                            )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                            .slideY(begin: 0.2, end: 0, delay: (index * 50).ms),
                  );
                }, childCount: _favorites.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.isSmallScreen,
    this.isPrice = false,
  });

  final IconData icon;
  final double value;
  final String label;
  final bool isSmallScreen;
  final bool isPrice;

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: isSmallScreen ? 22 : 24),
        SizedBox(height: isSmallScreen ? 8 : 10),
        Text(
          isPrice
              ? (value > 0 ? '${_formatPrice(value)} сум' : '—')
              : (value > 0 ? value.toStringAsFixed(1) : '—'),
          style: TextStyle(
            fontSize: isSmallScreen ? 17 : 19,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: isSmallScreen ? 4 : 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyFavoritesState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 60,
              color: Colors.white,
            ),
          ).animate().scale(duration: 600.ms).then().shimmer(duration: 2000.ms),
          const SizedBox(height: 24),
          Text(
            'Нет избранных заправок',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: getTitleColor(context),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 12),
          Text(
            'Добавляйте заправки в избранное,\nчтобы быстро находить их',
            style: TextStyle(
              fontSize: 16,
              color: getSecondaryTextColor(context),
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.station,
    required this.index,
    required this.onFavoriteChanged,
    required this.isSmallScreen,
  });

  final FuelStation station;
  final int index;
  final VoidCallback onFavoriteChanged;
  final bool isSmallScreen;

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} сум';
  }

  @override
  Widget build(BuildContext context) {
    final minPrice = station.minPrice;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Используем GasStationDetailPage с stationId для новой архитектуры
          Navigator.of(
            context,
          ).pushNamed(GasStationDetailPage.routeName, arguments: station.id);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
                child: Row(
                  children: [
                    // Иконка заправки (фиолетовый квадрат)
                    Container(
                      height: isSmallScreen ? 72 : 80,
                      width: isSmallScreen ? 72 : 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_gas_station_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 14 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Название заправки
                          Text(
                            station.name,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Адрес
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: isSmallScreen ? 14 : 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
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
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Рейтинг и цена
                          Row(
                            children: [
                              // Рейтинг (зеленый бейдж)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF34D399),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      station.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (minPrice != null) ...[
                                const SizedBox(width: 10),
                                // Цена (фиолетовый бейдж)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF6366F1,
                                        ).withOpacity(0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'от ${_formatPrice(minPrice)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Кнопка избранного (красное сердце в правом верхнем углу)
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onFavoriteChanged,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
