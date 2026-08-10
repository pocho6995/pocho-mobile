import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/fuel_station.dart';
import '../widgets/modern_snackbar.dart';

class StationDetailPage extends StatefulWidget {
  const StationDetailPage({super.key, required this.station});

  final FuelStation station;

  @override
  State<StationDetailPage> createState() => _StationDetailPageState();
}

class _StationDetailPageState extends State<StationDetailPage> {
  late FuelStation station;
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;
  final TextEditingController _reviewController = TextEditingController();
  double _userRating = 5.0;

  // Мок фотографии заправки
  final List<String> _stationImages = [];

  // Рекламные блоки
  final List<Map<String, dynamic>> _ads = [
    {
      'title': 'Скидка 15% на мойку',
      'subtitle': 'При заправке от 30 литров',
      'icon': Icons.local_car_wash_rounded,
      'color': [0xFF6366F1, 0xFF8B5CF6],
      'bgGradient': [0xFF6366F1, 0xFF8B5CF6],
    },
    {
      'title': 'Бесплатный кофе',
      'subtitle': 'При заправке от 50 литров',
      'icon': Icons.local_cafe_rounded,
      'color': [0xFFF59E0B, 0xFFEF4444],
      'bgGradient': [0xFFF59E0B, 0xFFEF4444],
    },
  ];

  @override
  void initState() {
    super.initState();
    station = widget.station;
    // Добавляем превью как первую фотографию, если есть
    if (station.preview.isNotEmpty) {
      _stationImages.add(station.preview);
    }
    // Добавляем мок фотографии
    _stationImages.addAll([
      'https://via.placeholder.com/800x600/6366F1/FFFFFF?text=PoCho+Station+1',
      'https://via.placeholder.com/800x600/8B5CF6/FFFFFF?text=PoCho+Station+2',
      'https://via.placeholder.com/800x600/3B82F6/FFFFFF?text=PoCho+Station+3',
    ]);
    _startImageAutoScroll();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _startImageAutoScroll() {
    if (_stationImages.length > 1) {
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _imagePageController.hasClients) {
          final nextPage = (_currentImageIndex + 1) % _stationImages.length;
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

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} сум';
  }

  void _openInMaps() async {
    final coords = station.coordinatesList;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${coords[0]},${coords[1]}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _callStation() async {
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
                              color: Color(0xFF6366F1),
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
                            backgroundColor: const Color(0xFF6366F1),
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
    final coords = station.coordinatesList;
    final position = LatLng(coords[0], coords[1]);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Современный AppBar с изображением
          SliverAppBar(
            expandedHeight: isSmallScreen ? 300 : 350,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: const Color(0xFF111827),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
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
                    station.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: station.isFavorite
                        ? Colors.red
                        : const Color(0xFF111827),
                  ),
                  onPressed: () {
                    setState(() {
                      station.isFavorite = !station.isFavorite;
                    });
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _stationImages.isEmpty
                  ? Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_gas_station_rounded,
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
                          itemCount: _stationImages.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              _stationImages[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
                                    ],
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.local_gas_station_rounded,
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
                        if (_stationImages.length > 1)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _stationImages.length,
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
                        isSmallScreen ? 16 : 20,
                        0,
                        isSmallScreen ? 16 : 20,
                        isSmallScreen ? 12 : 16,
                      ),
                      padding: EdgeInsets.all(isSmallScreen ? 18 : 20),
                      decoration: BoxDecoration(
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
                                      station.name,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 20 : 24,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF111827),
                                        height: 1.2,
                                      ),
                                      maxLines: 2,
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
                                                Color(0xFF10B981),
                                                Color(0xFF059669),
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
                                                station.rating.toStringAsFixed(
                                                  1,
                                                ),
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
                                            '${station.reviewsCount} отзывов',
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
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          // Адрес и время работы
                          _InfoItem(
                            icon: Icons.location_on_rounded,
                            iconColor: const Color(0xFFEF4444),
                            title: 'Адрес',
                            value: station.address,
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          if (station.workingHours.isNotEmpty)
                            _InfoItem(
                              icon: Icons.access_time_rounded,
                              iconColor: const Color(0xFF6366F1),
                              title: 'Режим работы',
                              value: station.workingHours,
                              isSmallScreen: isSmallScreen,
                              badge: station.workingHours == '24/7'
                                  ? Container(
                                      margin: EdgeInsets.only(
                                        left: isSmallScreen ? 6 : 8,
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 6 : 8,
                                        vertical: isSmallScreen ? 3 : 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF10B981),
                                            Color(0xFF059669),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '24/7',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 10 : 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 200.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                // Кнопки действий
                Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ModernActionButton(
                              icon: Icons.directions_rounded,
                              label: 'Маршрут',
                              gradient: const [
                                Color(0xFF6366F1),
                                Color(0xFF8B5CF6),
                              ],
                              onTap: _openInMaps,
                              isSmallScreen: isSmallScreen,
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
                              onTap: _callStation,
                              isSmallScreen: isSmallScreen,
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
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 300.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                SizedBox(height: isSmallScreen ? 16 : 20),
                // Мини карта
                Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                      ),
                      height: isSmallScreen ? 180 : 200,
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
                                  markerId: MarkerId('station_${widget.station.id}'),
                                  position: position,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueViolet,
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
                                      color: Color(0xFF6366F1),
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
                // Цены на топливо
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
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 10 : 12),
                          Text(
                            'Цены на топливо',
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
                ...station.fuelPrices.map((fuel) {
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
                                          Color(0xFF6366F1),
                                          Color(0xFF8B5CF6),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF6366F1,
                                          ).withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.local_gas_station_rounded,
                                      color: Colors.white,
                                      size: isSmallScreen ? 22 : 26,
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 10 : 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          fuel.fuelType,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 15 : 17,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF111827),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: isSmallScreen ? 3 : 4),
                                        Text(
                                          'Обновлено ${_formatTime(fuel.createdAt)}',
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 11 : 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 8 : 10),
                                  Flexible(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 10 : 14,
                                        vertical: isSmallScreen ? 8 : 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF6366F1),
                                            Color(0xFF8B5CF6),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF6366F1,
                                            ).withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        _formatPrice(fuel.price),
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 15 : 17,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(
                              duration: 500.ms,
                              delay:
                                  (700 + station.fuelPrices.indexOf(fuel) * 100)
                                      .ms,
                            )
                            .slideX(
                              begin: -0.1,
                              end: 0,
                              delay:
                                  (700 + station.fuelPrices.indexOf(fuel) * 100)
                                      .ms,
                              curve: Curves.easeOut,
                            ),
                  );
                }),
                if (station.fuelPrices.isEmpty) ...[
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
                            'Информация о ценах отсутствует',
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
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
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
                    .fadeIn(duration: 500.ms, delay: 1000.ms)
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
                            value: station.category.isNotEmpty
                                ? station.category
                                : 'Заправка',
                            gradient: const [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                            ],
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          _ModernInfoRow(
                            icon: Icons.map_rounded,
                            label: 'Координаты',
                            value: station.coordinates,
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
                            onTap: _callStation,
                            gradient: const [
                              Color(0xFFF59E0B),
                              Color(0xFFEF4444),
                            ],
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          _ModernInfoRow(
                            icon: Icons.access_time_rounded,
                            label: 'Режим работы',
                            value: station.workingHours.isNotEmpty
                                ? station.workingHours
                                : 'Не указано',
                            gradient: const [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                            ],
                            isSmallScreen: isSmallScreen,
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 1100.ms)
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
                    .fadeIn(duration: 500.ms, delay: 1200.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                      delay: 1200.ms,
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
                                      Color(0xFF6366F1),
                                      Color(0xFF8B5CF6),
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
                                    color: const Color(0xFF6366F1),
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
                                    color: const Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 1300.ms)
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
                            'Отличная заправка! Всегда чисто, быстрое обслуживание. Цены приемлемые.',
                        date: DateTime.now().subtract(const Duration(days: 2)),
                        isSmallScreen: isSmallScreen,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 1400.ms)
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
                            'Хорошее качество топлива. Единственный минус - иногда очереди.',
                        date: DateTime.now().subtract(const Duration(days: 5)),
                        isSmallScreen: isSmallScreen,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 1500.ms)
                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return 'сегодня';
    } else if (difference.inDays == 1) {
      return 'вчера';
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
}

class _ModernActionButton extends StatelessWidget {
  const _ModernActionButton({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
    this.isSmallScreen = false,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(20),
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
              Icon(icon, color: Colors.white, size: isSmallScreen ? 22 : 26),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
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
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        // TODO: Открыть детали акции
      },
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 18 : 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isSmallScreen ? 52 : 64,
              height: isSmallScreen ? 52 : 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: isSmallScreen ? 26 : 32,
              ),
            ),
            SizedBox(width: isSmallScreen ? 16 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 10 : 12,
                      vertical: isSmallScreen ? 5 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'АКЦИЯ',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 10 : 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 17 : 20,
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
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.95),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: isSmallScreen ? 16 : 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.badge,
    this.isSmallScreen = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final Widget? badge;
  final bool isSmallScreen;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: isSmallScreen ? 18 : 20, color: iconColor),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                      maxLines: 2,
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
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
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
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
