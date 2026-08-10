/// Точка адреса для API доставки (ТЗ п.2.4, п.4)
class DeliveryAddressPoint {
  DeliveryAddressPoint({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
  };

  factory DeliveryAddressPoint.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String? ?? '',
    );
  }
}

/// Ответ расчёта стоимости POST /api/v1/delivery/calculate-price (ТЗ п.2.4)
/// Согласно документации API: distance_km, delivery_cost, min_total, cost_per_km, base_fixed
class DeliveryCalculatePriceResponse {
  DeliveryCalculatePriceResponse({
    required this.deliveryCost,
    required this.distanceKm,
    this.minTotal,
    this.costPerKm,
    this.baseFixed,
    this.currency = 'UZS',
  });

  /// Стоимость доставки (delivery_cost)
  final double deliveryCost;

  /// Расстояние в километрах (distance_km)
  final double distanceKm;

  /// Минимальная общая стоимость (min_total)
  final double? minTotal;

  /// Стоимость за километр (cost_per_km)
  final double? costPerKm;

  /// Базовая фиксированная стоимость (base_fixed)
  final double? baseFixed;

  /// Валюта (по умолчанию UZS)
  final String currency;

  /// Для обратной совместимости: возвращает delivery_cost
  double get finalPrice => deliveryCost;

  /// Для обратной совместимости: возвращает baseFixed
  double? get basePrice => baseFixed;

  factory DeliveryCalculatePriceResponse.fromJson(Map<String, dynamic> json) {
    // Поддержка нового формата API (delivery_cost, distance_km, min_total, cost_per_km, base_fixed)
    if (json.containsKey('delivery_cost') || json.containsKey('distance_km')) {
      return DeliveryCalculatePriceResponse(
        deliveryCost: (json['delivery_cost'] as num?)?.toDouble() ?? 0.0,
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
        minTotal: json['min_total'] != null
            ? (json['min_total'] as num).toDouble()
            : null,
        costPerKm: json['cost_per_km'] != null
            ? (json['cost_per_km'] as num).toDouble()
            : null,
        baseFixed: json['base_fixed'] != null
            ? (json['base_fixed'] as num).toDouble()
            : null,
        currency: json['currency'] as String? ?? 'UZS',
      );
    }

    // Обратная совместимость со старым форматом (final_price, base_price, distance_km)
    return DeliveryCalculatePriceResponse(
      deliveryCost:
          (json['final_price'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble() ??
          0,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : 0.0,
      baseFixed: json['base_price'] != null
          ? (json['base_price'] as num).toDouble()
          : null,
      currency: json['currency'] as String? ?? 'UZS',
    );
  }
}

/// Ответ баланса GET /api/v1/delivery/balance (ТЗ п.5)
class DeliveryBalanceResponse {
  DeliveryBalanceResponse({required this.balance, this.currency = 'UZS'});

  final double balance;
  final String currency;

  factory DeliveryBalanceResponse.fromJson(Map<String, dynamic> json) {
    return DeliveryBalanceResponse(
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'UZS',
    );
  }
}

/// Запись истории баланса GET /api/v1/delivery/balance/log
class DeliveryBalanceLogEntry {
  DeliveryBalanceLogEntry({
    required this.id,
    required this.amount,
    required this.type,
    this.description,
    this.orderId,
    required this.createdAt,
  });

  final int id;
  final double amount; // положительный — возврат, отрицательный — списание
  final String type; // order_payment, refund, admin_adjustment
  final String? description;
  final int? orderId;
  final DateTime createdAt;

  factory DeliveryBalanceLogEntry.fromJson(Map<String, dynamic> json) {
    return DeliveryBalanceLogEntry(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String? ?? 'transaction',
      description: json['description'] as String?,
      orderId: json['order_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
