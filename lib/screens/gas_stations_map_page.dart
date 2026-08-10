import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/entities/gas_station.dart';
import '../domain/repositories/gas_station_repository.dart';
import '../presentation/bloc/gas_stations/gas_stations_bloc.dart';
import '../presentation/bloc/gas_stations/gas_stations_event.dart';
import '../presentation/bloc/gas_stations/gas_stations_state.dart';
import '../presentation/pages/gas_station_detail_page.dart';
import '../di/injection_container.dart' as di;
import '../utils/location_helper.dart';

/// Страница с картой заправочных станций
class GasStationsMapPage extends StatefulWidget {
  const GasStationsMapPage({super.key});

  static const String routeName = '/gas-stations-map';

  @override
  State<GasStationsMapPage> createState() => _GasStationsMapPageState();
}

class _GasStationsMapPageState extends State<GasStationsMapPage> {
  GoogleMapController? _mapController;
  GasStation? _selectedStation;
  Set<Marker> _markers = {};
  Position? _userPosition;
  BitmapDescriptor? _userMarkerIcon;
  BitmapDescriptor? _stationMarkerIcon;
  List<GasStation> _sortedStations = [];
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(41.3111, 69.2797), // Ташкент по умолчанию
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _createCustomMarkers();
    // Добавляем небольшую задержку, чтобы виджет полностью инициализировался
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestLocationPermissionAndGetLocation();
      }
    });
  }

  Future<void> _requestLocationPermissionAndGetLocation() async {
    if (!mounted) return;

    if (kDebugMode) {
      print('🔍 GasStationsMapPage: Starting location permission request...');
    }

    // Небольшая задержка для гарантии, что контекст готов
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (kDebugMode) {
      print('🔍 GasStationsMapPage: Requesting location permission...');
    }

    // Сначала запрашиваем разрешение
    final hasPermission = await LocationHelper.checkAndRequestPermission();

    if (kDebugMode) {
      print('🔍 GasStationsMapPage: Permission result: $hasPermission');
    }

    if (!mounted) return;

    if (!hasPermission) {
      if (kDebugMode) {
        print('⚠️ GasStationsMapPage: Permission denied, showing snackbar');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Для отображения вашего местоположения на карте необходимо разрешение на доступ к геолокации. Пожалуйста, предоставьте разрешение в настройках приложения.',
            ),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (kDebugMode) {
      print('✅ GasStationsMapPage: Permission granted, getting location...');
    }

    // После получения разрешения получаем местоположение
    await _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    if (!mounted) return;

    final position = await LocationHelper.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _userPosition = position;
        _initialCameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14,
        );
      });
    }
  }

  Future<void> _createCustomMarkers() async {
    // Создаем кастомный маркер для пользователя (красный)
    _userMarkerIcon = await _createMarkerIcon(Colors.red, Icons.person);

    // Создаем кастомный маркер для заправок (светло-синий градиент)
    _stationMarkerIcon = await _createMarkerIcon(
      const Color(0xFF64B5F6), // Светло-синий
      Icons.local_gas_station_rounded,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<BitmapDescriptor> _createMarkerIcon(Color color, IconData icon) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = 120.0;

    // Рисуем градиентный круг (внешний)
    final outerPaint = Paint()
      ..shader = ui.Gradient.radial(
        const Offset(size / 2, size / 2),
        size / 2,
        [color.withOpacity(0.3), color.withOpacity(0.1)],
        const [0.0, 1.0],
      );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 5,
      outerPaint,
    );

    // Рисуем основной круг с градиентом
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        const Offset(size / 2, size / 2),
        size / 2 - 10,
        [color, color.withOpacity(0.8)],
        const [0.0, 1.0],
      );
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2 - 10, paint);

    // Рисуем белый круг внутри
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 20,
      whitePaint,
    );

    // Рисуем иконку через TextPainter с Material Icons
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size / 3,
          fontFamily: icon.fontFamily ?? 'MaterialIcons',
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2 - 5, // Смещение для центрирования
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.getIt<GasStationsBloc>()
        ..add(
          LoadGasStationsEvent(
            filterParams: GasStationFilterParams(skip: 0, limit: 1000),
          ),
        ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Заправки на карте'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: BlocConsumer<GasStationsBloc, GasStationsState>(
          listener: (context, state) {
            if (state is GasStationsLoaded) {
              _sortStationsByDistance(state.stations);
              _updateMarkers(_sortedStations);
            }
          },
          builder: (context, state) {
            if (state is GasStationsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is GasStationsError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка загрузки заправок',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<GasStationsBloc>().add(
                          LoadGasStationsEvent(
                            filterParams: GasStationFilterParams(
                              skip: 0,
                              limit: 1000,
                            ),
                          ),
                        );
                      },
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }

            // Определяем начальную позицию камеры
            if (_userPosition != null) {
              _initialCameraPosition = CameraPosition(
                target: LatLng(
                  _userPosition!.latitude,
                  _userPosition!.longitude,
                ),
                zoom: 14,
              );
            } else if (state is GasStationsLoaded &&
                state.stations.isNotEmpty) {
              final firstStation = state.stations.first;
              _initialCameraPosition = CameraPosition(
                target: LatLng(firstStation.latitude, firstStation.longitude),
                zoom: 12,
              );
            }

            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
                  mapType: MapType.normal,
                  zoomControlsEnabled: true,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    if (state is GasStationsLoaded) {
                      _sortStationsByDistance(state.stations);
                      _updateMarkers(_sortedStations);
                    }
                  },
                  onTap: (LatLng position) {
                    // Скрываем информацию при клике на карту
                    setState(() {
                      _selectedStation = null;
                    });
                  },
                ),
                // Информационная панель снизу
                if (_selectedStation != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _StationInfoCard(
                      station: _selectedStation!,
                      userPosition: _userPosition,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          GasStationDetailPage.routeName,
                          arguments: _selectedStation!.id,
                        );
                      },
                      onClose: () {
                        setState(() {
                          _selectedStation = null;
                        });
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _sortStationsByDistance(List<GasStation> stations) {
    if (_userPosition == null) {
      _sortedStations = stations;
      return;
    }

    // Сортируем станции по расстоянию от пользователя
    _sortedStations = List<GasStation>.from(stations);
    _sortedStations.sort((a, b) {
      final distanceA = LocationHelper.calculateDistance(
        _userPosition!.latitude,
        _userPosition!.longitude,
        a.latitude,
        a.longitude,
      );
      final distanceB = LocationHelper.calculateDistance(
        _userPosition!.latitude,
        _userPosition!.longitude,
        b.latitude,
        b.longitude,
      );
      return distanceA.compareTo(distanceB);
    });
  }

  void _updateMarkers(List<GasStation> stations) {
    final markers = <Marker>{};

    // Добавляем маркер пользователя
    if (_userPosition != null && _userMarkerIcon != null) {
      final userMarker = Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
        icon: _userMarkerIcon!,
        infoWindow: const InfoWindow(title: 'Ваше местоположение'),
      );
      markers.add(userMarker);
    }

    // Добавляем маркеры заправок
    for (final station in stations) {
      // Используем кастомный иконку или дефолтную, если еще не создана
      final icon =
          _stationMarkerIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

      // Вычисляем расстояние от пользователя
      String? distanceText;
      if (_userPosition != null) {
        final distance = LocationHelper.calculateDistance(
          _userPosition!.latitude,
          _userPosition!.longitude,
          station.latitude,
          station.longitude,
        );
        distanceText = distance < 1
            ? '${(distance * 1000).toStringAsFixed(0)} м'
            : '${distance.toStringAsFixed(1)} км';
      }

      final marker = Marker(
        markerId: MarkerId('station_${station.id}'),
        position: LatLng(station.latitude, station.longitude),
        icon: icon,
        infoWindow: InfoWindow(
          title: station.name,
          snippet: distanceText != null
              ? '${station.address}\n$distanceText'
              : station.address,
        ),
        onTap: () {
          setState(() {
            _selectedStation = station;
          });
          // Прокручиваем карту к выбранной заправке
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(station.latitude, station.longitude),
              15,
            ),
          );
        },
      );
      markers.add(marker);
    }

    setState(() {
      _markers = markers;
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

/// Виджет карточки информации о заправке
class _StationInfoCard extends StatelessWidget {
  const _StationInfoCard({
    required this.station,
    required this.userPosition,
    required this.onTap,
    required this.onClose,
  });

  final GasStation station;
  final Position? userPosition;
  final VoidCallback onTap;
  final VoidCallback onClose;

  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} сум';
  }

  String _formatRating(double rating) {
    return rating.toStringAsFixed(1);
  }

  String? _getDistanceText() {
    if (userPosition == null) return null;
    final distance = LocationHelper.calculateDistance(
      userPosition!.latitude,
      userPosition!.longitude,
      station.latitude,
      station.longitude,
    );
    return distance < 1
        ? '${(distance * 1000).toStringAsFixed(0)} м'
        : '${distance.toStringAsFixed(1)} км';
  }

  @override
  Widget build(BuildContext context) {
    final distanceText = _getDistanceText();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с кнопкой закрытия
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              station.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Расстояние до заправки
                      if (distanceText != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.navigation_rounded,
                              size: 14,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distanceText,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: onClose,
                color: Colors.grey.shade600,
              ),
            ],
          ),
          // Информация о заправке
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Рейтинг
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatRating(station.rating),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Круглосуточно
                if (station.is24_7)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '24/7',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Отзывы
                Row(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${station.reviewsCount} отзывов',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Цены на топливо
          if (station.fuelPrices.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: station.fuelPrices.take(4).map((fuelPrice) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1565C0).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fuelPrice.fuelType,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatPrice(fuelPrice.price),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Кнопка "Подробнее"
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Подробнее',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
