/// Модель размера посылки
class PackageSize {
  PackageSize({
    required this.id,
    required this.code,
    required this.nameRu,
    this.nameUz,
    required this.length,
    required this.width,
    required this.height,
    this.maxWeight,
    this.iconUrl,
    required this.displayOrder,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.tariff,
  });

  final int id;
  final String code; // S, M, P, L, XL
  final String nameRu;
  final String? nameUz;
  final double length; // Длина в см
  final double width; // Ширина в см
  final double height; // Высота в см
  final double? maxWeight; // Максимальный вес в кг
  final String? iconUrl;
  final int displayOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PricingTariff? tariff; // Тариф (если запрашивается с ценами)

  String get name => nameRu;

  factory PackageSize.fromJson(Map<String, dynamic> json) {
    return PackageSize(
      id: json['id'] as int,
      code: json['code'] as String,
      nameRu: json['name_ru'] as String,
      nameUz: json['name_uz'] as String?,
      length: (json['length'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      maxWeight: json['max_weight'] != null
          ? (json['max_weight'] as num).toDouble()
          : null,
      iconUrl: json['icon_url'] as String?,
      displayOrder: json['display_order'] as int,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      tariff: json['tariff'] != null
          ? PricingTariff.fromJson(json['tariff'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name_ru': nameRu,
      'name_uz': nameUz,
      'length': length,
      'width': width,
      'height': height,
      'max_weight': maxWeight,
      'icon_url': iconUrl,
      'display_order': displayOrder,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (tariff != null) 'tariff': tariff!.toJson(),
    };
  }
}

/// Модель тарифа
class PricingTariff {
  PricingTariff({
    required this.id,
    required this.packageSizeId,
    this.regionId,
    required this.basePrice,
    this.oldPrice,
    required this.serviceFeePercent,
    required this.serviceFeeFixed,
    this.minPrice,
    this.maxPrice,
    this.descriptionRu,
    this.descriptionUz,
    required this.isActive,
    required this.priority,
    this.createdAt,
    this.updatedAt,
    this.regionName,
  });

  final int id;
  final int packageSizeId;
  final int? regionId; // null для всех регионов
  final double basePrice;
  final double? oldPrice;
  final double serviceFeePercent; // 0-100
  final double serviceFeeFixed;
  final double? minPrice;
  final double? maxPrice;
  final String? descriptionRu;
  final String? descriptionUz;
  final bool isActive;
  final int priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? regionName;

  String get description => descriptionRu ?? descriptionUz ?? '';

  factory PricingTariff.fromJson(Map<String, dynamic> json) {
    return PricingTariff(
      id: json['id'] as int,
      packageSizeId: json['package_size_id'] as int,
      regionId: json['region_id'] as int?,
      basePrice: (json['base_price'] as num).toDouble(),
      oldPrice: json['old_price'] != null
          ? (json['old_price'] as num).toDouble()
          : null,
      serviceFeePercent: (json['service_fee_percent'] as num?)?.toDouble() ?? 0.0,
      serviceFeeFixed: (json['service_fee_fixed'] as num?)?.toDouble() ?? 0.0,
      minPrice: json['min_price'] != null
          ? (json['min_price'] as num).toDouble()
          : null,
      maxPrice: json['max_price'] != null
          ? (json['max_price'] as num).toDouble()
          : null,
      descriptionRu: json['description_ru'] as String?,
      descriptionUz: json['description_uz'] as String?,
      isActive: json['is_active'] as bool,
      priority: json['priority'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      regionName: json['region_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'package_size_id': packageSizeId,
      'region_id': regionId,
      'base_price': basePrice,
      'old_price': oldPrice,
      'service_fee_percent': serviceFeePercent,
      'service_fee_fixed': serviceFeeFixed,
      'min_price': minPrice,
      'max_price': maxPrice,
      'description_ru': descriptionRu,
      'description_uz': descriptionUz,
      'is_active': isActive,
      'priority': priority,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'region_name': regionName,
    };
  }
}

/// Модель ответа расчета цены
class PriceCalculationResponse {
  PriceCalculationResponse({
    required this.packageSizeId,
    required this.packageSizeCode,
    required this.packageSizeName,
    this.regionId,
    this.regionName,
    required this.basePrice,
    this.oldPrice,
    required this.serviceFeePercent,
    required this.serviceFeeFixed,
    required this.serviceFeeTotal,
    required this.finalPrice,
    this.minPrice,
    this.maxPrice,
    required this.hasDiscount,
    this.discountAmount,
    this.description,
  });

  final int packageSizeId;
  final String packageSizeCode;
  final String packageSizeName;
  final int? regionId;
  final String? regionName;
  final double basePrice;
  final double? oldPrice;
  final double serviceFeePercent;
  final double serviceFeeFixed;
  final double serviceFeeTotal;
  final double finalPrice;
  final double? minPrice;
  final double? maxPrice;
  final bool hasDiscount;
  final double? discountAmount;
  final String? description;

  factory PriceCalculationResponse.fromJson(Map<String, dynamic> json) {
    return PriceCalculationResponse(
      packageSizeId: json['package_size_id'] as int,
      packageSizeCode: json['package_size_code'] as String,
      packageSizeName: json['package_size_name'] as String,
      regionId: json['region_id'] as int?,
      regionName: json['region_name'] as String?,
      basePrice: (json['base_price'] as num).toDouble(),
      oldPrice: json['old_price'] != null
          ? (json['old_price'] as num).toDouble()
          : null,
      serviceFeePercent: (json['service_fee_percent'] as num?)?.toDouble() ?? 0.0,
      serviceFeeFixed: (json['service_fee_fixed'] as num?)?.toDouble() ?? 0.0,
      serviceFeeTotal: (json['service_fee_total'] as num).toDouble(),
      finalPrice: (json['final_price'] as num).toDouble(),
      minPrice: json['min_price'] != null
          ? (json['min_price'] as num).toDouble()
          : null,
      maxPrice: json['max_price'] != null
          ? (json['max_price'] as num).toDouble()
          : null,
      hasDiscount: json['has_discount'] as bool? ?? false,
      discountAmount: json['discount_amount'] != null
          ? (json['discount_amount'] as num).toDouble()
          : null,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'package_size_id': packageSizeId,
      'package_size_code': packageSizeCode,
      'package_size_name': packageSizeName,
      'region_id': regionId,
      'region_name': regionName,
      'base_price': basePrice,
      'old_price': oldPrice,
      'service_fee_percent': serviceFeePercent,
      'service_fee_fixed': serviceFeeFixed,
      'service_fee_total': serviceFeeTotal,
      'final_price': finalPrice,
      'min_price': minPrice,
      'max_price': maxPrice,
      'has_discount': hasDiscount,
      'discount_amount': discountAmount,
      'description': description,
    };
  }
}

