import '../../utils/image_url_helper.dart';

class Vehicle {
  Vehicle({
    required this.id,
    required this.driverId,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.licensePlate,
    required this.vehiclePassportNumber,
    this.photoUrl,
    this.capacityKg,
    this.volumeM3,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int driverId;
  final String vehicleType; // car, truck, motorcycle, van
  final String brand;
  final String model;
  final int year;
  final String color;
  final String licensePlate;
  final String vehiclePassportNumber;
  final String? photoUrl;
  final double? capacityKg;
  final double? volumeM3;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get vehicleTypeName {
    switch (vehicleType) {
      case 'car':
        return 'Легковой автомобиль';
      case 'truck':
        return 'Грузовик';
      case 'motorcycle':
        return 'Мотоцикл';
      case 'van':
        return 'Фургон';
      default:
        return vehicleType;
    }
  }

  String get fullName => '$brand $model ($year)';

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int,
      driverId: json['driver_id'] as int,
      vehicleType: json['vehicle_type'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      color: json['color'] as String,
      licensePlate: json['license_plate'] as String,
      vehiclePassportNumber: json['vehicle_passport_number'] as String,
      photoUrl: ImageUrlHelper.getFullImageUrl(json['photo_url'] as String?),
      capacityKg: json['capacity_kg'] != null
          ? (json['capacity_kg'] as num).toDouble()
          : null,
      volumeM3: json['volume_m3'] != null
          ? (json['volume_m3'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'vehicle_type': vehicleType,
      'brand': brand,
      'model': model,
      'year': year,
      'color': color,
      'license_plate': licensePlate,
      'vehicle_passport_number': vehiclePassportNumber,
      'photo_url': photoUrl,
      'capacity_kg': capacityKg,
      'volume_m3': volumeM3,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}





