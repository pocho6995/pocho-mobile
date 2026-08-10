import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../di/injection_container.dart' as di;
import '../../models/delivery/delivery_api_tz.dart';
import '../../repositories/delivery_repository.dart';
import '../../widgets/modern_dialog.dart';
import '../../state/app_state.dart';
import 'map_picker_page.dart';
import 'order_detail_page.dart' as order_detail;

/// Данные точки отправления или получения
class AddressPoint {
  AddressPoint({this.address, this.lat, this.lng});

  final String? address;
  final double? lat;
  final double? lng;

  bool get hasMapPoint => lat != null && lng != null;
  String get shortCoords => (lat != null && lng != null)
      ? '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}'
      : '';
}

/// Экран «Откуда и куда» — сначала карта, затем адреса (текст + точка на карте).
class FromToAddressPage extends StatefulWidget {
  const FromToAddressPage({super.key});

  static const String routeName = '/delivery/from-to-address';

  @override
  State<FromToAddressPage> createState() => _FromToAddressPageState();
}

class _FromToAddressPageState extends State<FromToAddressPage> {
  final DeliveryRepository _deliveryRepository = di.getIt<DeliveryRepository>();
  final _fromAddressController = TextEditingController();
  final _toAddressController = TextEditingController();
  final _parcelDescriptionController = TextEditingController();
  final _parcelEstimatedValueController = TextEditingController();

  AddressPoint _from = AddressPoint();
  AddressPoint _to = AddressPoint();
  int _step = 1;
  DeliveryCalculatePriceResponse? _calculatedPrice;
  bool _isCalculating = false;
  bool _isCreating = false;

  GoogleMapController? _mapController;
  static const LatLng _defaultCenter = LatLng(41.3111, 69.2797);

  @override
  void dispose() {
    _fromAddressController.dispose();
    _toAddressController.dispose();
    _parcelDescriptionController.dispose();
    _parcelEstimatedValueController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> get _markers {
    final Set<Marker> m = {};
    if (_from.hasMapPoint) {
      m.add(
        Marker(
          markerId: const MarkerId('from'),
          position: LatLng(_from.lat!, _from.lng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
    if (_to.hasMapPoint) {
      m.add(
        Marker(
          markerId: const MarkerId('to'),
          position: LatLng(_to.lat!, _to.lng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }
    return m;
  }

  Future<void> _pickOnMap(bool isFrom) async {
    final initial = isFrom ? _from : _to;
    final LatLng? initialLatLng = (initial.lat != null && initial.lng != null)
        ? LatLng(initial.lat!, initial.lng!)
        : null;

    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute<LatLng>(
        builder: (context) {
          final appState = Provider.of<AppState>(context, listen: false);
          return MapPickerPage(
            title: isFrom
                ? appState.t('delivery_from')
                : appState.t('delivery_to'),
            initialPosition: initialLatLng,
          );
        },
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      if (isFrom) {
        _from = AddressPoint(
          address: _from.address,
          lat: result.latitude,
          lng: result.longitude,
        );
      } else {
        _to = AddressPoint(
          address: _to.address,
          lat: result.latitude,
          lng: result.longitude,
        );
      }
    });

    // Подтянуть камеру к выбранной точке или к обеим
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(result.latitude, result.longitude), 14),
    );
  }

  Future<void> _onNext() async {
    final fromText = _fromAddressController.text.trim();
    final toText = _toAddressController.text.trim();

    final appState = Provider.of<AppState>(context, listen: false);
    if (fromText.isEmpty && !_from.hasMapPoint) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appState.t('delivery_specify_pickup'))),
      );
      return;
    }
    if (toText.isEmpty && !_to.hasMapPoint) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appState.t('delivery_specify_delivery'))),
      );
      return;
    }
    if (!_from.hasMapPoint || !_to.hasMapPoint) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appState.t('delivery_specify_both_points'))),
      );
      return;
    }

    setState(() {
      _from = AddressPoint(
        address: fromText.isEmpty ? null : fromText,
        lat: _from.lat,
        lng: _from.lng,
      );
      _to = AddressPoint(
        address: toText.isEmpty ? null : toText,
        lat: _to.lat,
        lng: _to.lng,
      );
      _isCalculating = true;
    });

    try {
      final pickup = DeliveryAddressPoint(
        latitude: _from.lat!,
        longitude: _from.lng!,
        address: fromText.isEmpty
            ? Provider.of<AppState>(
                context,
                listen: false,
              ).t('delivery_map_point')
            : fromText,
      );
      final dropoff = DeliveryAddressPoint(
        latitude: _to.lat!,
        longitude: _to.lng!,
        address: toText.isEmpty
            ? Provider.of<AppState>(
                context,
                listen: false,
              ).t('delivery_map_point')
            : toText,
      );
      final price = await _deliveryRepository.calculateDeliveryPrice(
        pickup: pickup,
        dropoff: dropoff,
      );
      if (mounted) {
        setState(() {
          _calculatedPrice = price;
          _isCalculating = false;
          _step = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCalculating = false);
        final appState = Provider.of<AppState>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${appState.t('delivery_failed_to_calculate')}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _onCreateOrder() async {
    if (_calculatedPrice == null || !_from.hasMapPoint || !_to.hasMapPoint) {
      return;
    }
    final fromText = _fromAddressController.text.trim();
    final toText = _toAddressController.text.trim();
    final pickup = DeliveryAddressPoint(
      latitude: _from.lat!,
      longitude: _from.lng!,
      address: fromText.isEmpty
          ? Provider.of<AppState>(
              context,
              listen: false,
            ).t('delivery_map_point')
          : fromText,
    );
    final dropoff = DeliveryAddressPoint(
      latitude: _to.lat!,
      longitude: _to.lng!,
      address: toText.isEmpty
          ? Provider.of<AppState>(
              context,
              listen: false,
            ).t('delivery_map_point')
          : toText,
    );
    final parcelDesc = _parcelDescriptionController.text.trim();
    final estimatedStr = _parcelEstimatedValueController.text.trim();
    double? estimatedValue;
    if (estimatedStr.isNotEmpty) {
      estimatedValue = double.tryParse(
        estimatedStr.replaceAll(',', '.').replaceAll(' ', ''),
      );
    }

    setState(() => _isCreating = true);
    try {
      final order = await _deliveryRepository.createOrderByPoints(
        pickup: pickup,
        dropoff: dropoff,
        parcelDescription: parcelDesc.isEmpty ? null : parcelDesc,
        parcelEstimatedValue: estimatedValue,
      );
      if (!mounted) return;
      setState(() => _isCreating = false);

      // Показываем сообщение о том, что курьер свяжется
      if (mounted) {
        final currentAppState = Provider.of<AppState>(context, listen: false);
        await ModernDialog.show(
          context: context,
          title: currentAppState.t('delivery_order_created'),
          content: currentAppState.t('delivery_courier_contact'),
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF10B981),
          primaryAction: DialogAction(
            label: currentAppState.t('delivery_understood'),
            onPressed: () {},
            color: const Color(0xFF1565C0),
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => order_detail.OrderDetailPage(orderId: order.id),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${Provider.of<AppState>(context, listen: false).t('delivery_failed_to_create')}: $e',
            ),
          ),
        );
      }
    }
  }

  String _formatPrice(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }

  Widget _buildStep1(MediaQueryData media, bool isSmallScreen, double padding) {
    return Stack(
      children: [
        // Карта на весь экран
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultCenter,
              zoom: 10,
            ),
            mapType: MapType.normal,
            markers: _markers,
            onMapCreated: (c) => _mapController = c,
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
            padding: EdgeInsets.only(
              bottom: media.size.height * 0.52,
              left: 12,
              right: 12,
            ),
          ),
        ),
        // Лёгкий градиент сверху для читаемости AppBar
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: media.padding.top + 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.35),
                  Colors.black.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Кнопка «Найти меня» над картой
        Positioned(
          right: 16,
          top: media.padding.top + 60,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.15),
            child: IconButton(
              onPressed: () {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_defaultCenter, 14),
                );
              },
              icon: const Icon(
                Icons.my_location_rounded,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
        ),
        // Нижняя выдвижная панель с адресами
        DraggableScrollableSheet(
          initialChildSize: 0.48,
          minChildSize: 0.28,
          maxChildSize: 0.88,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  padding,
                  12,
                  padding,
                  media.padding.bottom + 24,
                ),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.t('delivery_from_to'),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            appState.t('delivery_from_to_hint'),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: isSmallScreen ? 18 : 22),
                  Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      return Column(
                        children: [
                          _buildAddressCard(
                            isSmallScreen: isSmallScreen,
                            title: appState.t('delivery_from'),
                            subtitle: appState.t('delivery_pickup_address'),
                            hint: appState.t('delivery_address_hint'),
                            controller: _fromAddressController,
                            point: _from,
                            isFrom: true,
                            icon: Icons.upload_rounded,
                            color: const Color(0xFF1565C0),
                          ),
                          SizedBox(height: isSmallScreen ? 14 : 18),
                          _buildAddressCard(
                            isSmallScreen: isSmallScreen,
                            title: appState.t('delivery_to'),
                            subtitle: appState.t('delivery_delivery_address'),
                            hint: appState.t('delivery_address_hint'),
                            controller: _toAddressController,
                            point: _to,
                            isFrom: false,
                            icon: Icons.download_rounded,
                            color: const Color(0xFFE65100),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isCalculating ? null : _onNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 16 : 18,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isCalculating
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Builder(
                              builder: (context) {
                                final appState = Provider.of<AppState>(
                                  context,
                                  listen: false,
                                );
                                return Text(
                                  appState.t('delivery_calculate_price'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep2(MediaQueryData media, bool isSmallScreen, double padding) {
    final price = _calculatedPrice!;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        padding,
        20,
        padding,
        media.padding.bottom + 24,
      ),
      children: [
        TextButton.icon(
          onPressed: () => setState(() {
            _step = 1;
            _calculatedPrice = null;
          }),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          label: Builder(
            builder: (context) {
              final appState = Provider.of<AppState>(context, listen: false);
              return Text(appState.t('delivery_change_addresses'));
            },
          ),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF1565C0)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 18 : 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF1565C0),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
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
                              appState.t('delivery_price'),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatPrice(price.finalPrice)} ${price.currency}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1565C0),
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
        SizedBox(height: isSmallScreen ? 18 : 22),
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  final appState = Provider.of<AppState>(
                    context,
                    listen: false,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appState.t('delivery_parcel_description'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _parcelDescriptionController,
                        decoration: InputDecoration(
                          hintText: appState.t(
                            'delivery_parcel_description_hint',
                          ),
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 14),
                      Builder(
                        builder: (context) {
                          final appState = Provider.of<AppState>(
                            context,
                            listen: false,
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                appState.t('delivery_estimated_value'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _parcelEstimatedValueController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: appState.t('delivery_optional'),
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallScreen ? 24 : 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isCreating ? null : _onCreateOrder,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 16 : 18),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isCreating
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final appState = Provider.of<AppState>(
                        context,
                        listen: false,
                      );
                      return Text(
                        appState.t('delivery_create_order'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isSmallScreen = media.size.width < 360;
    final padding = isSmallScreen ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: _step == 1
          ? const Color(0xFFE8ECF0)
          : const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: _step == 1,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _step == 1
            ? Colors.transparent
            : const Color(0xFFF8FAFC),
        foregroundColor: _step == 1 ? Colors.white : const Color(0xFF111827),
        title: Builder(
          builder: (context) {
            final appState = Provider.of<AppState>(context, listen: false);
            return Text(
              _step == 1
                  ? appState.t('delivery_from_to')
                  : appState.t('delivery_create_order'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _step == 1 ? Colors.white : const Color(0xFF111827),
              ),
            );
          },
        ),
        centerTitle: true,
      ),
      body: _step == 1
          ? _buildStep1(media, isSmallScreen, padding)
          : _buildStep2(media, isSmallScreen, padding),
    );
  }

  Widget _buildAddressCard({
    required bool isSmallScreen,
    required String title,
    required String subtitle,
    required String hint,
    required TextEditingController controller,
    required AddressPoint point,
    required bool isFrom,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 14 : 16),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: color, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isSmallScreen ? 14 : 16,
              ),
            ),
            maxLines: 2,
          ),
          if (point.hasMapPoint) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.place_rounded, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final appState = Provider.of<AppState>(
                          context,
                          listen: false,
                        );
                        return Text(
                          '${appState.t('delivery_map_point')}: ${point.shortCoords}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickOnMap(isFrom),
            icon: Icon(Icons.map_rounded, size: 20, color: color),
            label: Builder(
              builder: (context) {
                final appState = Provider.of<AppState>(context, listen: false);
                return Text(appState.t('delivery_pick_on_map'));
              },
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color.withOpacity(0.6)),
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 12 : 14,
                horizontal: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
