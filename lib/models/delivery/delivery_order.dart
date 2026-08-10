import 'package:flutter/foundation.dart';
import 'driver.dart';

/// Модель заявки на доставку согласно новому API
class DeliveryOrder {
  DeliveryOrder({
    required this.id,
    required this.userId,
    this.packageSizeId,
    this.packageSizeCode,
    this.packageSizeName,
    this.regionId,
    this.regionName,
    this.senderPointName,
    this.senderPointAddress,
    this.senderPointLatitude,
    this.senderPointLongitude,
    this.senderName,
    this.senderPhone,
    this.recipientPointName,
    this.recipientPointAddress,
    this.recipientPointLatitude,
    this.recipientPointLongitude,
    this.recipientName,
    this.recipientPhone = '',
    this.packageContent,
    this.estimatedValue,
    this.basePrice = 0.0,
    this.serviceFee = 0.0,
    this.finalPrice = 0.0,
    this.currency = 'UZS',
    required this.status,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.userComment,
    this.adminComment,
    required this.createdAt,
    this.updatedAt,
    this.acceptedAt,
    this.deliveredAt,
    this.canceledAt,
    this.cancelReason,
    this.distanceKm,
  });

  final int id;
  final int userId;
  final int? packageSizeId;
  final String? packageSizeCode; // S, M, P, L, XL
  final String? packageSizeName;
  final int? regionId;
  final String? regionName;

  // Пункт отправления
  final String? senderPointName;
  final String? senderPointAddress;
  final double? senderPointLatitude;
  final double? senderPointLongitude;
  final String? senderName;
  final String? senderPhone;

  // Пункт выдачи
  final String? recipientPointName;
  final String? recipientPointAddress;
  final double? recipientPointLatitude;
  final double? recipientPointLongitude;
  final String? recipientName;
  final String recipientPhone;

  // Содержимое
  final String? packageContent;
  final double? estimatedValue;

  // Цена
  final double basePrice;
  final double serviceFee;
  final double finalPrice;
  final String currency;

  // Статус
  final String
  status; // new, pending, accepted, in_transit, delivered, cancelled, rejected
  final int? driverId;
  final String? driverName;
  final String? driverPhone;

  // Комментарии
  final String? userComment;
  final String? adminComment;

  // Временные метки
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final DateTime? canceledAt;
  final String? cancelReason;

  // Геттеры для удобства
  bool get isNew => status.toLowerCase() == 'new';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isAccepted => status.toLowerCase() == 'accepted';
  bool get isInTransit => status.toLowerCase() == 'in_transit';
  bool get isDelivered {
    final s = status.toLowerCase();
    return s == 'delivered' || s == 'completed';
  }

  bool get isCancelled {
    final s = status.toLowerCase();
    return s == 'cancelled' || s == 'canceled';
  }

  bool get isRejected => status.toLowerCase() == 'rejected';

  // Алиасы для обратной совместимости
  bool get isPickingUp => isAccepted; // Для обратной совместимости
  bool get isFailed => false; // Не используется в новой модели

  // Алиасы для адресов (поддержка нового API с pickup/dropoff)
  String? get pickupAddress => senderPointAddress;
  String? get deliveryAddress => recipientPointAddress;
  double? get pickupLatitude => senderPointLatitude;
  double? get pickupLongitude => senderPointLongitude;
  double? get deliveryLatitude => recipientPointLatitude;
  double? get deliveryLongitude => recipientPointLongitude;

  // Прямые поля для нового API
  String? get parcelDescription => packageContent;
  double? get parcelEstimatedValue => estimatedValue;

  // Алиасы для контактов
  String? get pickupContactName => senderName;
  String? get pickupContactPhone => senderPhone;
  String? get deliveryContactName => recipientName;
  String get deliveryContactPhone => recipientPhone;

  // Алиасы для содержимого
  String? get cargoDescription => packageContent;
  double? get cargoWeightKg => null; // Не используется в новой модели
  double? get cargoVolumeM3 => null; // Не используется в новой модели

  // Расстояние (если есть в ответе API)
  final double? distanceKm;

  // Алиасы для цены и расстояния
  double get displayPrice => finalPrice;
  double get displayDistance => distanceKm ?? 0.0;

  // Алиасы для комментариев
  String? get customerComment => userComment;
  String? get driverComment =>
      adminComment; // В новой модели только adminComment

  // Алиасы для водителя (не используется в новой модели, но оставляем для совместимости)
  Driver? get driver => null; // В новой модели только driverId и driverName

  // Алиасы для временных меток
  DateTime? get pickedUpAt => null; // Не используется в новой модели
  DateTime? get cancelledAt => canceledAt;

  // Алиасы для метода оплаты
  String get paymentMethodName =>
      'Баланс приложения'; // В новой модели оплата через баланс

  String get statusName {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'new':
      case 'created':
        return 'Создан';
      case 'searching_driver':
        return 'Поиск водителя';
      case 'driver_assigned':
        return 'Водитель назначен';
      case 'driver_on_way':
        return 'Водитель в пути';
      case 'picked_up':
        return 'Посылка забрана';
      case 'in_delivery':
      case 'in_transit':
        return 'В доставке';
      case 'delivered':
        return 'Доставлено';
      case 'completed':
        return 'Завершён';
      case 'cancelled':
      case 'canceled':
        return 'Отменён';
      case 'pending':
        return 'Ожидает обработки';
      case 'accepted':
        return 'Принята в работу';
      case 'rejected':
        return 'Отклонена';
      default:
        return status;
    }
  }

  /// Парсинг ответа API по новому ТЗ (pickup_latitude, dropoff_latitude, parcel_description, delivery_cost)
  static DeliveryOrder _fromJsonTZ(Map<String, dynamic> json) {
    // Поддержка как нового формата (прямые поля), так и старого (вложенные объекты)
    String? pickupAddress;
    double? pickupLatitude;
    double? pickupLongitude;
    String? dropoffAddress;
    double? dropoffLatitude;
    double? dropoffLongitude;

    if (json.containsKey('pickup_latitude')) {
      // Новый формат: прямые поля
      pickupAddress = json['pickup_address'] as String?;
      pickupLatitude = json['pickup_latitude'] != null
          ? (json['pickup_latitude'] as num).toDouble()
          : null;
      pickupLongitude = json['pickup_longitude'] != null
          ? (json['pickup_longitude'] as num).toDouble()
          : null;
      dropoffAddress = json['dropoff_address'] as String?;
      dropoffLatitude = json['dropoff_latitude'] != null
          ? (json['dropoff_latitude'] as num).toDouble()
          : null;
      dropoffLongitude = json['dropoff_longitude'] != null
          ? (json['dropoff_longitude'] as num).toDouble()
          : null;
    } else if (json.containsKey('pickup')) {
      // Старый формат: вложенные объекты
      final pickup = json['pickup'] as Map<String, dynamic>?;
      final dropoff = json['dropoff'] as Map<String, dynamic>?;
      pickupAddress = pickup?['address'] as String?;
      pickupLatitude = pickup != null && pickup['latitude'] != null
          ? (pickup['latitude'] as num).toDouble()
          : null;
      pickupLongitude = pickup != null && pickup['longitude'] != null
          ? (pickup['longitude'] as num).toDouble()
          : null;
      dropoffAddress = dropoff?['address'] as String?;
      dropoffLatitude = dropoff != null && dropoff['latitude'] != null
          ? (dropoff['latitude'] as num).toDouble()
          : null;
      dropoffLongitude = dropoff != null && dropoff['longitude'] != null
          ? (dropoff['longitude'] as num).toDouble()
          : null;
    }

    // delivery_cost или final_price
    final deliveryCost =
        (json['delivery_cost'] as num?)?.toDouble() ??
        (json['final_price'] as num?)?.toDouble() ??
        0.0;
    final basePrice = (json['base_price'] as num?)?.toDouble() ?? deliveryCost;

    // Расстояние (если есть в ответе)
    final distanceKm = json['distance_km'] != null
        ? (json['distance_km'] as num).toDouble()
        : null;

    return DeliveryOrder(
      id: json['id'] as int,
      userId: json['user_id'] as int? ?? 0,
      packageSizeId: json['package_size_id'] as int? ?? 0,
      packageSizeCode: null,
      packageSizeName: null,
      regionId: null,
      regionName: null,
      senderPointName: null,
      senderPointAddress: pickupAddress,
      senderPointLatitude: pickupLatitude,
      senderPointLongitude: pickupLongitude,
      senderName: null,
      senderPhone: json['sender_phone'] as String? ?? '',
      recipientPointName: null,
      recipientPointAddress: dropoffAddress,
      recipientPointLatitude: dropoffLatitude,
      recipientPointLongitude: dropoffLongitude,
      recipientName: null,
      recipientPhone: json['recipient_phone'] as String? ?? '',
      packageContent: json['parcel_description'] as String?,
      estimatedValue: json['parcel_estimated_value'] != null
          ? (json['parcel_estimated_value'] as num).toDouble()
          : null,
      basePrice: basePrice,
      serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0.0,
      finalPrice: deliveryCost,
      currency: json['currency'] as String? ?? 'UZS',
      status: json['status'] as String? ?? 'created',
      driverId: json['driver_id'] as int?,
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      userComment: json['user_comment'] as String?,
      adminComment: json['admin_comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      canceledAt: json['canceled_at'] != null
          ? DateTime.parse(json['canceled_at'] as String)
          : null,
      cancelReason: json['cancel_reason'] as String?,
      distanceKm: distanceKm,
    );
  }

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    // Логируем для отладки
    if (kDebugMode) {
      print('📦 DeliveryOrder.fromJson: parsing order');
      print('   Keys: ${json.keys.toList()}');
      print('   Has pickup: ${json.containsKey('pickup')}');
      print('   Has pickup_latitude: ${json.containsKey('pickup_latitude')}');
      print('   Has pickup_address: ${json.containsKey('pickup_address')}');
      print('   Has delivery_cost: ${json.containsKey('delivery_cost')}');
    }

    // Проверяем, является ли это ответом нового API доставки
    // Используем более широкую проверку - если есть хотя бы одно из новых полей
    if (json.containsKey('pickup') ||
        json.containsKey('pickup_latitude') ||
        json.containsKey('pickup_address') ||
        json.containsKey('dropoff_latitude') ||
        json.containsKey('dropoff_address') ||
        json.containsKey('parcel_description') ||
        json.containsKey('delivery_cost') ||
        json.containsKey('driver_phone')) {
      if (kDebugMode) {
        print('   ✅ Using _fromJsonTZ (new API format)');
      }
      return _fromJsonTZ(json);
    }

    if (kDebugMode) {
      print('   ✅ Using standard fromJson (old API format)');
    }
    return DeliveryOrder(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      packageSizeId: json['package_size_id'] as int,
      packageSizeCode: json['package_size_code'] as String?,
      packageSizeName: json['package_size_name'] as String?,
      regionId: json['region_id'] as int?,
      regionName: json['region_name'] as String?,
      senderPointName: json['sender_point_name'] as String?,
      senderPointAddress: json['sender_point_address'] as String?,
      senderPointLatitude: json['sender_point_latitude'] != null
          ? (json['sender_point_latitude'] as num).toDouble()
          : null,
      senderPointLongitude: json['sender_point_longitude'] != null
          ? (json['sender_point_longitude'] as num).toDouble()
          : null,
      senderName: json['sender_name'] as String?,
      senderPhone: json['sender_phone'] as String,
      recipientPointName: json['recipient_point_name'] as String?,
      recipientPointAddress: json['recipient_point_address'] as String?,
      recipientPointLatitude: json['recipient_point_latitude'] != null
          ? (json['recipient_point_latitude'] as num).toDouble()
          : null,
      recipientPointLongitude: json['recipient_point_longitude'] != null
          ? (json['recipient_point_longitude'] as num).toDouble()
          : null,
      recipientName: json['recipient_name'] as String?,
      recipientPhone: json['recipient_phone'] as String,
      packageContent: json['package_content'] as String?,
      estimatedValue: json['estimated_value'] != null
          ? (json['estimated_value'] as num).toDouble()
          : null,
      basePrice: (json['base_price'] as num).toDouble(),
      serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0.0,
      finalPrice: (json['final_price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'UZS',
      status: json['status'] as String,
      driverId: json['driver_id'] as int?,
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      userComment: json['user_comment'] as String?,
      adminComment: json['admin_comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      acceptedAt: json['accepted_at'] != null
          ? DateTime.parse(json['accepted_at'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      canceledAt: json['canceled_at'] != null
          ? DateTime.parse(json['canceled_at'] as String)
          : null,
      cancelReason: json['cancel_reason'] as String?,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'package_size_id': packageSizeId,
      'package_size_code': packageSizeCode,
      'package_size_name': packageSizeName,
      'region_id': regionId,
      'region_name': regionName,
      'sender_point_name': senderPointName,
      'sender_point_address': senderPointAddress,
      'sender_point_latitude': senderPointLatitude,
      'sender_point_longitude': senderPointLongitude,
      'sender_name': senderName,
      'sender_phone': senderPhone,
      'recipient_point_name': recipientPointName,
      'recipient_point_address': recipientPointAddress,
      'recipient_point_latitude': recipientPointLatitude,
      'recipient_point_longitude': recipientPointLongitude,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'package_content': packageContent,
      'estimated_value': estimatedValue,
      'base_price': basePrice,
      'service_fee': serviceFee,
      'final_price': finalPrice,
      'currency': currency,
      'status': status,
      'driver_id': driverId,
      'driver_name': driverName,
      'user_comment': userComment,
      'admin_comment': adminComment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
    };
  }
}
