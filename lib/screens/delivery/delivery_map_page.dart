import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../models/delivery/delivery_screen_content.dart';
import '../../utils/location_helper.dart';
import '../../state/app_state.dart';
import 'from_to_address_page.dart';

/// Страница доставки по регионам Узбекистана
class DeliveryMapPage extends StatefulWidget {
  const DeliveryMapPage({super.key});

  static const String routeName = '/delivery-map';

  @override
  State<DeliveryMapPage> createState() => _DeliveryMapPageState();
}

class _DeliveryMapPageState extends State<DeliveryMapPage> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTrackingLocation = false;
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(41.3111, 69.2797), // Ташкент по умолчанию
    zoom: 6, // Увеличенный zoom для показа всей страны
  );

  final DeliveryScreenContent _screenContent = DeliveryScreenContent.defaults;

  @override
  void initState() {
    super.initState();
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
      print('🔍 DeliveryMapPage: Starting location permission request...');
    }

    // Небольшая задержка для гарантии, что контекст готов
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (kDebugMode) {
      print('🔍 DeliveryMapPage: Requesting location permission...');
    }

    // Сначала запрашиваем разрешение
    final hasPermission = await LocationHelper.checkAndRequestPermission();

    if (kDebugMode) {
      print('🔍 DeliveryMapPage: Permission result: $hasPermission');
    }

    if (!mounted) return;

    if (!hasPermission) {
      if (kDebugMode) {
        print('⚠️ DeliveryMapPage: Permission denied, showing snackbar');
      }
      final appState = Provider.of<AppState>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appState.t('delivery_location_permission')),
          duration: Duration(seconds: 4),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (kDebugMode) {
      print('✅ DeliveryMapPage: Permission granted, getting location...');
    }

    // После получения разрешения получаем местоположение
    await _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    if (!mounted) return;

    final position = await LocationHelper.getCurrentLocation();
    if (position != null && mounted) {
      // Анимируем камеру к местоположению пользователя
      if (mounted && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14,
          ),
        );
      }
    }
  }

  void _startLocationTracking() {
    if (!mounted) return;

    if (_isTrackingLocation) {
      _stopLocationTracking();
      return;
    }

    LocationHelper.checkAndRequestPermission().then((granted) {
      if (!mounted) return;

      if (!granted) {
        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                appState.t('delivery_location_permission_required'),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      final positionStream = LocationHelper.getPositionStream(
        desiredAccuracy: LocationAccuracy.high,
        distanceFilter: 10, // Обновлять каждые 10 метров
      );

      if (positionStream != null && mounted) {
        if (mounted) {
          setState(() {
            _isTrackingLocation = true;
          });
        }

        _positionStreamSubscription = positionStream.listen(
          (Position position) {
            if (!mounted) return;

            // Обновляем камеру карты при изменении местоположения
            if (mounted && _mapController != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(position.latitude, position.longitude),
                  14,
                ),
              );
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isTrackingLocation = false;
              });
              if (kDebugMode) {
                print('❌ Location tracking error: $error');
              }
            }
          },
        );
      }
    });
  }

  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    if (mounted) {
      setState(() {
        _isTrackingLocation = false;
      });
    } else {
      // Если виджет уже удален, просто обновляем переменную без setState
      _isTrackingLocation = false;
    }
  }

  /// Найти и показать местоположение пользователя на карте
  Future<void> _findMyLocation() async {
    if (!mounted) return;

    // Получаем ScaffoldMessenger только если виджет еще mounted
    ScaffoldMessengerState? scaffoldMessenger;
    try {
      if (mounted) {
        scaffoldMessenger = ScaffoldMessenger.of(context);
      } else {
        return;
      }
    } catch (e) {
      // Контекст недоступен, выходим
      return;
    }

    // Сначала проверяем и запрашиваем разрешение
    final hasPermission = await LocationHelper.checkAndRequestPermission();
    if (!hasPermission) {
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    appState.t('delivery_location_permission_required_full'),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Показываем индикатор загрузки
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(appState.t('delivery_finding_location')),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Получаем текущее местоположение
    final position = await LocationHelper.getCurrentLocation();

    // Проверяем mounted после асинхронной операции
    if (!mounted) {
      scaffoldMessenger.hideCurrentSnackBar();
      return;
    }

    if (position != null) {
      if (!mounted) {
        scaffoldMessenger.hideCurrentSnackBar();
        return;
      }

      if (mounted) {}

      // Анимируем камеру к местоположению пользователя
      if (mounted && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15, // Более близкий zoom для детального просмотра
          ),
        );

        // Показываем успешное сообщение
        if (mounted) {
          final appState = Provider.of<AppState>(context, listen: false);
          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(appState.t('delivery_location_found')),
                ],
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } else {
      // Показываем ошибку
      if (mounted) {
        final appState = Provider.of<AppState>(context, listen: false);
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(appState.t('delivery_location_failed'))),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Увеличить масштаб карты
  void _zoomIn() {
    if (!mounted || _mapController == null) return;
    _mapController!.animateCamera(CameraUpdate.zoomIn());
  }

  /// Уменьшить масштаб карты
  void _zoomOut() {
    if (!mounted || _mapController == null) return;
    _mapController!.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    // Высота нижней панели примерно 280-320px, добавляем отступ
    final bottomPanelHeight = isSmallScreen ? 280.0 : 320.0;

    return Scaffold(
      body: Stack(
        children: [
          // Карта на фоне
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            zoomGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              if (!mounted) {
                controller.dispose();
                return;
              }
              _mapController = controller;
              // Запускаем получение местоположения и отслеживание асинхронно
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _getUserLocation();
                  // Автоматически запускаем отслеживание местоположения
                  _startLocationTracking();
                }
              });
            },
          ),
          // Кнопка назад (слева вверху)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
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
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    color: const Color(0xFF111827),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms),
            ),
          ),
          // Кнопка "Найти меня" в правом верхнем углу (напротив кнопки назад)
          Positioned(
            right: 16,
            top: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.my_location_rounded),
                  onPressed: _findMyLocation,
                  color: const Color(0xFF1565C0),
                  tooltip: Provider.of<AppState>(
                    context,
                    listen: false,
                  ).t('delivery_find_me'),
                ),
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
            ),
          ),
          // Кнопки управления картой справа (над нижней панелью)
          Positioned(
            right: 16,
            bottom: bottomPanelHeight + 16, // Высота нижней панели + отступ
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Кнопки масштабирования
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Кнопка увеличения
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _zoomIn,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.add_rounded,
                                color: const Color(0xFF1565C0),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        // Разделитель
                        Container(
                          height: 1,
                          color: Colors.grey.shade200,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        // Кнопка уменьшения
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _zoomOut,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.remove_rounded,
                                color: const Color(0xFF1565C0),
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
            ),
          ),
          // Нижняя панель с информацией
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(isSmallScreen),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Индикатор перетаскивания
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Карточка доставки
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: 8,
              ),
              child: _buildDeliveryCard(isSmallScreen),
            ),
            // Информация о сервисном сборе
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 20,
                vertical: 8,
              ),
              child: _buildServiceFeeInfo(isSmallScreen),
            ),
            // Кнопка перехода к форме заказа
            Padding(
              padding: EdgeInsets.only(
                left: isSmallScreen ? 16 : 20,
                right: isSmallScreen ? 16 : 20,
                top: 8,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: _buildOrderButton(isSmallScreen),
            ),
          ],
        ),
      ),
    ).animate().slideY(
      begin: 1,
      end: 0,
      duration: 400.ms,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildDeliveryCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Иконка посылки
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Color(0xFF1565C0),
              size: 28,
            ),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          // Текст (статичные данные)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final appState = Provider.of<AppState>(
                      context,
                      listen: false,
                    );
                    return Text(
                      appState.t('delivery_regions_uzbekistan'),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    );
                  },
                ),
                SizedBox(height: isSmallScreen ? 4 : 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Builder(
                      builder: (context) {
                        final appState = Provider.of<AppState>(
                          context,
                          listen: false,
                        );
                        return Text(
                          appState.t('delivery_time_1_3_days'),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _screenContent.priceFromLabel,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms);
  }

  Widget _buildServiceFeeInfo(bool isSmallScreen) {
    return InkWell(
      onTap: () {
        // TODO: Показать подробную информацию
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF1565C0).withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: const Color(0xFF1565C0),
              size: 18,
            ),
            SizedBox(width: isSmallScreen ? 10 : 12),
            Expanded(
              child: Builder(
                builder: (context) {
                  final appState = Provider.of<AppState>(
                    context,
                    listen: false,
                  );
                  return Text(
                    appState.t('delivery_service_fee_text'),
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFF1565C0),
              size: 14,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 200.ms);
  }

  Widget _buildOrderButton(bool isSmallScreen) {
    return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).pushNamed(FromToAddressPage.routeName);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 16 : 18,
                horizontal: isSmallScreen ? 16 : 20,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 12),
                  Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      return Text(
                        appState.t('delivery_go_to_order_form'),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 300.ms, delay: 300.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          delay: 300.ms,
        );
  }

  @override
  void dispose() {
    // Отменяем отслеживание местоположения
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    // Останавливаем отслеживание без setState
    _isTrackingLocation = false;

    // Освобождаем контроллер карты
    _mapController?.dispose();
    _mapController = null;

    super.dispose();
  }
}
