class Region {
  Region({
    required this.id,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.isActive,
    required this.displayOrder,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final double centerLatitude;
  final double centerLongitude;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get name => nameRu; // По умолчанию русский

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] as int,
      nameUz: json['name_uz'] as String,
      nameRu: json['name_ru'] as String,
      nameEn: json['name_en'] as String,
      centerLatitude: (json['center_latitude'] as num).toDouble(),
      centerLongitude: (json['center_longitude'] as num).toDouble(),
      isActive: json['is_active'] as bool,
      displayOrder: json['display_order'] as int,
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
      'name_uz': nameUz,
      'name_ru': nameRu,
      'name_en': nameEn,
      'center_latitude': centerLatitude,
      'center_longitude': centerLongitude,
      'is_active': isActive,
      'display_order': displayOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}





