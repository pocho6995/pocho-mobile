import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/charging_station.dart';
import '../services/charging_station_service.dart';
import '../di/injection_container.dart' as di;
import 'charging_station_detail_page.dart';
import 'charging_stations_page.dart';
import 'main_shell.dart';
import 'widgets/category_bottom_sheet.dart';

class FavoritesChargingStationsPage extends StatefulWidget {
  const FavoritesChargingStationsPage({super.key});

  static const String routeName = '/favorites-charging-stations';

  @override
  State<FavoritesChargingStationsPage> createState() =>
      _FavoritesChargingStationsPageState();
}

class _FavoritesChargingStationsPageState
    extends State<FavoritesChargingStationsPage> {
  late final ChargingStationService _chargingStationService;
  bool _isLoading = true;
  List<ChargingStation> _favorites = [];

  // Рекламные баннеры
  final List<Map<String, dynamic>> _adBanners = [
    {
      'title': 'Премиум подписка',
      'subtitle': 'Получайте уведомления о лучших станциях первыми',
      'icon': Icons.workspace_premium_rounded,
      'gradient': [0xFF8B5CF6, 0xFFA78BFA],
    },
    {
      'title': 'Пригласите друзей',
      'subtitle': 'Получите бонусы за каждого друга',
      'icon': Icons.card_giftcard_rounded,
      'gradient': [0xFF6366F1, 0xFF8B5CF6],
    },
    {
      'title': 'Эксклюзивные предложения',
      'subtitle': 'Специальные скидки для постоянных клиентов',
      'icon': Icons.local_offer_rounded,
      'gradient': [0xFFA78BFA, 0xFFC4B5FD],
    },
  ];

  @override
  void initState() {
    super.initState();
    _chargingStationService = di.getIt<ChargingStationService>();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      // Загружаем избранные только с сервера
      final response = await _chargingStationService
          .getFavoriteChargingStations(skip: 0, limit: 100);

      setState(() {
        _favorites = response.stations;
        _isLoading = false;
      });
    } catch (e) {
      // При ошибке показываем пустой список
      if (mounted) {
        setState(() {
          _favorites = [];
          _isLoading = false;
        });
      }
    }
  }

  // Категории для навигации (без текущей категории "Электрозаправки")
  final List<Map<String, dynamic>> _otherCategories = const [
    {
      'name': 'Рестораны',
      'icon': Icons.restaurant_rounded,
      'color': 0xFFEC4899,
      'route': 'restaurants',
    },
    {
      'name': 'СТО',
      'icon': Icons.build_rounded,
      'color': 0xFF10B981,
      'route': 'car_service',
    },
    {
      'name': 'Мойки',
      'icon': Icons.local_car_wash_rounded,
      'color': 0xFF3B82F6,
      'route': 'car_wash',
    },
  ];

  void _handleCategoriesTap() {
    showBottomCategoryMenu(
      context,
      _otherCategories,
      FavoritesChargingStationsPage.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
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
                      isSmallScreen ? 20 : 24,
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
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 12 : 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Избранное',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 28 : 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 6),
                                  Text(
                                    _favorites.isEmpty
                                        ? 'Нет избранных станций'
                                        : '${_favorites.length} ${_getPluralForm(_favorites.length)}',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                ),
              ),
            )
          else if (_favorites.isEmpty)
            SliverFillRemaining(
              child: _EmptyFavoritesState(isSmallScreen: isSmallScreen),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: 16,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  // Показываем рекламу каждые 3 станции
                  if (index > 0 && index % 3 == 0) {
                    final adIndex = (index ~/ 3 - 1) % _adBanners.length;
                    return Column(
                          children: [
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            _AdBanner(
                              title: _adBanners[adIndex]['title'] as String,
                              subtitle:
                                  _adBanners[adIndex]['subtitle'] as String,
                              icon: _adBanners[adIndex]['icon'] as IconData,
                              gradient:
                                  (_adBanners[adIndex]['gradient'] as List<int>)
                                      .map((c) => Color(c))
                                      .toList(),
                              isSmallScreen: isSmallScreen,
                            ),
                            SizedBox(height: isSmallScreen ? 16 : 20),
                            _FavoriteChargingStationCard(
                              station: _favorites[index - (index ~/ 3)],
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChargingStationDetailPage(
                                      station: _favorites[index - (index ~/ 3)],
                                    ),
                                  ),
                                );
                              },
                              onFavoriteTap: () async {
                                // Удаляем из избранного через API
                                final stationIndex = index - (index ~/ 3);
                                if (stationIndex < _favorites.length) {
                                  final station = _favorites[stationIndex];
                                  try {
                                    final success =
                                        await _chargingStationService
                                            .removeFromFavorites(station.id);
                                    if (success && mounted) {
                                      setState(() {
                                        _favorites.removeAt(stationIndex);
                                      });
                                    }
                                  } catch (e) {
                                    // Игнорируем ошибки
                                  }
                                }
                              },
                              isSmallScreen: isSmallScreen,
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                        .slideY(begin: 0.2, end: 0, delay: (index * 50).ms);
                  }
                  final stationIndex = index - (index ~/ 3);
                  if (stationIndex >= _favorites.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                        padding: EdgeInsets.only(
                          bottom:
                              index <
                                  _favorites.length +
                                      (_favorites.length ~/ 3) -
                                      1
                              ? 16
                              : 0,
                        ),
                        child: _FavoriteChargingStationCard(
                          station: _favorites[stationIndex],
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChargingStationDetailPage(
                                  station: _favorites[stationIndex],
                                ),
                              ),
                            );
                          },
                          onFavoriteTap: () async {
                            // Удаляем из избранного через API
                            if (stationIndex < _favorites.length) {
                              final station = _favorites[stationIndex];
                              try {
                                final success = await _chargingStationService
                                    .removeFromFavorites(station.id);
                                if (success && mounted) {
                                  setState(() {
                                    _favorites.removeAt(stationIndex);
                                  });
                                }
                              } catch (e) {
                                // Игнорируем ошибки
                              }
                            }
                          },
                          isSmallScreen: isSmallScreen,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                      .slideY(begin: 0.2, end: 0, delay: (index * 50).ms);
                }, childCount: _favorites.length + (_favorites.length ~/ 3)),
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
          child: Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 6,
              bottom: 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ModernNavItem(
                  icon: Icons.home_rounded,
                  label: 'Главная',
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
                  label: 'Категории',
                  isSelected: false,
                  onTap: _handleCategoriesTap,
                ),
                _ModernNavItem(
                  icon: Icons.favorite_rounded,
                  label: 'Избранное',
                  isSelected: true,
                  gradient: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPluralForm(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'станция';
    if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return 'станции';
    }
    return 'станций';
  }
}

class _EmptyFavoritesState extends StatelessWidget {
  const _EmptyFavoritesState({required this.isSmallScreen});

  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isSmallScreen ? 24 : 32),
            Text(
              'Нет избранных станций',
              style: TextStyle(
                fontSize: isSmallScreen ? 22 : 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 8 : 12),
            Text(
              'Добавляйте понравившиеся электрозаправки в избранное для быстрого доступа',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isSmallScreen ? 32 : 40),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(ChargingStationsPage.routeName);
              },
              icon: const Icon(Icons.ev_station_rounded),
              label: const Text('Найти станции'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 24 : 32,
                  vertical: isSmallScreen ? 14 : 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteChargingStationCard extends StatelessWidget {
  const _FavoriteChargingStationCard({
    required this.station,
    required this.onTap,
    required this.onFavoriteTap,
    required this.isSmallScreen,
  });

  final ChargingStation station;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    final powerValue =
        int.tryParse(station.power.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Изображение
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  station.imageUrl,
                  width: isSmallScreen ? 80 : 100,
                  height: isSmallScreen ? 80 : 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: isSmallScreen ? 80 : 100,
                      height: isSmallScreen ? 80 : 100,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.ev_station_rounded,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            station.name,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: onFavoriteTap,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              size: 18,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: powerValue >= 100
                                  ? [
                                      const Color(0xFF8B5CF6),
                                      const Color(0xFFA78BFA),
                                    ]
                                  : [
                                      Colors.grey.shade300,
                                      Colors.grey.shade400,
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                station.power,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Text(
                          '${station.pricePerKwh.toStringAsFixed(1)} ₽/кВт·ч',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: isSmallScreen ? 14 : 16,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Expanded(
                          child: Text(
                            station.address,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (station.distance != null) ...[
                          SizedBox(width: isSmallScreen ? 6 : 8),
                          Text(
                            '${station.distance!.toStringAsFixed(1)} км',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }
}

class _AdBanner extends StatelessWidget {
  const _AdBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.isSmallScreen,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isSmallScreen ? 24 : 28,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: isSmallScreen ? 16 : 18,
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
