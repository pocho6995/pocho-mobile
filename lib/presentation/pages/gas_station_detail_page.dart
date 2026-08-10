import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/gas_station.dart';
import '../../domain/repositories/gas_station_repository.dart';
import '../../presentation/bloc/gas_station_detail/gas_station_detail_bloc.dart';
import '../../presentation/bloc/gas_station_detail/gas_station_detail_event.dart';
import '../../presentation/bloc/gas_station_detail/gas_station_detail_state.dart';
import '../../widgets/modern_bottom_sheet.dart';
import '../../widgets/modern_snackbar.dart';
import '../../widgets/safe_network_image.dart';
import '../../presentation/widgets/advertisement_banner.dart';
import '../../presentation/widgets/advertisement_placeholder.dart';
import '../../services/advertisement_service.dart';
import '../../services/stations_service.dart';
import '../../domain/entities/advertisement.dart';
import '../../di/injection_container.dart' as di;

/// Страница детальной информации о заправочной станции
class GasStationDetailPage extends StatefulWidget {
  const GasStationDetailPage({super.key, required this.stationId});

  final int stationId;

  static const String routeName = '/gas-station-detail';

  @override
  State<GasStationDetailPage> createState() => _GasStationDetailPageState();
}

class _GasStationDetailPageState extends State<GasStationDetailPage> {
  late final AdvertisementService _advertisementService;
  late final StationsService _stationsService;
  List<AdvertisementEntity> _gasStationDetailAds = [];
  bool _isFavorite = false;
  bool _isFavoriteLoading = false;

  @override
  void initState() {
    super.initState();
    _advertisementService = AdvertisementService();
    _stationsService = di.getIt<StationsService>();
    _loadAdvertisements();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final isFavorite = await _stationsService.checkIsFavorite(
        widget.stationId,
      );
      if (mounted) {
        setState(() {
          _isFavorite = isFavorite;
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
      if (_isFavorite) {
        success = await _stationsService.removeFromFavorites(widget.stationId);
        if (success && mounted) {
          ModernSnackBar.showSuccess(context, message: 'Удалено из избранного');
        }
      } else {
        success = await _stationsService.addToFavorites(widget.stationId);
        if (success && mounted) {
          ModernSnackBar.showSuccess(context, message: 'Добавлено в избранное');
        }
      }

      if (success && mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
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

  Future<void> _loadAdvertisements() async {
    try {
      final ads = await _advertisementService.getAdvertisementsForPosition(
        'gas_stations_list',
      );

      if (mounted) {
        setState(() {
          _gasStationDetailAds = ads;
        });
      }
    } catch (e) {
      // Игнорируем ошибки загрузки рекламы
    }
  }

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} сум';
  }

  String _formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  void _openInMaps(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          di.getIt<GasStationDetailBloc>()
            ..add(LoadGasStationDetailEvent(widget.stationId)),
      child: Scaffold(
        body: BlocConsumer<GasStationDetailBloc, GasStationDetailState>(
          listener: (context, state) {
            if (state is GasStationDetailError) {
              ModernSnackBar.showError(context, message: state.message);
            } else if (state is GasStationDetailLoaded) {
              // Можно показать успешное сообщение при обновлении
            }
          },
          builder: (context, state) {
            if (state is GasStationDetailLoading) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFF1565C0)),
                ),
              );
            } else if (state is GasStationDetailError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Ошибка')),
                body: Center(
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
                        onPressed: () {
                          context.read<GasStationDetailBloc>().add(
                            LoadGasStationDetailEvent(widget.stationId),
                          );
                        },
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is GasStationDetailLoaded) {
              return _buildLoadedState(context, state.station);
            }

            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF1565C0)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, GasStation station) {
    final mainPhoto =
        station.mainPhoto ??
        (station.photos.isNotEmpty ? station.photos.first.photoUrl : null);
    final isLoading =
        context.watch<GasStationDetailBloc>().state
            is GasStationDetailUpdatingPrices ||
        context.watch<GasStationDetailBloc>().state
            is GasStationDetailCreatingReview ||
        context.watch<GasStationDetailBloc>().state
            is GasStationDetailUploadingPhoto;

    return Scaffold(
      extendBodyBehindAppBar: false,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar с изображением
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  SafeNetworkImage(
                    imageUrl: mainPhoto,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1565C0),
                            const Color(0xFF42A5F5),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_gas_station,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    errorWidget: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1565C0),
                            const Color(0xFF42A5F5),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.local_gas_station,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Градиентный оверлей
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Кнопка избранного
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _isFavoriteLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _isFavorite ? Colors.red : Colors.white,
                        ),
                  onPressed: _toggleFavorite,
                  tooltip: _isFavorite
                      ? 'Удалить из избранного'
                      : 'Добавить в избранное',
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms).scale(),
              // Кнопка редактирования цен
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _showEditPricesDialog(context, station),
                  tooltip: 'Редактировать цены',
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms).scale(),
            ],
          ),
          // Контент
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Карточка с основной информацией
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
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
                            child:
                                Text(
                                      station.name,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF111827),
                                        letterSpacing: -0.5,
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(duration: 400.ms, delay: 100.ms)
                                    .slideY(begin: -0.2, end: 0),
                          ),
                          const SizedBox(width: 10),
                          Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1565C0),
                                      Color(0xFF42A5F5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF1565C0,
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
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatRating(station.rating),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: 200.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Адрес
                      Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF1565C0,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.location_on_rounded,
                                  size: 18,
                                  color: const Color(0xFF1565C0),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  station.address,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1565C0),
                                      Color(0xFF42A5F5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _openInMaps(
                                      station.latitude,
                                      station.longitude,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.map,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Маршрут',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 300.ms)
                          .slideX(begin: -0.1, end: 0),
                      const SizedBox(height: 12),
                      // Информация о работе
                      if (station.is24_7 || station.workingHours != null)
                        Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: station.is24_7
                                      ? [
                                          Colors.green.shade50,
                                          Colors.green.shade100.withOpacity(
                                            0.5,
                                          ),
                                        ]
                                      : [
                                          Colors.grey.shade50,
                                          Colors.grey.shade100.withOpacity(0.5),
                                        ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: station.is24_7
                                      ? Colors.green.shade200
                                      : Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: station.is24_7
                                          ? Colors.green.shade100
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.access_time_rounded,
                                      color: station.is24_7
                                          ? Colors.green.shade700
                                          : Colors.grey.shade600,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      station.is24_7
                                          ? 'Работает круглосуточно'
                                          : station.workingHours ??
                                                'Режим работы не указан',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: station.is24_7
                                            ? Colors.green.shade800
                                            : Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 400.ms)
                            .slideX(begin: 0.1, end: 0),
                    ],
                  ),
                ),
                // Мини-карта
                Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  station.latitude,
                                  station.longitude,
                                ),
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
                                    'gas_station_${station.id}',
                                  ),
                                  position: LatLng(
                                    station.latitude,
                                    station.longitude,
                                  ),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueBlue,
                                  ),
                                ),
                              },
                            ),
                            // Кнопка для открытия карты
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _openInMaps(
                                    station.latitude,
                                    station.longitude,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1565C0),
                                          Color(0xFF42A5F5),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF1565C0,
                                          ).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(
                                          Icons.map_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Открыть карту',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
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
                    .fadeIn(duration: 400.ms, delay: 450.ms)
                    .scale(begin: const Offset(0.95, 0.95)),
                const SizedBox(height: 12),
                // Рекламные блоки из API (первый)
                if (_gasStationDetailAds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child:
                        AdvertisementBanner(
                              advertisement: _gasStationDetailAds[0],
                              height: 120,
                            )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 500.ms)
                            .scale(begin: const Offset(0.95, 0.95)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AdvertisementPlaceholder(height: 120)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 500.ms)
                        .scale(begin: const Offset(0.95, 0.95)),
                  ),
                const SizedBox(height: 12),
                // Цены на топливо
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1565C0),
                                      Color(0xFF42A5F5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.local_gas_station_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Цены на топливо',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF111827),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 500.ms)
                          .slideY(begin: -0.1, end: 0),
                      const SizedBox(height: 12),
                      if (station.fuelPrices.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.local_gas_station_outlined,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Цены не указаны',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 600.ms)
                      else
                        ...station.fuelPrices.asMap().entries.map((entry) {
                          final index = entry.key;
                          final fuelPrice = entry.value;
                          return Container(
                                margin: EdgeInsets.only(
                                  bottom: index < station.fuelPrices.length - 1
                                      ? 8
                                      : 0,
                                ),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(
                                              0xFF1565C0,
                                            ).withOpacity(0.1),
                                            const Color(
                                              0xFF42A5F5,
                                            ).withOpacity(0.1),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.local_gas_station_rounded,
                                        color: Color(0xFF1565C0),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        fuelPrice.fuelType,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF1565C0),
                                            Color(0xFF42A5F5),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _formatPrice(fuelPrice.price),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(
                                duration: 400.ms,
                                delay: (600 + index * 80).ms,
                              )
                              .slideX(
                                begin: 0.2,
                                end: 0,
                                delay: (600 + index * 80).ms,
                              );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Рекламные блоки из API (второй)
                if (_gasStationDetailAds.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child:
                        AdvertisementBanner(
                              advertisement: _gasStationDetailAds[1],
                              height: 120,
                            )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 700.ms)
                            .scale(begin: const Offset(0.95, 0.95)),
                  )
                else if (_gasStationDetailAds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: AdvertisementPlaceholder(height: 120)
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 700.ms)
                        .scale(begin: const Offset(0.95, 0.95)),
                  ),
                if (_gasStationDetailAds.length > 1 ||
                    _gasStationDetailAds.isEmpty)
                  const SizedBox(height: 12),
                // Отзывы
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFF9800),
                                          Color(0xFFFFB74D),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.comment_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Отзывы',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF9800),
                                      Color(0xFFFFB74D),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showAddReviewDialog(
                                      context,
                                      station.id,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.add,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Добавить',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: 700.ms)
                          .slideY(begin: -0.1, end: 0),
                      const SizedBox(height: 16),
                      if (station.reviews.isEmpty)
                        Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.comment_outlined,
                                      size: 48,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Пока нет отзывов',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Будьте первым, кто оставит отзыв',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 900.ms)
                            .scale(begin: const Offset(0.9, 0.9))
                      else
                        ...station.reviews.asMap().entries.map((entry) {
                          final index = entry.key;
                          final review = entry.value;
                          return Container(
                                margin: EdgeInsets.only(
                                  bottom: index < station.reviews.length - 1
                                      ? 12
                                      : 0,
                                ),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        SafeAvatar(
                                          imageUrl: review.userAvatar,
                                          radius: 20,
                                          backgroundColor: Colors.grey.shade200,
                                          placeholderText:
                                              review.userName ?? 'U',
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                review.userName ??
                                                    'Пользователь',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF111827),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _formatDate(review.createdAt),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withOpacity(
                                              0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(5, (index) {
                                              return Icon(
                                                index < review.rating
                                                    ? Icons.star_rounded
                                                    : Icons
                                                          .star_outline_rounded,
                                                size: 12,
                                                color: index < review.rating
                                                    ? Colors.amber
                                                    : Colors.grey.shade300,
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (review.comment != null &&
                                        review.comment!.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          review.comment!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(
                                duration: 400.ms,
                                delay: (900 + index * 80).ms,
                              )
                              .slideX(
                                begin: 0.2,
                                end: 0,
                                delay: (900 + index * 80).ms,
                              );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isLoading
          ? FloatingActionButton.extended(
              onPressed: null,
              backgroundColor: const Color(0xFF1565C0),
              icon: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              label: const Text(
                'Сохранение...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).scale()
          : null,
    );
  }

  void _showEditPricesDialog(BuildContext context, GasStation station) {
    final priceControllers = <String, TextEditingController>{};

    // Инициализируем контроллеры для существующих цен
    for (final fuelPrice in station.fuelPrices) {
      priceControllers[fuelPrice.fuelType] = TextEditingController(
        text: fuelPrice.price.toStringAsFixed(0),
      );
    }

    // Добавляем контроллеры для всех типов топлива
    const fuelTypes = ['AI-80', 'AI-91', 'AI-95', 'AI-98', 'Дизель', 'Газ'];
    for (final fuelType in fuelTypes) {
      if (!priceControllers.containsKey(fuelType)) {
        priceControllers[fuelType] = TextEditingController();
      }
    }

    // Сохраняем родительский контекст для доступа к BlocProvider
    final blocContext = context;

    ModernBottomSheet.show(
      context: context,
      title: 'Редактировать цены',
      showCloseButton: true,
      isScrollControlled: true,
      child: StatefulBuilder(
        builder: (dialogContext, setState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Компактная сетка для цен
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: fuelTypes.length,
                  itemBuilder: (context, index) {
                    final fuelType = fuelTypes[index];
                    final controller = priceControllers[fuelType]!;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child:
                          TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  labelText: fuelType,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade400,
                                  ),
                                  suffixText: 'сум',
                                  suffixStyle: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                delay: (index * 50).ms,
                              ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                      onPressed: () async {
                        final fuelPrices = <FuelPriceInput>[];

                        for (final fuelType in fuelTypes) {
                          final controller = priceControllers[fuelType]!;
                          final text = controller.text.trim();
                          if (text.isNotEmpty) {
                            final price = double.tryParse(text);
                            if (price != null && price > 0) {
                              fuelPrices.add(
                                FuelPriceInput(
                                  fuelType: fuelType,
                                  price: price,
                                ),
                              );
                            }
                          }
                        }

                        if (fuelPrices.isEmpty) {
                          ModernSnackBar.showError(
                            dialogContext,
                            message: 'Введите хотя бы одну цену',
                          );
                          return;
                        }

                        Navigator.pop(dialogContext);

                        // Используем родительский контекст для доступа к BlocProvider
                        blocContext.read<GasStationDetailBloc>().add(
                          UpdateFuelPricesEvent(
                            stationId: station.id,
                            fuelPrices: fuelPrices,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Сохранить',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 400.ms)
                    .scale(begin: const Offset(0.95, 0.95)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddReviewDialog(BuildContext context, int stationId) {
    int rating = 5;
    final commentController = TextEditingController();

    // Сохраняем родительский контекст для доступа к BlocProvider
    final blocContext = context;

    ModernBottomSheet.show(
      context: context,
      title: 'Добавить отзыв',
      showCloseButton: true,
      isScrollControlled: true,
      maxHeight: MediaQuery.of(context).size.height * 0.85,
      child: StatefulBuilder(
        builder: (dialogContext, setState) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Рейтинг
                const Text(
                  'Оцените заправку',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Звезды
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.star_rounded,
                            size: 48,
                            color: index < rating
                                ? const Color(0xFFFFC107) // Ярко-желтый
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),
                // Комментарий
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Комментарий (необязательно)',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF1565C0),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 24),
                // Кнопка отправки
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      // Используем родительский контекст для доступа к BlocProvider
                      blocContext.read<GasStationDetailBloc>().add(
                        CreateReviewEvent(
                          stationId: stationId,
                          rating: rating,
                          comment: commentController.text.trim().isEmpty
                              ? null
                              : commentController.text.trim(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Отправить',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
