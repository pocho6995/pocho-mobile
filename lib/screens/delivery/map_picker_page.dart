import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

/// Страница выбора точки на карте (откуда/куда).
/// Пользователь нажимает на карту — ставится маркер, кнопка «Выбрать» возвращает [LatLng].
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key, this.initialPosition, this.title});

  static const String routeName = '/delivery/map-picker';

  /// Начальная позиция камеры и маркера (если уже выбрано)
  final LatLng? initialPosition;
  final String? title;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  LatLng? _selectedPosition;
  static const LatLng _defaultCenter = LatLng(41.3111, 69.2797);

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition;
  }

  Set<Marker> get _markers {
    if (_selectedPosition == null) return {};
    return {
      Marker(
        markerId: const MarkerId('selected'),
        position: _selectedPosition!,
        draggable: true,
        onDragEnd: (LatLng position) {
          setState(() => _selectedPosition = position);
        },
      ),
    };
  }

  void _onMapTap(LatLng position) {
    if (kDebugMode) {
      print(
        'MapPickerPage: tap at ${position.latitude}, ${position.longitude}',
      );
    }
    setState(() => _selectedPosition = position);
  }

  void _onConfirm() {
    Navigator.of(context).pop(_selectedPosition);
  }

  @override
  Widget build(BuildContext context) {
    final initialCamera = widget.initialPosition != null
        ? CameraPosition(target: widget.initialPosition!, zoom: 14)
        : const CameraPosition(target: _defaultCenter, zoom: 10);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final appState = Provider.of<AppState>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? appState.t('delivery_map_picker_title')),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _selectedPosition != null ? _onConfirm : null,
            child: Text(appState.t('delivery_select')),
          ),
        ],
      ),
      body: Column(
        children: [
          // Карта занимает всё доступное место — без оверлея сверху, касания доходят до карты
          Expanded(
            child: GoogleMap(
              initialCameraPosition: initialCamera,
              mapType: MapType.normal,
              markers: _markers,
              onMapCreated: (_) {},
              onTap: _onMapTap,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              // На Android даём карте обрабатывать все жесты
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),
          ),
          // Подсказка под картой (не перекрывает карту)
          Container(
            width: double.infinity,
            margin: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _selectedPosition == null
                  ? appState.t('delivery_tap_map_to_select')
                  : '${appState.t('delivery_latitude')}: ${_selectedPosition!.latitude.toStringAsFixed(5)}, ${appState.t('delivery_longitude')}: ${_selectedPosition!.longitude.toStringAsFixed(5)}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
