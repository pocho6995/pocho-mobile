import 'package:flutter/material.dart';
import '../../di/injection_container.dart' as di;
import '../../repositories/delivery_repository.dart';
import '../../models/delivery/vehicle.dart';
import '../../widgets/modern_dialog.dart';

class DriverVehiclePage extends StatefulWidget {
  const DriverVehiclePage({super.key});

  static const String routeName = '/delivery/driver-vehicle';

  @override
  State<DriverVehiclePage> createState() => _DriverVehiclePageState();
}

class _DriverVehiclePageState extends State<DriverVehiclePage> {
  final DeliveryRepository _deliveryRepository = di.getIt<DeliveryRepository>();
  
  Vehicle? _vehicle;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    try {
      final vehicle = await _deliveryRepository.getVehicle();
      setState(() {
        _vehicle = vehicle;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ModernDialog.show(
          context: context,
          title: 'Ошибка',
          content: 'Не удалось загрузить ТС: ${e.toString()}',
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red,
          primaryAction: DialogAction(
            label: 'OK',
            onPressed: () {},
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Транспортное средство'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadVehicle,
              child: _vehicle == null
                  ? const Center(
                      child: Text('ТС не зарегистрировано'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _vehicle!.fullName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _InfoRow(
                                label: 'Тип',
                                value: _vehicle!.vehicleTypeName,
                              ),
                              _InfoRow(
                                label: 'Цвет',
                                value: _vehicle!.color,
                              ),
                              _InfoRow(
                                label: 'Гос. номер',
                                value: _vehicle!.licensePlate,
                              ),
                              _InfoRow(
                                label: 'Номер техпаспорта',
                                value: _vehicle!.vehiclePassportNumber,
                              ),
                              if (_vehicle!.capacityKg != null)
                                _InfoRow(
                                  label: 'Грузоподъемность',
                                  value: '${_vehicle!.capacityKg} кг',
                                ),
                              if (_vehicle!.volumeM3 != null)
                                _InfoRow(
                                  label: 'Объем',
                                  value: '${_vehicle!.volumeM3} м³',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}





