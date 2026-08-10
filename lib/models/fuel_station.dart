class FuelPrice {
  FuelPrice({
    required this.id,
    required this.fuelType,
    required this.placeId,
    required this.price,
    required this.createdAt,
  });

  final int id;
  final String fuelType;
  final int placeId;
  final double price;
  final DateTime createdAt;

  factory FuelPrice.fromJson(Map<String, dynamic> json) {
    return FuelPrice(
      id: json['id'] as int,
      fuelType: json['fuel_type'] as String,
      placeId: json['place_id'] as int,
      price: (json['price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fuel_type': fuelType,
      'place_id': placeId,
      'price': price,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class FuelStation {
  FuelStation({
    required this.id,
    required this.name,
    required this.category,
    required this.workingHours,
    required this.address,
    required this.coordinates,
    required this.rating,
    required this.reviewsCount,
    required this.preview,
    required this.fuelPrices,
    this.isFavorite = false,
  });

  final int id;
  final String name;
  final String category;
  final String workingHours;
  final String address;
  final String coordinates;
  final double rating;
  final int reviewsCount;
  final String preview;
  final List<FuelPrice> fuelPrices;
  bool isFavorite;

  // Парсинг координат из строки "lat,lng"
  List<double> get coordinatesList {
    final parts = coordinates.split(',');
    if (parts.length == 2) {
      return [
        double.tryParse(parts[0].trim()) ?? 0.0,
        double.tryParse(parts[1].trim()) ?? 0.0,
      ];
    }
    return [0.0, 0.0];
  }

  double get lat => coordinatesList[0];
  double get lng => coordinatesList[1];

  bool get hasGasoline => fuelPrices.any(
    (p) =>
        p.fuelType.toLowerCase().contains('gasoline') ||
        p.fuelType.toLowerCase().contains('бензин'),
  );
  bool get hasAi80 => fuelPrices.any(
    (p) =>
        p.fuelType.toLowerCase().contains('80') ||
        p.fuelType.toLowerCase().contains('ai-80'),
  );
  bool get hasAi91 => fuelPrices.any(
    (p) =>
        p.fuelType.toLowerCase().contains('91') ||
        p.fuelType.toLowerCase().contains('ai-91'),
  );
  bool get hasAi95 => fuelPrices.any(
    (p) =>
        p.fuelType.toLowerCase().contains('95') ||
        p.fuelType.toLowerCase().contains('ai-95'),
  );
  bool get hasAi98 => fuelPrices.any(
    (p) =>
        p.fuelType.toLowerCase().contains('98') ||
        p.fuelType.toLowerCase().contains('ai-98'),
  );
  bool get hasDiesel => fuelPrices.any(
    (p) =>
        p.fuelType.toLowerCase().contains('diesel') ||
        p.fuelType.toLowerCase().contains('дизель'),
  );

  // Минимальная цена
  double? get minPrice {
    if (fuelPrices.isEmpty) return null;
    return fuelPrices.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }

  factory FuelStation.fromJson(Map<String, dynamic> json) {
    return FuelStation(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String? ?? '',
      workingHours: json['working_hours'] as String? ?? '',
      address: json['address'] as String,
      coordinates: json['coordinates'] as String? ?? '0.0,0.0',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      preview: json['preview'] as String? ?? '',
      fuelPrices:
          (json['fuel_price'] as List<dynamic>?)
              ?.map((e) => FuelPrice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'working_hours': workingHours,
      'address': address,
      'coordinates': coordinates,
      'rating': rating,
      'reviews_count': reviewsCount,
      'preview': preview,
      'fuel_price': fuelPrices.map((p) => p.toJson()).toList(),
    };
  }
}

class StationsResponse {
  StationsResponse({
    required this.total,
    required this.totalFiltered,
    required this.limit,
    required this.offset,
    required this.places,
  });

  final int total;
  final int totalFiltered;
  final int limit;
  final int offset;
  final List<FuelStation> places;

  factory StationsResponse.fromJson(Map<String, dynamic> json) {
    return StationsResponse(
      total: json['total'] as int? ?? 0,
      totalFiltered: json['total_filtered'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
      offset: json['offset'] as int? ?? 0,
      places:
          (json['places'] as List<dynamic>?)
              ?.map((e) => FuelStation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'total_filtered': totalFiltered,
      'limit': limit,
      'offset': offset,
      'places': places.map((p) => p.toJson()).toList(),
    };
  }
}
