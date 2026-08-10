import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../di/injection_container.dart' as di;
import '../../services/delivery_tracking_websocket_service.dart';
import '../../repositories/delivery_repository.dart';
import '../../models/delivery/delivery_order.dart';
import '../../widgets/modern_snackbar.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key});

  static const String routeName = '/delivery/order-tracking';

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final DeliveryRepository _deliveryRepository = di.getIt<DeliveryRepository>();
  final DeliveryTrackingWebSocketService _wsService = 
      DeliveryTrackingWebSocketService(tokenStorage: di.getIt());
  
  GoogleMapController? _mapController;
  DeliveryOrder? _order;
  DriverLocation? _driverLocation;
  bool _isLoading = true;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  int? _orderId;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  @override
  void dispose() {
    _wsService.disconnect();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeWebSocket() async {
    // Подключаемся к WebSocket
    _wsService.onConnected = () {
      if (_orderId != null) {
        _wsService.subscribeToOrder(_orderId!);
      }
    };
    
    _wsService.onDriverLocationUpdated = (location) {
      setState(() {
        _driverLocation = location;
        _updateDriverMarker();
      });
    };
    
    _wsService.onOrderStatusUpdated = (orderId, status) {
      _loadOrder();
    };
    
    _wsService.onError = (error) {
      if (mounted) {
        ModernSnackBar.showError(
          context,
          message: 'Ошибка подключения к трекингу: $error',
        );
      }
    };
    
    await _wsService.connect();
  }

  Future<void> _loadOrder() async {
    // Получаем orderId из аргументов
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int) {
      _orderId = args;
    } else if (args is DeliveryOrder) {
      _order = args;
      _orderId = args.id;
    }

    if (_orderId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final order = await _deliveryRepository.getOrder(_orderId!);
      setState(() {
        _order = order;
        _isLoading = false;
      });
      _updateMarkers();
      _centerMap();
      
      // Подписываемся на заказ если WebSocket подключен
      if (_wsService.isConnected) {
        _wsService.subscribeToOrder(_orderId!);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ModernSnackBar.showError(
          context,
          message: 'Не удалось загрузить заказ: $e',
        );
      }
    }
  }

  void _updateMarkers() {
    if (_order == null) return;

    final markers = <Marker>{};

    // Маркер точки отправления
    if (_order!.pickupLatitude != null && _order!.pickupLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(_order!.pickupLatitude!, _order!.pickupLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'Точка отправления',
            snippet: _order!.pickupAddress ?? 'Адрес не указан',
          ),
        ),
      );
    }

    // Маркер точки доставки
    if (_order!.deliveryLatitude != null && _order!.deliveryLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('delivery'),
          position: LatLng(_order!.deliveryLatitude!, _order!.deliveryLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Точка доставки',
            snippet: _order!.deliveryAddress ?? 'Адрес не указан',
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _updateDriverMarker() {
    if (_driverLocation == null) return;

    setState(() {
      _markers = Set.from(_markers)
        ..removeWhere((m) => m.markerId.value == 'driver')
        ..add(
          Marker(
            markerId: const MarkerId('driver'),
            position: LatLng(_driverLocation!.lat, _driverLocation!.lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(
              title: 'Водитель',
              snippet: 'В пути',
            ),
          ),
        );
    });

    // Центрируем карту на водителе
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(_driverLocation!.lat, _driverLocation!.lng),
      ),
    );
  }

  void _centerMap() {
    if (_order == null || 
        _mapController == null ||
        _order!.pickupLatitude == null ||
        _order!.pickupLongitude == null ||
        _order!.deliveryLatitude == null ||
        _order!.deliveryLongitude == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _order!.pickupLatitude! < _order!.deliveryLatitude!
            ? _order!.pickupLatitude!
            : _order!.deliveryLatitude!,
        _order!.pickupLongitude! < _order!.deliveryLongitude!
            ? _order!.pickupLongitude!
            : _order!.deliveryLongitude!,
      ),
      northeast: LatLng(
        _order!.pickupLatitude! > _order!.deliveryLatitude!
            ? _order!.pickupLatitude!
            : _order!.deliveryLatitude!,
        _order!.pickupLongitude! > _order!.deliveryLongitude!
            ? _order!.pickupLongitude!
            : _order!.deliveryLongitude!,
      ),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 360;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Трекинг заказа'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Трекинг заказа'),
        ),
        body: const Center(
          child: Text('Заказ не найден'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Заказ #${_order!.id}',
          style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _order!.pickupLatitude ?? 41.3111,
                _order!.pickupLongitude ?? 69.2797,
              ),
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController = controller;
              _centerMap();
            },
          ),
          // Карточка статуса заказа
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _order!.statusName,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            if (_driverLocation != null)
                              Text(
                                'Водитель в пути',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: Colors.grey.shade600,
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
                .fadeIn(duration: 300.ms)
                .slideY(begin: -0.2, end: 0),
          ),
        ],
      ),
    );
  }
}




