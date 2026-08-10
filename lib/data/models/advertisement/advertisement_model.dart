import 'package:equatable/equatable.dart';

/// Модель рекламного блока
class Advertisement extends Equatable {
  const Advertisement({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.linkUrl,
    this.linkType,
    required this.adType,
    required this.position,
    required this.status,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.priority,
    required this.displayOrder,
    this.targetAudience,
    this.showConditions,
    required this.viewsCount,
    required this.clicksCount,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String? description;
  final String imageUrl;
  final String? linkUrl;
  final String? linkType;
  final String adType;
  final String position;
  final String status;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final int priority;
  final int displayOrder;
  final String? targetAudience;
  final String? showConditions;
  final int viewsCount;
  final int clicksCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Проверка, активна ли реклама в данный момент
  bool get isCurrentlyActive {
    if (!isActive || status != 'active') return false;
    
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    
    return true;
  }

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String,
      linkUrl: json['link_url'] as String?,
      linkType: json['link_type'] as String?,
      adType: json['ad_type'] as String? ?? 'banner',
      position: json['position'] as String? ?? 'home_top',
      status: json['status'] as String? ?? 'active',
      isActive: json['is_active'] as bool? ?? true,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      priority: json['priority'] as int? ?? 0,
      displayOrder: json['display_order'] as int? ?? 0,
      targetAudience: json['target_audience'] as String?,
      showConditions: json['show_conditions'] as String?,
      viewsCount: json['views_count'] as int? ?? 0,
      clicksCount: json['clicks_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'link_type': linkType,
      'ad_type': adType,
      'position': position,
      'status': status,
      'is_active': isActive,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'priority': priority,
      'display_order': displayOrder,
      'target_audience': targetAudience,
      'show_conditions': showConditions,
      'views_count': viewsCount,
      'clicks_count': clicksCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        linkUrl,
        linkType,
        adType,
        position,
        status,
        isActive,
        startDate,
        endDate,
        priority,
        displayOrder,
        targetAudience,
        showConditions,
        viewsCount,
        clicksCount,
        createdAt,
        updatedAt,
      ];
}









