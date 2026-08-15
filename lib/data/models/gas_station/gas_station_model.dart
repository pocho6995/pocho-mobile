import 'package:flutter/foundation.dart';
import '../../../domain/entities/gas_station.dart';
import '../../../domain/repositories/gas_station_repository.dart';
import '../../../utils/image_url_helper.dart';

/// Модель заправочной станции (DTO)
class GasStationModel extends GasStation {
  const GasStationModel({
    required super.id,
    required super.name,
    required super.address,
    required super.latitude,
    required super.longitude,
    super.phone,
    super.is24_7 = false,
    super.workingHours,
    super.rating = 0.0,
    super.reviewsCount = 0,
    super.status = 'pending',
    super.hasPromotions = false,
    super.category,
    super.fuelPrices = const [],
    super.photos = const [],
    super.mainPhoto,
    super.reviews = const [],
    super.createdAt,
    super.updatedAt,
  });

  factory GasStationModel.fromJson(Map<String, dynamic> json) {
    return GasStationModel(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      phone: json['phone'] as String?,
      is24_7: json['is_24_7'] as bool? ?? false,
      workingHours: json['working_hours'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      status: json['status'] as String? ?? 'pending',
      hasPromotions: json['has_promotions'] as bool? ?? false,
      category: json['category'] as String?,
      fuelPrices: (json['fuel_prices'] as List<dynamic>?)
              ?.map((e) => FuelPriceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      photos: (json['photos'] as List<dynamic>?)
              ?.map((e) => GasStationPhotoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mainPhoto: () {
        final rawMainPhoto = json['main_photo'] as String?;
        final fullMainPhoto = ImageUrlHelper.getFullImageUrl(rawMainPhoto);
        if (kDebugMode && rawMainPhoto != null) {
          print('📸 Parsing mainPhoto: raw=$rawMainPhoto, full=$fullMainPhoto');
        }
        return fullMainPhoto;
      }(),
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'phone': phone,
      'is_24_7': is24_7,
      'working_hours': workingHours,
      'rating': rating,
      'reviews_count': reviewsCount,
      'status': status,
      'has_promotions': hasPromotions,
      'category': category,
      'fuel_prices': fuelPrices.map((e) => (e as FuelPriceModel).toJson()).toList(),
      'photos': photos.map((e) => (e as GasStationPhotoModel).toJson()).toList(),
      'main_photo': mainPhoto,
      'reviews': reviews.map((e) => (e as ReviewModel).toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  GasStationModel copyWith({
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
    return GasStationModel(
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

/// Модель цены на топливо (DTO)
class FuelPriceModel extends FuelPrice {
  const FuelPriceModel({
    required super.id,
    required super.gasStationId,
    required super.fuelType,
    required super.price,
    super.updatedAt,
  });

  factory FuelPriceModel.fromJson(Map<String, dynamic> json) {
    return FuelPriceModel(
      id: json['id'] as int,
      gasStationId: json['gas_station_id'] as int,
      fuelType: json['fuel_type'] as String,
      price: (json['price'] as num).toDouble(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gas_station_id': gasStationId,
      'fuel_type': fuelType,
      'price': price,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Модель фотографии станции (DTO)
class GasStationPhotoModel extends GasStationPhoto {
  const GasStationPhotoModel({
    required super.id,
    required super.gasStationId,
    required super.photoUrl,
    super.isMain = false,
    super.order = 0,
  });

  factory GasStationPhotoModel.fromJson(Map<String, dynamic> json) {
    final rawPhotoUrl = json['photo_url'] as String? ?? '';
    final fullPhotoUrl = ImageUrlHelper.getFullImageUrl(rawPhotoUrl) ?? '';
    
    if (kDebugMode && rawPhotoUrl.isNotEmpty) {
      print('📸 Parsing photo: raw=$rawPhotoUrl, full=$fullPhotoUrl');
    }
    
    return GasStationPhotoModel(
      id: json['id'] as int,
      gasStationId: json['gas_station_id'] as int,
      photoUrl: fullPhotoUrl,
      isMain: json['is_main'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gas_station_id': gasStationId,
      'photo_url': photoUrl,
      'is_main': isMain,
      'order': order,
    };
  }
}

/// Модель отзыва (DTO)
class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.gasStationId,
    required super.userId,
    super.userName,
    super.userAvatar,
    required super.rating,
    super.comment,
    super.createdAt,
    super.updatedAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as int,
      gasStationId: json['gas_station_id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String?,
      userAvatar: ImageUrlHelper.getFullImageUrl(json['user_avatar'] as String?),
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
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
      'gas_station_id': gasStationId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Модель ответа списка станций
class GasStationsListResponse {
  final List<GasStationModel> stations;
  final int total;
  final int skip;
  final int limit;

  GasStationsListResponse({
    required this.stations,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory GasStationsListResponse.fromJson(Map<String, dynamic> json) {
    return GasStationsListResponse(
      stations: (json['stations'] as List<dynamic>?)
              ?.map((e) => GasStationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      skip: json['skip'] as int? ?? 0,
      limit: json['limit'] as int? ?? 100,
    );
  }
}

/// Модель детального ответа станции (с отзывами)
/// В новом API отзывы приходят внутри объекта станции
class GasStationDetailResponse {
  final GasStationModel station;

  GasStationDetailResponse({
    required this.station,
  });

  factory GasStationDetailResponse.fromJson(Map<String, dynamic> json) {
    // В новом API весь объект станции приходит напрямую, включая reviews
    return GasStationDetailResponse(
      station: GasStationModel.fromJson(json),
    );
  }
}

/// Расширение FuelPriceModel для конвертации в FuelPriceInput
extension FuelPriceModelExtension on FuelPriceModel {
  FuelPriceInput toInput() {
    return FuelPriceInput(fuelType: fuelType, price: price);
  }
}

