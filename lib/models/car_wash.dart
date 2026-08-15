import '../utils/image_url_helper.dart';

class CarWash {
  CarWash({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.imageUrl,
    required this.washTypes,
    required this.priceRange,
    required this.workingHours,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.isFavorite = false,
    this.distance,
    this.features = const [],
    this.phone,
  });

  final int id;
  final String name;
  final String address;
  final double rating;
  final int reviewCount;
  final String imageUrl;
  final List<String> washTypes; // ["Ручная мойка", "Автоматическая мойка", "Полировка"]
  final String priceRange; // "Эконом", "Стандарт", "Премиум"
  final String workingHours; // "09:00 - 18:00"
  final String description;
  final double latitude;
  final double longitude;
  bool isFavorite;
  double? distance; // в километрах
  final List<String> features; // ["Парковка", "Кафе", "Wi-Fi", "Пылесос"]
  final String? phone;

  factory CarWash.fromJson(Map<String, dynamic> json) {
    return CarWash(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['review_count'] as int,
      imageUrl: ImageUrlHelper.getFullImageUrlOrEmpty(
        json['image_url'] as String?,
      ),
      washTypes: (json['wash_types'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      priceRange: json['price_range'] as String,
      workingHours: json['working_hours'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isFavorite: json['is_favorite'] as bool? ?? false,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      features: (json['features'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      phone: json['phone'] as String?,
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
      'wash_types': washTypes,
      'price_range': priceRange,
      'working_hours': workingHours,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'is_favorite': isFavorite,
      'distance': distance,
      'features': features,
      'phone': phone,
    };
  }
}








