import '../utils/image_url_helper.dart';

class Restaurant {
  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.priceRange,
    required this.imageUrl,
    required this.category,
    required this.cuisine,
    required this.workingHours,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.isFavorite = false,
    this.distance,
    this.features = const [],
  });

  final int id;
  final String name;
  final String address;
  final double rating;
  final int reviewCount;
  final String priceRange; // "$", "$$", "$$$", "$$$$"
  final String imageUrl;
  final String category; // "Ресторан", "Кафе", "Фастфуд" и т.д.
  final String cuisine; // "Европейская", "Азиатская", "Узбекская" и т.д.
  final String workingHours; // "09:00 - 23:00"
  final String description;
  final double latitude;
  final double longitude;
  bool isFavorite;
  double? distance; // в километрах
  final List<String> features; // ["Wi-Fi", "Парковка", "Доставка", "Терраса"]

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['review_count'] as int,
      priceRange: json['price_range'] as String,
      imageUrl: ImageUrlHelper.getFullImageUrlOrEmpty(
        json['image_url'] as String?,
      ),
      category: json['category'] as String,
      cuisine: json['cuisine'] as String,
      workingHours: json['working_hours'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isFavorite: json['is_favorite'] as bool? ?? false,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      features: (json['features'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rating': rating,
      'review_count': reviewCount,
      'price_range': priceRange,
      'image_url': imageUrl,
      'category': category,
      'cuisine': cuisine,
      'working_hours': workingHours,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'is_favorite': isFavorite,
      'distance': distance,
      'features': features,
    };
  }
}








