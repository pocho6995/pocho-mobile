import 'dart:io';
import '../models/delivery/region.dart';
import '../models/delivery/delivery_screen_content.dart';
import '../models/delivery/driver.dart';
import '../models/delivery/driver_document.dart';
import '../models/delivery/vehicle.dart';
import '../models/delivery/delivery_order.dart';
import '../models/delivery/delivery_calculator.dart';
import '../models/delivery/delivery_api_tz.dart';
import '../models/delivery/package_size.dart';
import '../services/delivery_service.dart';

/// Репозиторий для работы с доставкой
/// Инкапсулирует бизнес-логику и обработку ошибок
class DeliveryRepository {
  final DeliveryService deliveryService;

  DeliveryRepository({required this.deliveryService});

  // ==================== Regions ====================

  Future<List<Region>> getRegions({bool? isActive}) async {
    try {
      return await deliveryService.getRegions(isActive: isActive);
    } catch (e) {
      throw Exception('Ошибка при получении регионов: ${e.toString()}');
    }
  }

  Future<Region> getRegion(int regionId) async {
    try {
      return await deliveryService.getRegion(regionId);
    } catch (e) {
      throw Exception('Ошибка при получении региона: ${e.toString()}');
    }
  }

  /// Контент экрана «По регионам Узбекистана»
  Future<DeliveryScreenContent> getDeliveryScreenContent() async {
    try {
      return await deliveryService.getDeliveryScreenContent();
    } catch (e) {
      throw Exception(
        'Ошибка при получении контента экрана доставки: ${e.toString()}',
      );
    }
  }

  // ==================== Drivers ====================

  Future<Driver> registerDriver({
    required String phoneNumber,
    required String fullName,
    required String email,
    required int regionId,
  }) async {
    try {
      return await deliveryService.registerDriver(
        phoneNumber: phoneNumber,
        fullName: fullName,
        email: email,
        regionId: regionId,
      );
    } catch (e) {
      throw Exception('Ошибка при регистрации водителя: ${e.toString()}');
    }
  }

  Future<Driver> getMyDriverProfile() async {
    try {
      return await deliveryService.getMyDriverProfile();
    } catch (e) {
      throw Exception('Ошибка при получении профиля водителя: ${e.toString()}');
    }
  }

  Future<Driver> updateDriverProfile({
    String? fullName,
    String? email,
    int? regionId,
    String? photoUrl,
    bool? autoAcceptOrders,
  }) async {
    try {
      return await deliveryService.updateDriverProfile(
        fullName: fullName,
        email: email,
        regionId: regionId,
        photoUrl: photoUrl,
        autoAcceptOrders: autoAcceptOrders,
      );
    } catch (e) {
      throw Exception('Ошибка при обновлении профиля: ${e.toString()}');
    }
  }

  Future<void> updateDriverLocation({
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
  }) async {
    try {
      await deliveryService.updateDriverLocation(
        latitude: latitude,
        longitude: longitude,
        speed: speed,
        heading: heading,
        accuracy: accuracy,
      );
    } catch (e) {
      throw Exception('Ошибка при обновлении геолокации: ${e.toString()}');
    }
  }

  Future<void> updateOnlineStatus({required bool isOnline}) async {
    try {
      await deliveryService.updateOnlineStatus(isOnline: isOnline);
    } catch (e) {
      throw Exception('Ошибка при обновлении статуса: ${e.toString()}');
    }
  }

  Future<DriverStatistics> getDriverStatistics() async {
    try {
      return await deliveryService.getDriverStatistics();
    } catch (e) {
      throw Exception('Ошибка при получении статистики: ${e.toString()}');
    }
  }

  // ==================== Driver Documents ====================

  Future<String> uploadDocumentImage(File imageFile) async {
    try {
      return await deliveryService.uploadDocumentImage(imageFile);
    } catch (e) {
      throw Exception('Ошибка при загрузке изображения: ${e.toString()}');
    }
  }

  Future<DriverDocument> uploadDocument({
    required String documentType,
    required String frontImageUrl,
    String? backImageUrl,
    String? documentNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    try {
      return await deliveryService.uploadDocument(
        documentType: documentType,
        frontImageUrl: frontImageUrl,
        backImageUrl: backImageUrl,
        documentNumber: documentNumber,
        issueDate: issueDate,
        expiryDate: expiryDate,
      );
    } catch (e) {
      throw Exception('Ошибка при загрузке документа: ${e.toString()}');
    }
  }

  Future<List<DriverDocument>> getDocuments() async {
    try {
      return await deliveryService.getDocuments();
    } catch (e) {
      throw Exception('Ошибка при получении документов: ${e.toString()}');
    }
  }

  Future<DriverDocument> getDocumentByType(String documentType) async {
    try {
      return await deliveryService.getDocumentByType(documentType);
    } catch (e) {
      throw Exception('Ошибка при получении документа: ${e.toString()}');
    }
  }

  Future<DriverDocument> updateDocument({
    required String documentType,
    String? frontImageUrl,
    String? backImageUrl,
    String? documentNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    try {
      return await deliveryService.updateDocument(
        documentType: documentType,
        frontImageUrl: frontImageUrl,
        backImageUrl: backImageUrl,
        documentNumber: documentNumber,
        issueDate: issueDate,
        expiryDate: expiryDate,
      );
    } catch (e) {
      throw Exception('Ошибка при обновлении документа: ${e.toString()}');
    }
  }

  // ==================== Vehicle ====================

  Future<Vehicle> registerVehicle({
    required String vehicleType,
    required String brand,
    required String model,
    required int year,
    required String color,
    required String licensePlate,
    required String vehiclePassportNumber,
    String? photoUrl,
    double? capacityKg,
    double? volumeM3,
  }) async {
    try {
      return await deliveryService.registerVehicle(
        vehicleType: vehicleType,
        brand: brand,
        model: model,
        year: year,
        color: color,
        licensePlate: licensePlate,
        vehiclePassportNumber: vehiclePassportNumber,
        photoUrl: photoUrl,
        capacityKg: capacityKg,
        volumeM3: volumeM3,
      );
    } catch (e) {
      throw Exception('Ошибка при регистрации ТС: ${e.toString()}');
    }
  }

  Future<Vehicle> getVehicle() async {
    try {
      return await deliveryService.getVehicle();
    } catch (e) {
      throw Exception('Ошибка при получении ТС: ${e.toString()}');
    }
  }

  Future<Vehicle> updateVehicle({
    String? vehicleType,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? licensePlate,
    String? vehiclePassportNumber,
    String? photoUrl,
    double? capacityKg,
    double? volumeM3,
  }) async {
    try {
      return await deliveryService.updateVehicle(
        vehicleType: vehicleType,
        brand: brand,
        model: model,
        year: year,
        color: color,
        licensePlate: licensePlate,
        vehiclePassportNumber: vehiclePassportNumber,
        photoUrl: photoUrl,
        capacityKg: capacityKg,
        volumeM3: volumeM3,
      );
    } catch (e) {
      throw Exception('Ошибка при обновлении ТС: ${e.toString()}');
    }
  }

  // ==================== Delivery Orders ====================

  /// Создать заявку на доставку (новый API)
  Future<DeliveryOrder> createDeliveryOrder({
    required int packageSizeId,
    int? regionId,
    String? senderPointName,
    String? senderPointAddress,
    double? senderPointLatitude,
    double? senderPointLongitude,
    String? senderName,
    required String senderPhone,
    String? recipientPointName,
    String? recipientPointAddress,
    double? recipientPointLatitude,
    double? recipientPointLongitude,
    String? recipientName,
    required String recipientPhone,
    String? packageContent,
    double? estimatedValue,
    String? userComment,
  }) async {
    try {
      return await deliveryService.createDeliveryOrder(
        packageSizeId: packageSizeId,
        regionId: regionId,
        senderPointName: senderPointName,
        senderPointAddress: senderPointAddress,
        senderPointLatitude: senderPointLatitude,
        senderPointLongitude: senderPointLongitude,
        senderName: senderName,
        senderPhone: senderPhone,
        recipientPointName: recipientPointName,
        recipientPointAddress: recipientPointAddress,
        recipientPointLatitude: recipientPointLatitude,
        recipientPointLongitude: recipientPointLongitude,
        recipientName: recipientName,
        recipientPhone: recipientPhone,
        packageContent: packageContent,
        estimatedValue: estimatedValue,
        userComment: userComment,
      );
    } catch (e) {
      throw Exception('Ошибка при создании заявки: ${e.toString()}');
    }
  }

  /// Получить список своих заявок на доставку
  Future<List<DeliveryOrder>> getMyDeliveryOrders({
    int? skip,
    int? limit,
    String? status,
  }) async {
    try {
      return await deliveryService.getMyDeliveryOrders(
        skip: skip,
        limit: limit,
        status: status,
      );
    } catch (e) {
      throw Exception('Ошибка при получении заявок: ${e.toString()}');
    }
  }

  /// Получить заявку по ID
  Future<DeliveryOrder> getDeliveryOrderById(int orderId) async {
    try {
      return await deliveryService.getDeliveryOrderById(orderId);
    } catch (e) {
      throw Exception('Ошибка при получении заявки: ${e.toString()}');
    }
  }

  /// Создать заказ (старый метод для обратной совместимости)
  @Deprecated('Use createDeliveryOrder instead')
  Future<DeliveryOrder> createOrder({
    int? regionId,
    required String pickupAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    String? pickupContactName,
    required String pickupContactPhone,
    String? deliveryContactName,
    String? deliveryContactPhone,
    String? cargoDescription,
    double? cargoWeightKg,
    double? cargoVolumeM3,
    required double price,
    String currency = 'UZS',
    String paymentMethod = 'cash',
    String? customerComment,
  }) async {
    try {
      return await deliveryService.createOrder(
        regionId: regionId,
        pickupAddress: pickupAddress,
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        deliveryAddress: deliveryAddress,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        pickupContactName: pickupContactName,
        pickupContactPhone: pickupContactPhone,
        deliveryContactName: deliveryContactName,
        deliveryContactPhone: deliveryContactPhone,
        cargoDescription: cargoDescription,
        cargoWeightKg: cargoWeightKg,
        cargoVolumeM3: cargoVolumeM3,
        price: price,
        currency: currency,
        paymentMethod: paymentMethod,
        customerComment: customerComment,
      );
    } catch (e) {
      throw Exception('Ошибка при создании заказа: ${e.toString()}');
    }
  }

  /// Получить список заказов (старый метод для обратной совместимости)
  @Deprecated('Use getMyDeliveryOrders instead')
  Future<List<DeliveryOrder>> getOrders({
    int? skip,
    int? limit,
    String? status,
    int? regionId,
  }) async {
    return getMyDeliveryOrders(skip: skip, limit: limit, status: status);
  }

  /// Получить заказ по ID (старый метод для обратной совместимости)
  @Deprecated('Use getDeliveryOrderById instead')
  Future<DeliveryOrder> getOrder(int orderId) async {
    return getDeliveryOrderById(orderId);
  }

  Future<DeliveryOrder> acceptOrder(int orderId) async {
    try {
      return await deliveryService.acceptOrder(orderId);
    } catch (e) {
      throw Exception('Ошибка при принятии заказа: ${e.toString()}');
    }
  }

  Future<List<Driver>> getAvailableDrivers({
    required int orderId,
    double? radiusKm,
  }) async {
    try {
      return await deliveryService.getAvailableDrivers(
        orderId: orderId,
        radiusKm: radiusKm,
      );
    } catch (e) {
      throw Exception('Ошибка при получении водителей: ${e.toString()}');
    }
  }

  Future<DeliveryOrder> updateOrderStatus({
    required int orderId,
    required String status,
    String? driverComment,
  }) async {
    try {
      return await deliveryService.updateOrderStatus(
        orderId: orderId,
        status: status,
        driverComment: driverComment,
      );
    } catch (e) {
      throw Exception('Ошибка при обновлении статуса: ${e.toString()}');
    }
  }

  // ==================== Delivery Calculator ====================

  Future<DeliveryCalculationResponse> calculateDelivery({
    required double pickupLatitude,
    required double pickupLongitude,
    required double deliveryLatitude,
    required double deliveryLongitude,
    double weightKg = 0.0,
    double volumeM3 = 0.0,
  }) async {
    try {
      return await deliveryService.calculateDelivery(
        pickupLatitude: pickupLatitude,
        pickupLongitude: pickupLongitude,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        weightKg: weightKg,
        volumeM3: volumeM3,
      );
    } catch (e) {
      throw Exception('Ошибка при расчете стоимости: ${e.toString()}');
    }
  }

  // ==================== Pricing ====================

  /// Получить список размеров посылок
  Future<List<PackageSize>> getPackageSizes({int? regionId}) async {
    try {
      return await deliveryService.getPackageSizes(regionId: regionId);
    } catch (e) {
      throw Exception('Ошибка при получении размеров посылок: ${e.toString()}');
    }
  }

  /// Получить размеры посылок с ценами
  Future<List<PackageSize>> getPackageSizesWithPrices({int? regionId}) async {
    try {
      return await deliveryService.getPackageSizesWithPrices(
        regionId: regionId,
      );
    } catch (e) {
      throw Exception(
        'Ошибка при получении размеров с ценами: ${e.toString()}',
      );
    }
  }

  /// Получить размер посылки по ID
  Future<PackageSize> getPackageSizeById(int sizeId) async {
    try {
      return await deliveryService.getPackageSizeById(sizeId);
    } catch (e) {
      throw Exception('Ошибка при получении размера посылки: ${e.toString()}');
    }
  }

  /// Рассчитать цену доставки
  Future<PriceCalculationResponse> calculatePrice({
    required int packageSizeId,
    int? regionId,
    double? weight,
  }) async {
    try {
      return await deliveryService.calculatePrice(
        packageSizeId: packageSizeId,
        regionId: regionId,
        weight: weight,
      );
    } catch (e) {
      throw Exception('Ошибка при расчете цены: ${e.toString()}');
    }
  }

  // ==================== Delivery API (ТЗ) ====================

  Future<DeliveryCalculatePriceResponse> calculateDeliveryPrice({
    required DeliveryAddressPoint pickup,
    required DeliveryAddressPoint dropoff,
  }) async {
    try {
      return await deliveryService.calculateDeliveryPrice(
        pickup: pickup,
        dropoff: dropoff,
      );
    } catch (e) {
      throw Exception('Ошибка при расчёте стоимости: ${e.toString()}');
    }
  }

  Future<DeliveryOrder> createOrderByPoints({
    required DeliveryAddressPoint pickup,
    required DeliveryAddressPoint dropoff,
    String? parcelDescription,
    double? parcelEstimatedValue,
  }) async {
    try {
      return await deliveryService.createOrderByPoints(
        pickup: pickup,
        dropoff: dropoff,
        parcelDescription: parcelDescription,
        parcelEstimatedValue: parcelEstimatedValue,
      );
    } catch (e) {
      throw Exception('Ошибка при создании заказа: ${e.toString()}');
    }
  }

  Future<List<DeliveryOrder>> getMyOrders({
    int? skip,
    int? limit,
    String? status,
  }) async {
    try {
      return await deliveryService.getMyOrders(
        skip: skip,
        limit: limit,
        status: status,
      );
    } catch (e) {
      throw Exception('Ошибка при получении заказов: ${e.toString()}');
    }
  }

  Future<DeliveryOrder> getOrderById(int orderId) async {
    try {
      return await deliveryService.getOrderById(orderId);
    } catch (e) {
      throw Exception('Ошибка при получении заказа: ${e.toString()}');
    }
  }

  Future<DeliveryOrder> cancelOrder(int orderId, {String? reason}) async {
    try {
      return await deliveryService.cancelOrder(orderId, reason: reason);
    } catch (e) {
      throw Exception('Ошибка при отмене заказа: ${e.toString()}');
    }
  }

  Future<DeliveryBalanceResponse> getDeliveryBalance() async {
    try {
      return await deliveryService.getDeliveryBalance();
    } catch (e) {
      throw Exception('Ошибка при получении баланса: ${e.toString()}');
    }
  }

  Future<List<DeliveryBalanceLogEntry>> getDeliveryBalanceLog({
    int? skip,
    int? limit,
  }) async {
    try {
      return await deliveryService.getDeliveryBalanceLog(
        skip: skip,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Ошибка при получении истории баланса: ${e.toString()}');
    }
  }

  Future<List<DeliveryOrder>> getDriverOrdersTZ({String? status}) async {
    try {
      return await deliveryService.getDriverOrdersTZ(status: status);
    } catch (e) {
      throw Exception('Ошибка при получении заказов водителя: ${e.toString()}');
    }
  }

  Future<DeliveryOrder> getDriverOrderById(int orderId) async {
    try {
      return await deliveryService.getDriverOrderById(orderId);
    } catch (e) {
      throw Exception('Ошибка при получении заказа: ${e.toString()}');
    }
  }

  Future<DeliveryOrder> acceptDriverOrder(int orderId) async {
    try {
      return await deliveryService.acceptDriverOrder(orderId);
    } catch (e) {
      throw Exception('Ошибка при принятии заказа: ${e.toString()}');
    }
  }

  Future<void> rejectDriverOrder(int orderId) async {
    try {
      return await deliveryService.rejectDriverOrder(orderId);
    } catch (e) {
      throw Exception('Ошибка при отклонении заказа: ${e.toString()}');
    }
  }

  Future<DeliveryOrder> updateDriverOrderStatus(
    int orderId,
    String status,
  ) async {
    try {
      return await deliveryService.updateDriverOrderStatus(orderId, status);
    } catch (e) {
      throw Exception('Ошибка при обновлении статуса: ${e.toString()}');
    }
  }
}
