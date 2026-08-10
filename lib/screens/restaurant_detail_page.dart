import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/restaurant.dart';
import '../services/restaurants_service.dart';
import '../di/injection_container.dart' as di;
import '../widgets/modern_snackbar.dart';

class RestaurantDetailPage extends StatefulWidget {
  const RestaurantDetailPage({super.key, required this.restaurant});

  final Restaurant restaurant;

  static const String routeName = '/restaurant-detail';

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  late Restaurant restaurant;
  late final RestaurantsService _restaurantsService;
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;
  final TextEditingController _reviewController = TextEditingController();
  double _userRating = 5.0;
  bool _isFavoriteLoading = false;

  // Мок фотографии ресторана
  final List<String> _restaurantImages = [];

  // Рекламные блоки
  final List<Map<String, dynamic>> _ads = [
    {
      'title': 'Скидка 20% на ужин',
      'subtitle': 'При заказе от 100 000 сум',
      'icon': Icons.local_dining_rounded,
      'color': [0xFFEF4444, 0xFFF87171],
      'bgGradient': [0xFFEF4444, 0xFFF87171],
    },
    {
      'title': 'Бесплатная доставка',
      'subtitle': 'При заказе от 50 000 сум',
      'icon': Icons.delivery_dining_rounded,
      'color': [0xFF10B981, 0xFF34D399],
      'bgGradient': [0xFF10B981, 0xFF34D399],
    },
  ];

  @override
  void initState() {
    super.initState();
    restaurant = widget.restaurant;
    _restaurantsService = di.getIt<RestaurantsService>();
    // Проверяем статус избранного
    _checkFavoriteStatus();
    // Добавляем основное изображение
    if (restaurant.imageUrl.isNotEmpty) {
      _restaurantImages.add(restaurant.imageUrl);
    }
    // Добавляем мок фотографии
    _restaurantImages.addAll([
      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
      'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
      'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
    ]);
    _startImageAutoScroll();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isFavorite = await _restaurantsService.checkIsFavorite(
        restaurant.id,
      );
      if (mounted) {
        setState(() {
          restaurant.isFavorite = isFavorite;
        });
      }
    } catch (e) {
      // Игнорируем ошибки проверки статуса
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isFavoriteLoading) return;

    setState(() {
      _isFavoriteLoading = true;
    });

    try {
      bool success;
      if (restaurant.isFavorite) {
        success = await _restaurantsService.removeFromFavorites(restaurant.id);
        if (success && mounted) {
          ModernSnackBar.showSuccess(context, message: 'Удалено из избранного');
        }
      } else {
        success = await _restaurantsService.addToFavorites(restaurant.id);
        if (success && mounted) {
          ModernSnackBar.showSuccess(context, message: 'Добавлено в избранное');
        }
      }

      if (success && mounted) {
        setState(() {
          restaurant.isFavorite = !restaurant.isFavorite;
        });
      } else if (mounted) {
        ModernSnackBar.showError(
          context,
          message: 'Не удалось изменить статус избранного',
        );
      }
    } catch (e) {
      if (mounted) {
        ModernSnackBar.showError(
          context,
          message: 'Ошибка при изменении избранного',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFavoriteLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _startImageAutoScroll() {
    if (_restaurantImages.length > 1) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _imagePageController.hasClients) {
          final nextPage = (_currentImageIndex + 1) % _restaurantImages.length;
          _imagePageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
          _startImageAutoScroll();
        }
      });
    }
  }

  void _openInMaps() async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${restaurant.latitude},${restaurant.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _callRestaurant() async {
    final url = Uri.parse('tel:+998901234567');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showAddReviewDialog() {
    _userRating = 5.0;
    _reviewController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Добавить отзыв',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ваша оценка',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      StatefulBuilder(
                        builder: (context, setState) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _userRating = (index + 1).toDouble();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  index < _userRating.round()
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  size: 40,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Ваш отзыв',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reviewController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Напишите ваш отзыв...',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_reviewController.text.trim().isNotEmpty) {
                              Navigator.pop(context);
                              ModernSnackBar.showSuccess(
                                context,
                                message: 'Отзыв добавлен!',
                              );
                              _reviewController.clear();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Отправить отзыв',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
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

  @override
  Widget build(BuildContext context) {
    final position = LatLng(restaurant.latitude, restaurant.longitude);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth >= 600;

    // Адаптивные значения
    final contentPadding = isSmallScreen ? 16.0 : (isTablet ? 32.0 : 20.0);
    final cardPadding = isSmallScreen ? 18.0 : (isTablet ? 28.0 : 20.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Современный AppBar с изображением
          SliverAppBar(
            expandedHeight: isSmallScreen ? 300 : (isTablet ? 450 : 350),
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: EdgeInsets.all(isTablet ? 12 : 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: isTablet ? 22 : 18,
                ),
                color: const Color(0xFF111827),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.all(isTablet ? 12 : 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: _isFavoriteLoading
                      ? SizedBox(
                          width: isTablet ? 24 : 20,
                          height: isTablet ? 24 : 20,
                          child: const CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          restaurant.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: isTablet ? 24 : 20,
                          color: restaurant.isFavorite
                              ? Colors.red
                              : const Color(0xFF111827),
                        ),
                  onPressed: _toggleFavorite,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _restaurantImages.isEmpty
                  ? Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.restaurant_rounded,
                          size: 100,
                          color: Colors.white70,
                        ),
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        PageView.builder(
                          controller: _imagePageController,
                          itemCount: _restaurantImages.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              _restaurantImages[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFEF4444),
                                      Color(0xFFF87171),
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.restaurant_rounded,
                                    size: 100,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Градиентное затемнение
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.3, 0.7, 1.0],
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                        // Индикатор страниц
                        if (_restaurantImages.length > 1)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _restaurantImages.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  width: _currentImageIndex == index ? 32 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == index
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: _currentImageIndex == index
                                        ? [
                                            BoxShadow(
                                              color: Colors.white.withOpacity(
                                                0.5,
                                              ),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          // Контент
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Основная информация в карточке
                Container(
                      margin: EdgeInsets.fromLTRB(
                        contentPadding,
                        0,
                        contentPadding,
                        isSmallScreen ? 12 : (isTablet ? 20 : 16),
                      ),
                      padding: EdgeInsets.all(cardPadding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
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
                                      restaurant.name,
                                      style: TextStyle(
                                        fontSize: isSmallScreen
                                            ? 20
                                            : (isTablet ? 28 : 24),
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF111827),
                                        height: 1.2,
                                      ),
                                      maxLines: isTablet ? 3 : 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: isSmallScreen ? 10 : 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isSmallScreen ? 10 : 12,
                                            vertical: isSmallScreen ? 5 : 6,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFFEF4444),
                                                Color(0xFFF87171),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.star_rounded,
                                                color: Colors.white,
                                                size: isSmallScreen ? 14 : 16,
                                              ),
                                              SizedBox(
                                                width: isSmallScreen ? 4 : 6,
                                              ),
                                              Text(
                                                restaurant.rating
                                                    .toStringAsFixed(1),
                                                style: TextStyle(
                                                  fontSize: isSmallScreen
                                                      ? 12
                                                      : 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: isSmallScreen ? 8 : 12),
                                        Flexible(
                                          child: Text(
                                            '${restaurant.reviewCount} отзывов',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 12 : 14,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
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
                          SizedBox(
                            height: isSmallScreen ? 16 : (isTablet ? 24 : 20),
                          ),
                          // Адрес и время работы
                          _InfoItem(
                            icon: Icons.location_on_rounded,
                            iconColor: const Color(0xFFEF4444),
                            title: 'Адрес',
                            value: restaurant.address,
                            isSmallScreen: isSmallScreen,
                            isTablet: isTablet,
                          ),
                          SizedBox(
                            height: isSmallScreen ? 12 : (isTablet ? 20 : 16),
                          ),
                          _InfoItem(
                            icon: Icons.access_time_rounded,
                            iconColor: const Color(0xFF6366F1),
                            title: 'Режим работы',
                            value: restaurant.workingHours,
                            isSmallScreen: isSmallScreen,
                            isTablet: isTablet,
                          ),
                          SizedBox(
                            height: isSmallScreen ? 12 : (isTablet ? 20 : 16),
                          ),
                          _InfoItem(
                            icon: Icons.restaurant_menu_rounded,
                            iconColor: const Color(0xFF10B981),
                            title: 'Кухня',
                            value: restaurant.cuisine,
                            isSmallScreen: isSmallScreen,
                            isTablet: isTablet,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 10 : 12,
                                  vertical: isSmallScreen ? 5 : 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEF4444),
                                      Color(0xFFF87171),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  restaurant.priceRange,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 8 : 12),
                              if (restaurant.distance != null)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 10 : 12,
                                    vertical: isSmallScreen ? 5 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.navigation_rounded,
                                        size: isSmallScreen ? 12 : 14,
                                        color: Colors.grey.shade700,
                                      ),
                                      SizedBox(width: isSmallScreen ? 4 : 6),
                                      Text(
                                        '${restaurant.distance!.toStringAsFixed(1)} км',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                // Кнопки действий
                Padding(
                      padding: EdgeInsets.symmetric(horizontal: contentPadding),
                      child: isTablet
                          ? Row(
                              children: [
                                Expanded(
                                  child: _ModernActionButton(
                                    icon: Icons.directions_rounded,
                                    label: 'Маршрут',
                                    gradient: const [
                                      Color(0xFFEF4444),
                                      Color(0xFFF87171),
                                    ],
                                    onTap: _openInMaps,
                                    isSmallScreen: isSmallScreen,
                                    isTablet: isTablet,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _ModernActionButton(
                                    icon: Icons.phone_rounded,
                                    label: 'Позвонить',
                                    gradient: const [
                                      Color(0xFF10B981),
                                      Color(0xFF059669),
                                    ],
                                    onTap: _callRestaurant,
                                    isSmallScreen: isSmallScreen,
                                    isTablet: isTablet,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: _ModernActionButton(
                                    icon: Icons.share_rounded,
                                    label: 'Поделиться',
                                    gradient: const [
                                      Color(0xFFF59E0B),
                                      Color(0xFFEF4444),
                                    ],
                                    onTap: () {
                                      // TODO: Поделиться
                                    },
                                    isSmallScreen: isSmallScreen,
                                    isTablet: isTablet,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _ModernActionButton(
                                    icon: Icons.directions_rounded,
                                    label: 'Маршрут',
                                    gradient: const [
                                      Color(0xFFEF4444),
                                      Color(0xFFF87171),
                                    ],
                                    onTap: _openInMaps,
                                    isSmallScreen: isSmallScreen,
                                    isTablet: isTablet,
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 8 : 12),
                                Expanded(
                                  child: _ModernActionButton(
                                    icon: Icons.phone_rounded,
                                    label: 'Позвонить',
                                    gradient: const [
                                      Color(0xFF10B981),
                                      Color(0xFF059669),
                                    ],
                                    onTap: _callRestaurant,
                                    isSmallScreen: isSmallScreen,
                                    isTablet: isTablet,
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 8 : 12),
                                Expanded(
                                  child: _ModernActionButton(
                                    icon: Icons.share_rounded,
                                    label: 'Поделиться',
                                    gradient: const [
                                      Color(0xFFF59E0B),
                                      Color(0xFFEF4444),
                                    ],
                                    onTap: () {
                                      // TODO: Поделиться
                                    },
                                    isSmallScreen: isSmallScreen,
                                    isTablet: isTablet,
                                  ),
                                ),
                              ],
                            ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 300.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                SizedBox(height: isSmallScreen ? 16 : (isTablet ? 24 : 20)),
                // Мини карта
                Container(
                      margin: EdgeInsets.symmetric(horizontal: contentPadding),
                      height: isSmallScreen ? 180 : (isTablet ? 280 : 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: position,
                                zoom: 15.0,
                              ),
                              mapType: MapType.normal,
                              zoomControlsEnabled: false,
                              zoomGesturesEnabled: false,
                              scrollGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                              myLocationButtonEnabled: false,
                              markers: {
                                Marker(
                                  markerId: MarkerId(
                                    'restaurant_${restaurant.id}',
                                  ),
                                  position: position,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed,
                                  ),
                                ),
                              },
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                elevation: 4,
                                shadowColor: Colors.black.withOpacity(0.2),
                                child: InkWell(
                                  onTap: _openInMaps,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: const Icon(
                                      Icons.open_in_new_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 400.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                      delay: 400.ms,
                      curve: Curves.easeOut,
                    ),
                SizedBox(height: isSmallScreen ? 16 : 20),
                // Рекламный блок
                Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                      ),
                      child: _ModernAdBanner(
                        title: _ads[0]['title'] as String,
                        subtitle: _ads[0]['subtitle'] as String,
                        icon: _ads[0]['icon'] as IconData,
                        gradient: (_ads[0]['bgGradient'] as List<int>)
                            .map((c) => Color(c))
                            .toList(),
                        isSmallScreen: isSmallScreen,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 500.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                      delay: 500.ms,
                      curve: Curves.easeOut,
                    ),
                SizedBox(height: isSmallScreen ? 20 : 24),
                // Особенности ресторана
                Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: isSmallScreen ? 20 : 24,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 12),
                          Text(
                            'Особенности',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 600.ms)
                    .slideX(begin: -0.2, end: 0, curve: Curves.easeOut),
                SizedBox(height: isSmallScreen ? 12 : 16),
                ...restaurant.features.map((feature) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 20,
                    ),
                    child:
                        Container(
                              margin: EdgeInsets.only(
                                bottom: isSmallScreen ? 10 : 12,
                              ),
                              padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.grey.shade100,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: isSmallScreen ? 44 : 52,
                                    height: isSmallScreen ? 44 : 52,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFEF4444),
                                          Color(0xFFF87171),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFEF4444,
                                          ).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _getFeatureIcon(feature),
                                      color: Colors.white,
                                      size: isSmallScreen ? 22 : 26,
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 10 : 14),
                                  Expanded(
                                    child: Text(
                                      feature,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 15 : 17,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF111827),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(
                              duration: 500.ms,
                              delay:
                                  (700 +
                                          restaurant.features.indexOf(feature) *
                                              100)
                                      .ms,
                            )
                            .slideX(
                              begin: -0.1,
                              end: 0,
                              delay:
                                  (700 +
                                          restaurant.features.indexOf(feature) *
                                              100)
                                      .ms,
                              curve: Curves.easeOut,
                            ),
                  );
                }),
                if (restaurant.features.isEmpty) ...[
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 16 : 20,
                    ),
                    padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: isSmallScreen ? 40 : 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Информация об особенностях отсутствует',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                SizedBox(height: isSmallScreen ? 20 : 24),
                // Описание
                if (restaurant.description.isNotEmpty) ...[
                  Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 20,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: isSmallScreen ? 18 : 22,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFFEF4444),
                                    Color(0xFFF87171),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 10 : 12),
                            Flexible(
                              child: Text(
                                'Описание',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 1000.ms)
                      .slideX(begin: -0.2, end: 0, curve: Curves.easeOut),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 20,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.shade100,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            restaurant.description,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.grey.shade800,
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 1100.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                ],
                // Дополнительная информация
                Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: isSmallScreen ? 18 : 22,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 12),
                          Flexible(
                            child: Text(
                              'Дополнительная информация',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF111827),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 1200.ms)
                    .slideX(begin: -0.2, end: 0, curve: Curves.easeOut),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                      ),
                      child: Column(
                        children: [
                          _ModernInfoRow(
                            icon: Icons.category_rounded,
                            label: 'Категория',
                            value: restaurant.category,
                            gradient: const [
                              Color(0xFFEF4444),
                              Color(0xFFF87171),
                            ],
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          _ModernInfoRow(
                            icon: Icons.map_rounded,
                            label: 'Координаты',
                            value:
                                '${restaurant.latitude.toStringAsFixed(6)}, ${restaurant.longitude.toStringAsFixed(6)}',
                            gradient: const [
                              Color(0xFF10B981),
                              Color(0xFF059669),
                            ],
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          _ModernInfoRow(
                            icon: Icons.phone_rounded,
                            label: 'Телефон',
                            value: '+998 90 123 45 67',
                            onTap: _callRestaurant,
                            gradient: const [
                              Color(0xFFF59E0B),
                              Color(0xFFEF4444),
                            ],
                            isSmallScreen: isSmallScreen,
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 1300.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                SizedBox(height: isSmallScreen ? 16 : 20),
                // Второй рекламный блок
                Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                      ),
                      child: _ModernAdBanner(
                        title: _ads[1]['title'] as String,
                        subtitle: _ads[1]['subtitle'] as String,
                        icon: _ads[1]['icon'] as IconData,
                        gradient: (_ads[1]['bgGradient'] as List<int>)
                            .map((c) => Color(c))
                            .toList(),
                        isSmallScreen: isSmallScreen,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 1400.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                      delay: 1400.ms,
                      curve: Curves.easeOut,
                    ),
                SizedBox(height: isSmallScreen ? 20 : 24),
                // Отзывы
                Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: isSmallScreen ? 18 : 22,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFFEF4444),
                                      Color(0xFFF87171),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              SizedBox(width: isSmallScreen ? 10 : 12),
                              Text(
                                'Отзывы',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: _showAddReviewDialog,
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: Text(
                                  'Добавить',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 8 : 12,
                                    vertical: isSmallScreen ? 6 : 8,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Показать все отзывы
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 8 : 12,
                                    vertical: isSmallScreen ? 6 : 8,
                                  ),
                                ),
                                child: Text(
                                  'Все',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 1500.ms)
                    .slideX(begin: -0.2, end: 0, curve: Curves.easeOut),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                      ),
                      child: _ModernReviewCard(
                        userName: 'Иван Петров',
                        rating: 5.0,
                        text:
                            'Отличный ресторан! Вкусная еда, быстрое обслуживание. Обязательно вернусь!',
                        date: DateTime.now().subtract(const Duration(days: 2)),
                        isSmallScreen: isSmallScreen,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 1600.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                SizedBox(height: isSmallScreen ? 10 : 12),
                Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                      ),
                      child: _ModernReviewCard(
                        userName: 'Мария Сидорова',
                        rating: 4.5,
                        text:
                            'Хорошая кухня и атмосфера. Единственный минус - долгое ожидание блюд в выходные.',
                        date: DateTime.now().subtract(const Duration(days: 5)),
                        isSmallScreen: isSmallScreen,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 1700.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFeatureIcon(String feature) {
    switch (feature.toLowerCase()) {
      case 'wi-fi':
      case 'wifi':
        return Icons.wifi_rounded;
      case 'парковка':
        return Icons.local_parking_rounded;
      case 'доставка':
        return Icons.delivery_dining_rounded;
      case 'терраса':
        return Icons.deck_rounded;
      case 'детское меню':
        return Icons.child_care_rounded;
      case 'живая музыка':
        return Icons.music_note_rounded;
      case 'бар':
        return Icons.local_bar_rounded;
      case 'vip-зал':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }
}

// Виджеты для детальной страницы ресторана

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.isSmallScreen = false,
    this.isTablet = false,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Widget? badge;
  final bool isSmallScreen;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : (isTablet ? 14 : 10)),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: isSmallScreen ? 18 : (isTablet ? 24 : 20),
            color: iconColor,
          ),
        ),
        SizedBox(width: isSmallScreen ? 10 : (isTablet ? 16 : 12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : (isTablet ? 14 : 12),
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: isTablet ? 6 : 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : (isTablet ? 18 : 16),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                      maxLines: isTablet ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null) badge!,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModernActionButton extends StatelessWidget {
  const _ModernActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
    this.isSmallScreen = false,
    this.isTablet = false,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool isSmallScreen;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 14 : (isTablet ? 20 : 16),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: isSmallScreen ? 22 : (isTablet ? 28 : 24),
              ),
              SizedBox(height: isSmallScreen ? 6 : (isTablet ? 10 : 8)),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : (isTablet ? 16 : 14),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernAdBanner extends StatelessWidget {
  const _ModernAdBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.isSmallScreen = false,
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
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 18 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isSmallScreen ? 28 : 32,
                ),
              ),
              SizedBox(width: isSmallScreen ? 14 : 16),
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
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 4 : 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: isSmallScreen ? 18 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernInfoRow extends StatelessWidget {
  const _ModernInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    this.onTap,
    this.isSmallScreen = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;
  final VoidCallback? onTap;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isSmallScreen ? 40 : 44,
            height: isSmallScreen ? 40 : 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: gradient[0].withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: isSmallScreen ? 20 : 22,
              color: Colors.white,
            ),
          ),
          SizedBox(width: isSmallScreen ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 3 : 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: isSmallScreen ? 16 : 18,
            ),
        ],
      ),
    );
  }
}

class _ModernReviewCard extends StatelessWidget {
  const _ModernReviewCard({
    required this.userName,
    required this.rating,
    required this.text,
    required this.date,
    this.isSmallScreen = false,
  });

  final String userName;
  final double rating;
  final String text;
  final DateTime date;
  final bool isSmallScreen;

  String _formatDate(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${_pluralize(difference.inDays, 'день', 'дня', 'дней')} назад';
    } else {
      return '${time.day}.${time.month}.${time.year}';
    }
  }

  String _pluralize(int count, String one, String few, String many) {
    if (count % 10 == 1 && count % 100 != 11) return one;
    if (count % 10 >= 2 &&
        count % 10 <= 4 &&
        (count % 100 < 10 || count % 100 >= 20)) {
      return few;
    }
    return many;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 40 : 44,
                height: isSmallScreen ? 40 : 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    userName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 3 : 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              index < rating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: isSmallScreen ? 12 : 14,
                              color: Colors.amber.shade700,
                            ),
                          );
                        }),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Flexible(
                          child: Text(
                            _formatDate(date),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
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
          SizedBox(height: isSmallScreen ? 10 : 12),
          Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: Colors.grey.shade800,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
