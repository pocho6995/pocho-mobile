import '../utils/image_url_helper.dart';

class ChargingStation {
  ChargingStation({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.connectorTypes, // ["Type 2", "CCS", "CHAdeMO", "Tesla Supercharger"]
    required this.power, // в кВт, например "50 кВт", "150 кВт"
    required this.pricePerKwh, // цена за кВт·ч
    required this.workingHours, // "24/7" или "09:00 - 22:00"
    required this.description,
    required this.latitude,
    required this.longitude,
    this.isFavorite = false,
    this.distance, // в километрах
    this.features = const [], // ["Парковка", "Кафе", "Wi-Fi", "Туалет", "Магазин"]
    this.phone,
    this.availableConnectors, // количество доступных разъемов
    this.totalConnectors, // общее количество разъемов
    this.isAvailable = true, // доступна ли станция
  });

  final int id;
  final String name;
  final String address;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final List<String> connectorTypes; // Типы разъемов
  final String power; // Мощность зарядки
  final double pricePerKwh; // Цена за кВт·ч
  final String workingHours;
  final String description;
  final double latitude;
  final double longitude;
  bool isFavorite;
  double? distance;
  final List<String> features;
  final String? phone;
  final int? availableConnectors; // Доступные разъемы
  final int? totalConnectors; // Всего разъемов
  final bool isAvailable; // Доступность станции

  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    return ChargingStation(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['review_count'] as int,
      imageUrl: ImageUrlHelper.getFullImageUrlOrEmpty(
        json['image_url'] as String?,
      ),
      connectorTypes: (json['connector_types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      power: json['power'] as String,
      pricePerKwh: (json['price_per_kwh'] as num).toDouble(),
      workingHours: json['working_hours'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isFavorite: json['is_favorite'] as bool? ?? false,
      distance: (json['distance'] as num?)?.toDouble(),
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      phone: json['phone'] as String?,
      availableConnectors: json['available_connectors'] as int?,
      totalConnectors: json['total_connectors'] as int?,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rating': rating,
      'review_count': reviewCount,
      'image_url': imageUrl,
      'connector_types': connectorTypes,
      'power': power,
      'price_per_kwh': pricePerKwh,
      'working_hours': workingHours,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'is_favorite': isFavorite,
      'distance': distance,
      'features': features,
      'phone': phone,
      'available_connectors': availableConnectors,
      'total_connectors': totalConnectors,
      'is_available': isAvailable,
    };
  }
}

class ChargingStationResponse {
  ChargingStationResponse({
    required this.stations,
  });

  final List<ChargingStation> stations;

  factory ChargingStationResponse.fromJson(Map<String, dynamic> json) {
    return ChargingStationResponse(
      stations: (json['stations'] as List<dynamic>?)
              ?.map((e) => ChargingStation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}








