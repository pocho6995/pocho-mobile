import 'package:equatable/equatable.dart';

/// Сущность заправочной станции
class GasStation extends Equatable {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phone;
  final bool is24_7;
  final String? workingHours;
  final double rating;
  final int reviewsCount;
  final String status; // pending, approved, rejected, archived
  final bool hasPromotions;
  final String? category;
  final List<FuelPrice> fuelPrices;
  final List<GasStationPhoto> photos;
  final String? mainPhoto; // URL главной фотографии
  final List<Review> reviews; // Отзывы (только в детальном ответе)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GasStation({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.is24_7 = false,
    this.workingHours,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.status = 'pending',
    this.hasPromotions = false,
    this.category,
    this.fuelPrices = const [],
    this.photos = const [],
    this.mainPhoto,
    this.reviews = const [],
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        latitude,
        longitude,
        phone,
        is24_7,
        workingHours,
        rating,
        reviewsCount,
        status,
        hasPromotions,
        category,
        fuelPrices,
        photos,
        mainPhoto,
        reviews,
        createdAt,
        updatedAt,
      ];

  GasStation copyWith({
    int? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    bool? is24_7,
    String? workingHours,
    double? rating,
    int? reviewsCount,
    String? status,
    bool? hasPromotions,
    String? category,
    List<FuelPrice>? fuelPrices,
    List<GasStationPhoto>? photos,
    String? mainPhoto,
    List<Review>? reviews,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GasStation(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      is24_7: is24_7 ?? this.is24_7,
      workingHours: workingHours ?? this.workingHours,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      status: status ?? this.status,
      hasPromotions: hasPromotions ?? this.hasPromotions,
      category: category ?? this.category,
      fuelPrices: fuelPrices ?? this.fuelPrices,
      photos: photos ?? this.photos,
      mainPhoto: mainPhoto ?? this.mainPhoto,
      reviews: reviews ?? this.reviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Сущность цены на топливо
class FuelPrice extends Equatable {
  final int id;
  final int gasStationId;
  final String fuelType; // AI-80, AI-91, AI-95, AI-98, Дизель, Газ
  final double price;
  final DateTime? updatedAt;

  const FuelPrice({
    required this.id,
    required this.gasStationId,
    required this.fuelType,
    required this.price,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, gasStationId, fuelType, price, updatedAt];
}

/// Сущность фотографии станции
class GasStationPhoto extends Equatable {
  final int id;
  final int gasStationId;
  final String photoUrl;
  final bool isMain;
  final int order;

  const GasStationPhoto({
    required this.id,
    required this.gasStationId,
    required this.photoUrl,
    this.isMain = false,
    this.order = 0,
  });

  @override
  List<Object?> get props => [id, gasStationId, photoUrl, isMain, order];
}

/// Сущность отзыва
class Review extends Equatable {
  final int id;
  final int gasStationId;
  final int userId;
  final String? userName;
  final String? userAvatar;
  final int rating; // 1-5
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Review({
    required this.id,
    required this.gasStationId,
    required this.userId,
    this.userName,
    this.userAvatar,
    required this.rating,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        gasStationId,
        userId,
        userName,
        userAvatar,
        rating,
        comment,
        createdAt,
        updatedAt,
      ];
}

