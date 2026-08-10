class DeliveryCalculationRequest {
  DeliveryCalculationRequest({
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    this.weightKg = 0.0,
    this.volumeM3 = 0.0,
  });

  final double pickupLatitude;
  final double pickupLongitude;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final double weightKg;
  final double volumeM3;

  Map<String, dynamic> toJson() {
    return {
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'delivery_latitude': deliveryLatitude,
      'delivery_longitude': deliveryLongitude,
      'weight_kg': weightKg,
      'volume_m3': volumeM3,
    };
  }
}

class DeliveryCalculationResponse {
  DeliveryCalculationResponse({
    required this.distanceKm,
    required this.distancePrice,
    required this.weightSurcharge,
    required this.volumeSurcharge,
    required this.totalPrice,
  });

  final double distanceKm;
  final double distancePrice;
  final double weightSurcharge;
  final double volumeSurcharge;
  final double totalPrice;

  factory DeliveryCalculationResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryCalculationResponse(
      distanceKm: (json['distance_km'] as num).toDouble(),
      distancePrice: (json['distance_price'] as num).toDouble(),
      weightSurcharge: (json['weight_surcharge'] as num?)?.toDouble() ?? 0.0,
      volumeSurcharge: (json['volume_surcharge'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }
}





