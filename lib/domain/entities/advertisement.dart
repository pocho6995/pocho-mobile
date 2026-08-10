import 'package:equatable/equatable.dart';

/// Сущность рекламного блока
class AdvertisementEntity extends Equatable {
  const AdvertisementEntity({
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









