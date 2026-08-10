import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/car_service.dart';
import '../services/car_service_service.dart';
import '../di/injection_container.dart' as di;
import 'car_service_detail_page.dart';
import 'car_wash_page.dart';
import 'charging_stations_page.dart';
import 'main_shell.dart';
import 'restaurants_page.dart';
import 'widgets/category_bottom_sheet.dart';

class FavoritesCarServicePage extends StatefulWidget {
  const FavoritesCarServicePage({super.key});

  static const String routeName = '/favorites-car-service';

  @override
  State<FavoritesCarServicePage> createState() =>
      _FavoritesCarServicePageState();
}

class _FavoritesCarServicePageState extends State<FavoritesCarServicePage> {
  late final CarServiceService _carServiceService;
  bool _isLoading = true;
  List<CarService> _favorites = [];

  // Рекламные баннеры
  final List<Map<String, dynamic>> _adBanners = [
    {
      'title': 'Премиум подписка',
      'subtitle': 'Получайте уведомления о лучших СТО первыми',
      'icon': Icons.workspace_premium_rounded,
      'gradient': [0xFF10B981, 0xFF34D399],
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
      'gradient': [0xFFEF4444, 0xFFF87171],
    },
  ];

  @override
  void initState() {
    super.initState();
    _carServiceService = di.getIt<CarServiceService>();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    try {
      // Загружаем избранные только с сервера
      final response = await _carServiceService.getFavoriteCarServices(
        skip: 0,
        limit: 100,
      );

      setState(() {
        _favorites = response.carServices;
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

  // Категории для навигации (без текущей категории "СТО")
  final List<Map<String, dynamic>> _otherCategories = const [
    {
      'name': 'Рестораны',
      'icon': Icons.restaurant_rounded,
      'color': 0xFFEC4899,
      'route': 'restaurants',
    },
    {
      'name': 'Мойки',
      'icon': Icons.local_car_wash_rounded,
      'color': 0xFF3B82F6,
      'route': 'car_wash',
    },
    {
      'name': 'Электрозаправки',
      'icon': Icons.ev_station_rounded,
      'color': 0xFF8B5CF6,
      'route': 'charging',
    },
  ];

  Future<void> _handleCategoriesTap(BuildContext context) async {
    final selected = await showBottomCategoryMenu(
      context,
      _otherCategories,
      '', // Нет выбранной категории, так как мы на странице избранного
    );

    if (selected == null || !mounted) return;

    switch (selected) {
      case 'Рестораны':
        if (mounted) {
          Navigator.of(context).pushNamed(RestaurantsPage.routeName);
        }
        break;
      case 'Мойки':
        if (mounted) {
          Navigator.of(context).pushNamed(CarWashPage.routeName);
        }
        break;
      case 'Электрозаправки':
        if (mounted) {
          Navigator.of(context).pushNamed(ChargingStationsPage.routeName);
        }
        break;
      default:
        break;
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
                  isSelected: true,
                  onTap: () {
                    // Уже на странице избранного, ничего не делаем
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // SliverAppBar с градиентом
          SliverAppBar(
            expandedHeight: isSmallScreen ? 220 : 260,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF10B981),
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
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
                                  const Text(
                                        'Избранное',
                                        style: TextStyle(
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
                                              ? 'СТО'
                                              : _favorites.length < 5
                                              ? 'СТО'
                                              : 'СТО'}',
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
                                padding: EdgeInsets.all(
                                  isSmallScreen ? 12 : 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _StatItem(
                                        icon: Icons.star_rounded,
                                        value:
                                            _favorites
                                                .map((cs) => cs.rating)
                                                .reduce((a, b) => a + b) /
                                            _favorites.length,
                                        label: 'Средний рейтинг',
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: isSmallScreen ? 35 : 40,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                    Expanded(
                                      child: _StatItem(
                                        icon: Icons.build_rounded,
                                        value: _favorites.length.toDouble(),
                                        label: isSmallScreen
                                            ? 'Всего'
                                            : 'Всего СТО',
                                        isSmallScreen: isSmallScreen,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 400.ms)
                              .slideY(begin: 0.2, end: 0),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Контент
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              ),
            )
          else if (_favorites.isEmpty)
            SliverFillRemaining(child: _EmptyFavoritesState())
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 16 : 20,
                isSmallScreen ? 16 : 20,
                isSmallScreen ? 16 : 20,
                20,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Вычисляем, сколько рекламных блоков было до этого индекса
                    int carServiceIndex = 0;
                    int adCount = 0;
                    for (int i = 0; i < index; i++) {
                      if (carServiceIndex > 0 &&
                          carServiceIndex % 3 == 0 &&
                          adCount < _adBanners.length) {
                        adCount++;
                      } else {
                        carServiceIndex++;
                      }
                    }

                    // Если это позиция для рекламы
                    if (carServiceIndex > 0 &&
                        carServiceIndex % 3 == 0 &&
                        adCount < _adBanners.length) {
                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          _AdBanner(
                                title: _adBanners[adCount]['title'] as String,
                                subtitle:
                                    _adBanners[adCount]['subtitle'] as String,
                                icon: _adBanners[adCount]['icon'] as IconData,
                                gradient:
                                    (_adBanners[adCount]['gradient']
                                            as List<int>)
                                        .map((c) => Color(c))
                                        .toList(),
                              )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 300.ms)
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1, 1),
                                delay: 300.ms,
                              ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }

                    // Карточка СТО
                    if (carServiceIndex >= _favorites.length) {
                      return const SizedBox.shrink();
                    }
                    final carService = _favorites[carServiceIndex];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child:
                          _FavoriteCarServiceCard(
                                carService: carService,
                                index: carServiceIndex,
                                onFavoriteChanged: () async {
                                  // Удаляем из избранного через API
                                  try {
                                    final success = await _carServiceService
                                        .removeFromFavorites(carService.id);
                                    if (success && mounted) {
                                      setState(() {
                                        _favorites.remove(carService);
                                      });
                                    }
                                  } catch (e) {
                                    // Игнорируем ошибки
                                  }
                                },
                                isSmallScreen: isSmallScreen,
                              )
                              .animate()
                              .fadeIn(
                                duration: 400.ms,
                                delay: (carServiceIndex * 50).ms,
                              )
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                delay: (carServiceIndex * 50).ms,
                              ),
                    );
                  },
                  childCount:
                      _favorites.length +
                      (_favorites.length ~/ 3).clamp(0, _adBanners.length),
                ),
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
  });

  final IconData icon;
  final double value;
  final String label;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: isSmallScreen ? 18 : 22),
        SizedBox(height: isSmallScreen ? 6 : 8),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isSmallScreen ? 2 : 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
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
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
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
          const Text(
            'Нет избранных СТО',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 12),
          Text(
            'Добавляйте СТО в избранное,\nчтобы быстро находить их',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
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

class _AdBanner extends StatelessWidget {
  const _AdBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
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
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'РЕКЛАМА',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteCarServiceCard extends StatelessWidget {
  const _FavoriteCarServiceCard({
    required this.carService,
    required this.index,
    required this.onFavoriteChanged,
    required this.isSmallScreen,
  });

  final CarService carService;
  final int index;
  final VoidCallback onFavoriteChanged;
  final bool isSmallScreen;

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
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 18),
            child: Row(
              children: [
                // Изображение СТО
                Container(
                  width: isSmallScreen ? 100 : 120,
                  height: isSmallScreen ? 100 : 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey.shade200, Colors.grey.shade300],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      carService.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
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
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Информация о СТО
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              carService.name,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onFavoriteChanged,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: isSmallScreen ? 16 : 18,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            carService.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${carService.reviewCount})',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: isSmallScreen ? 14 : 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              carService.address,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              carService.category,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              carService.services.take(1).join(', '),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
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
