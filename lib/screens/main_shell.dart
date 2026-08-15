import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../di/injection_container.dart' as di;
import '../repositories/notification_repository.dart';
import '../services/delivery_service.dart';
import 'car_service_page.dart';
import 'car_wash_page.dart';
import 'charging_stations_page.dart';
import 'notifications_page.dart';
import 'restaurants_page.dart';
import 'tabs/delivery_tab.dart';
import 'tabs/favorites_tab.dart';
import 'tabs/home_tab.dart';
import 'profile_page.dart';
import 'widgets/category_bottom_sheet.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static const String routeName = '/main';

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _unreadNotificationsCount = 0;
  String _selectedNavigationCategory =
      'restaurants'; // Используем ключ вместо русского названия
  late NotificationRepository _notificationRepository;
  late DeliveryService _deliveryService;
  bool _isDriver = false;
  bool _isCheckingDriver = true;

  List<Widget> get _pages => [
    const HomeTab(),
    if (!_isDriver) const DeliveryTab(),
    const FavoritesTab(),
  ];

  @override
  void initState() {
    super.initState();
    _notificationRepository = di.getIt<NotificationRepository>();
    _deliveryService = di.getIt<DeliveryService>();
    _checkIfDriver();
    _loadUnreadCount();
    _setupWebSocketListeners();
  }

  Future<void> _checkIfDriver() async {
    final isDriver = await _deliveryService.isRegisteredDriver();
    if (mounted) {
      setState(() {
        _isDriver = isDriver;
        _isCheckingDriver = false;
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final stats = await _notificationRepository.getStats();
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = stats.unread;
        });
      }
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  void _setupWebSocketListeners() {
    _notificationRepository.setOnNotificationReceived((notification) {
      if (mounted) {
        setState(() {
          if (!notification.isRead) {
            _unreadNotificationsCount++;
          }
        });
      }
    });
  }

  // Категории для навигации (используются и на главной, и в нижней панели)
  List<Map<String, dynamic>> _getNavigationCategories(AppState appState) {
    return [
      {
        'name': appState.t('category_restaurants'),
        'nameKey': 'restaurants',
        'icon': Icons.restaurant_rounded,
        'color': 0xFFEF4444,
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
      {
        'name': appState.t('category_charging_stations'),
        'nameKey': 'charging',
        'icon': Icons.ev_station_rounded,
        'color': 0xFF8B5CF6,
        'route': 'charging',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      body: Column(
        children: [
          if (_currentIndex !=
              (_isDriver ? 1 : 2)) // Скрываем AppBar на странице избранного
            _CustomAppBar(
              appState: appState,
              unreadNotificationsCount: _unreadNotificationsCount,
              onNotificationTap: () async {
                // Обновляем счетчик при открытии страницы уведомлений
                await _loadUnreadCount();
              },
            ),
          Expanded(
            child: _isCheckingDriver
                ? const Center(child: CircularProgressIndicator())
                : _pages[_currentIndex],
          ),
        ],
      ),
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
                  label: appState.t('home'),
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                // Таб доставки скрываем для водителей
                if (!_isDriver && !_isCheckingDriver)
                  _ModernNavItem(
                    icon: Icons.delivery_dining_outlined,
                    selectedIcon: Icons.delivery_dining_rounded,
                    label: appState.t('delivery'),
                    isSelected: _currentIndex == 1,
                    onTap: () {
                      Navigator.of(context).pushNamed('/delivery-map');
                    },
                  ),
                // Кнопка категорий с выпадающим списком
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
                  isSelected: _isDriver
                      ? _currentIndex == 1
                      : _currentIndex == 2,
                  onTap: () =>
                      setState(() => _currentIndex = _isDriver ? 1 : 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCategoriesTap(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final categories = _getNavigationCategories(appState);
    final selectedName =
        categories.firstWhere(
              (cat) => cat['nameKey'] == _selectedNavigationCategory,
              orElse: () => categories[0],
            )['name']
            as String;

    final selected = await showBottomCategoryMenu(
      context,
      categories,
      selectedName,
    );

    if (selected == null) return;

    // Находим ключ выбранной категории
    final selectedCategory = categories.firstWhere(
      (cat) => cat['name'] == selected,
      orElse: () => categories[0],
    );
    final selectedKey = selectedCategory['nameKey'] as String;

    setState(() {
      _selectedNavigationCategory = selectedKey;
    });

    switch (selectedKey) {
      case 'restaurants':
        Navigator.of(context).pushNamed(RestaurantsPage.routeName);
        break;
      case 'car_service':
        Navigator.of(context).pushNamed(CarServicePage.routeName);
        break;
      case 'car_wash':
        Navigator.of(context).pushNamed(CarWashPage.routeName);
        break;
      case 'charging':
        Navigator.of(context).pushNamed(ChargingStationsPage.routeName);
        break;
      default:
        break;
    }
  }
}

class _CustomAppBar extends StatelessWidget {
  const _CustomAppBar({
    required this.appState,
    required this.unreadNotificationsCount,
    this.onNotificationTap,
  });

  final AppState appState;
  final int unreadNotificationsCount;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: statusBarHeight + 4,
        left: isSmallScreen ? 16 : 20,
        right: isSmallScreen ? 16 : 20,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Логотип с улучшенным дизайном
          Container(
                height: isSmallScreen ? 40 : 44,
                width: isSmallScreen ? 40 : 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  ),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .scale(begin: const Offset(0.8, 0.8), delay: 100.ms),
          SizedBox(width: isSmallScreen ? 12 : 14),
          // Название приложения с улучшенной типографикой
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                    appState.t('app_name'),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 20 : 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                      letterSpacing: -0.5,
                      height: 1.0,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 150.ms)
                  .slideX(begin: -0.2, end: 0),
            ],
          ),
          const Spacer(),
          // Кнопка чата с улучшенным дизайном
          Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed('/global-chat');
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .scale(begin: const Offset(0.9, 0.9), delay: 200.ms),
          SizedBox(width: isSmallScreen ? 10 : 12),
          // Кнопка уведомлений с улучшенным дизайном
          Stack(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        onNotificationTap?.call();
                        Navigator.of(
                          context,
                        ).pushNamed(NotificationsPage.routeName);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.notifications_outlined,
                          size: 20,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  if (unreadNotificationsCount > 0)
                    Positioned(
                      right: isSmallScreen ? 4 : 6,
                      top: isSmallScreen ? 4 : 6,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadNotificationsCount > 9
                              ? '9+'
                              : '$unreadNotificationsCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 250.ms)
              .scale(begin: const Offset(0.9, 0.9), delay: 250.ms),
          SizedBox(width: isSmallScreen ? 10 : 12),
          // Кнопка аватара пользователя с улучшенным дизайном
          Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed(ProfilePage.routeName);
                  },
                  borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 20),
                  child: Container(
                    width: isSmallScreen ? 40 : 44,
                    height: isSmallScreen ? 40 : 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      ),
                      borderRadius: BorderRadius.circular(
                        isSmallScreen ? 18 : 20,
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms)
              .scale(delay: 400.ms),
        ],
      ),
    );
  }
}

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
