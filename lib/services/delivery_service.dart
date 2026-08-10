import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/delivery/region.dart';
import '../models/delivery/delivery_screen_content.dart';
import '../models/delivery/driver.dart';
import '../models/delivery/driver_document.dart';
import '../models/delivery/vehicle.dart';
import '../models/delivery/delivery_order.dart';
import '../models/delivery/delivery_calculator.dart';
import '../models/delivery/delivery_api_tz.dart';
import '../models/delivery/package_size.dart';
import 'api_client.dart';

class DeliveryService {
  final ApiClient apiClient;

  DeliveryService({required this.apiClient});

  // ==================== Regions ====================

  /// Получить список регионов
  Future<List<Region>> getRegions({bool? isActive}) async {
    try {
      final queryParams = <String, String>{};
      if (isActive != null) {
        queryParams['is_active'] = isActive.toString();
      }

      final response = await apiClient.get(
        '/api/v1/regions',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = apiClient.parseListResponse(response);
      if (data == null) {
        return [];
      }

      return data
          .map((json) => Region.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getRegions error: $e');
      }
      rethrow;
    }
  }

  /// Получить регион по ID
  Future<Region> getRegion(int regionId) async {
    try {
      final response = await apiClient.get('/api/v1/regions/$regionId');
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse region');
      }
      return Region.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getRegion error: $e');
      }
      rethrow;
    }
  }

  /// Получить контент экрана доставки (карточка, кнопка, сервисный сбор)
  Future<DeliveryScreenContent> getDeliveryScreenContent() async {
    try {
      final response = await apiClient.get(
        '/api/v1/regions/delivery-screen-content',
      );
      final data = apiClient.parseResponse(response);
      if (data == null) {
        return DeliveryScreenContent.defaults;
      }
      return DeliveryScreenContent.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getDeliveryScreenContent error: $e');
      }
      rethrow;
    }
  }

  // ==================== Drivers ====================

  /// Регистрация как водитель
  Future<Driver> registerDriver({
    required String phoneNumber,
    required String fullName,
    required String email,
    required int regionId,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/v1/drivers/register',
        body: {
          'phone_number': phoneNumber,
          'full_name': fullName,
          'email': email,
          'region_id': regionId,
        },
      );

      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse driver registration');
      }
      return Driver.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.registerDriver error: $e');
      }
      rethrow;
    }
  }

  /// Получить свой профиль водителя
  Future<Driver> getMyDriverProfile() async {
    try {
      final response = await apiClient.get('/api/v1/drivers/me');
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse driver profile');
      }
      return Driver.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getMyDriverProfile error: $e');
      }
      rethrow;
    }
  }

  /// Обновить профиль водителя
  Future<Driver> updateDriverProfile({
    String? fullName,
    String? email,
    int? regionId,
    String? photoUrl,
    bool? autoAcceptOrders,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fullName != null) body['full_name'] = fullName;
      if (email != null) body['email'] = email;
      if (regionId != null) body['region_id'] = regionId;
      if (photoUrl != null) body['photo_url'] = photoUrl;
      if (autoAcceptOrders != null)
        body['auto_accept_orders'] = autoAcceptOrders;

      final response = await apiClient.put('/api/v1/drivers/me', body: body);

      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse driver profile');
      }
      return Driver.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.updateDriverProfile error: $e');
      }
      rethrow;
    }
  }

  /// Обновить геолокацию водителя
  Future<void> updateDriverLocation({
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
  }) async {
    try {
      final body = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      };
      if (speed != null) body['speed'] = speed;
      if (heading != null) body['heading'] = heading;
      if (accuracy != null) body['accuracy'] = accuracy;

      await apiClient.post('/api/v1/drivers/me/location', body: body);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.updateDriverLocation error: $e');
      }
      rethrow;
    }
  }

  /// Обновить статус онлайн/оффлайн
  Future<void> updateOnlineStatus({required bool isOnline}) async {
    try {
      await apiClient.post(
        '/api/v1/drivers/me/online-status',
        body: {'is_online': isOnline},
      );
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.updateOnlineStatus error: $e');
      }
      rethrow;
    }
  }

  /// Получить статистику водителя
  Future<DriverStatistics> getDriverStatistics() async {
    try {
      final response = await apiClient.get('/api/v1/drivers/me/statistics');
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse driver statistics');
      }
      return DriverStatistics.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getDriverStatistics error: $e');
      }
      rethrow;
    }
  }

  // ==================== Driver Documents ====================

  /// Загрузить изображение документа и получить URL
  Future<String> uploadDocumentImage(File imageFile) async {
    try {
      final token = await apiClient.tokenStorage?.getAccessToken();
      if (token == null) {
        throw Exception('Токен не найден');
      }

      final uri = Uri.parse(
        '${ApiClient.baseUrl}/api/v1/drivers/me/documents/upload-image',
      );

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Определяем MediaType
      final extension = imageFile.path.split('.').last.toLowerCase();
      MediaType? mediaType;
      if (['jpg', 'jpeg'].contains(extension)) {
        mediaType = MediaType('image', 'jpeg');
      } else if (extension == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (extension == 'webp') {
        mediaType = MediaType('image', 'webp');
      } else {
        mediaType = MediaType('image', 'jpeg');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: imageFile.path.split('/').last,
          contentType: mediaType,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = apiClient.parseResponse(response);
        if (data != null && data['file_url'] != null) {
          return data['file_url'] as String;
        } else if (data != null && data['image_url'] != null) {
          return data['image_url'] as String;
        } else if (data != null && data['url'] != null) {
          return data['url'] as String;
        }
        throw Exception('URL изображения не найден в ответе');
      } else {
        throw Exception('Ошибка загрузки изображения: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.uploadDocumentImage error: $e');
      }
      rethrow;
    }
  }

  /// Загрузить документ
  Future<DriverDocument> uploadDocument({
    required String documentType,
    required String frontImageUrl,
    String? backImageUrl,
    String? documentNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    try {
      final body = <String, dynamic>{
        'document_type': documentType,
        'front_image_url': frontImageUrl,
      };
      if (backImageUrl != null) body['back_image_url'] = backImageUrl;
      if (documentNumber != null) body['document_number'] = documentNumber;
      if (issueDate != null) body['issue_date'] = issueDate.toIso8601String();
      if (expiryDate != null)
        body['expiry_date'] = expiryDate.toIso8601String();

      final response = await apiClient.post(
        '/api/v1/drivers/me/documents',
        body: body,
      );

      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse document');
      }
      return DriverDocument.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.uploadDocument error: $e');
      }
      rethrow;
    }
  }

  /// Получить все документы
  Future<List<DriverDocument>> getDocuments() async {
    try {
      final response = await apiClient.get('/api/v1/drivers/me/documents');
      final data = apiClient.parseListResponse(response);
      if (data == null) {
        return [];
      }
      return data
          .map((json) => DriverDocument.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getDocuments error: $e');
      }
      rethrow;
    }
  }

  /// Получить документ по типу
  Future<DriverDocument> getDocumentByType(String documentType) async {
    try {
      final response = await apiClient.get(
        '/api/v1/drivers/me/documents/$documentType',
      );
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse document');
      }
      return DriverDocument.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getDocumentByType error: $e');
      }
      rethrow;
    }
  }

  /// Обновить документ
  Future<DriverDocument> updateDocument({
    required String documentType,
    String? frontImageUrl,
    String? backImageUrl,
    String? documentNumber,
    DateTime? issueDate,
    DateTime? expiryDate,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (frontImageUrl != null) body['front_image_url'] = frontImageUrl;
      if (backImageUrl != null) body['back_image_url'] = backImageUrl;
      if (documentNumber != null) body['document_number'] = documentNumber;
      if (issueDate != null) body['issue_date'] = issueDate.toIso8601String();
      if (expiryDate != null)
        body['expiry_date'] = expiryDate.toIso8601String();

      final response = await apiClient.put(
        '/api/v1/drivers/me/documents/$documentType',
        body: body,
      );

      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse document');
      }
      return DriverDocument.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.updateDocument error: $e');
      }
      rethrow;
    }
  }

  // ==================== Vehicle ====================

  /// Зарегистрировать ТС
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
      final body = <String, dynamic>{
        'vehicle_type': vehicleType,
        'brand': brand,
        'model': model,
        'year': year,
        'color': color,
        'license_plate': licensePlate,
        'vehicle_passport_number': vehiclePassportNumber,
      };
      if (photoUrl != null) body['photo_url'] = photoUrl;
      if (capacityKg != null) body['capacity_kg'] = capacityKg;
      if (volumeM3 != null) body['volume_m3'] = volumeM3;

      final response = await apiClient.post(
        '/api/v1/drivers/me/vehicle',
        body: body,
      );

      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse vehicle');
      }
      return Vehicle.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.registerVehicle error: $e');
      }
      rethrow;
    }
  }

  /// Получить ТС
  Future<Vehicle> getVehicle() async {
    try {
      final response = await apiClient.get('/api/v1/drivers/me/vehicle');
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse vehicle');
      }
      return Vehicle.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getVehicle error: $e');
      }
      rethrow;
    }
  }

  /// Обновить ТС
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
      final body = <String, dynamic>{};
      if (vehicleType != null) body['vehicle_type'] = vehicleType;
      if (brand != null) body['brand'] = brand;
      if (model != null) body['model'] = model;
      if (year != null) body['year'] = year;
      if (color != null) body['color'] = color;
      if (licensePlate != null) body['license_plate'] = licensePlate;
      if (vehiclePassportNumber != null)
        body['vehicle_passport_number'] = vehiclePassportNumber;
      if (photoUrl != null) body['photo_url'] = photoUrl;
      if (capacityKg != null) body['capacity_kg'] = capacityKg;
      if (volumeM3 != null) body['volume_m3'] = volumeM3;

      final response = await apiClient.put(
        '/api/v1/drivers/me/vehicle',
        body: body,
      );

      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse vehicle');
      }
      return Vehicle.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.updateVehicle error: $e');
      }
      rethrow;
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
      final body = <String, dynamic>{
        'package_size_id': packageSizeId,
        'sender_phone': senderPhone,
        'recipient_phone': recipientPhone,
      };

      if (regionId != null) body['region_id'] = regionId;
      if (senderPointName != null) body['sender_point_name'] = senderPointName;
      if (senderPointAddress != null)
        body['sender_point_address'] = senderPointAddress;
      if (senderPointLatitude != null)
        body['sender_point_latitude'] = senderPointLatitude;
      if (senderPointLongitude != null)
        body['sender_point_longitude'] = senderPointLongitude;
      if (senderName != null) body['sender_name'] = senderName;
      if (recipientPointName != null)
        body['recipient_point_name'] = recipientPointName;
      if (recipientPointAddress != null)
        body['recipient_point_address'] = recipientPointAddress;
      if (recipientPointLatitude != null)
        body['recipient_point_latitude'] = recipientPointLatitude;
      if (recipientPointLongitude != null)
        body['recipient_point_longitude'] = recipientPointLongitude;
      if (recipientName != null) body['recipient_name'] = recipientName;
      if (packageContent != null) body['package_content'] = packageContent;
      if (estimatedValue != null) body['estimated_value'] = estimatedValue;
      if (userComment != null) body['user_comment'] = userComment;

      final response = await apiClient.post(
        '/api/v1/delivery-orders',
        body: body,
      );

      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse order');
      }
      return DeliveryOrder.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.createDeliveryOrder error: $e');
      }
      rethrow;
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
    return createDeliveryOrder(
      packageSizeId: 1, // По умолчанию размер S
      regionId: regionId,
      senderPointAddress: pickupAddress,
      senderPointLatitude: pickupLatitude,
      senderPointLongitude: pickupLongitude,
      senderName: pickupContactName,
      senderPhone: pickupContactPhone,
      recipientPointAddress: deliveryAddress,
      recipientPointLatitude: deliveryLatitude,
      recipientPointLongitude: deliveryLongitude,
      recipientName: deliveryContactName,
      recipientPhone: deliveryContactPhone ?? pickupContactPhone,
      packageContent: cargoDescription,
      estimatedValue: null,
      userComment: customerComment,
    );
  }

  /// Получить список своих заявок на доставку
  Future<List<DeliveryOrder>> getMyDeliveryOrders({
    int? skip,
    int? limit,
    String?
    status, // new, pending, accepted, in_transit, delivered, cancelled, rejected
  }) async {
    try {
      final queryParams = <String, String>{};
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (status != null) queryParams['status'] = status;

      final response = await apiClient.get(
        '/api/v1/delivery-orders',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = apiClient.parseListResponse(response);
      if (data == null) {
        return [];
      }
      return data
          .map((json) => DeliveryOrder.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getMyDeliveryOrders error: $e');
      }
      rethrow;
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

  /// Получить список заказов водителя
  Future<List<DeliveryOrder>> getDriverOrders({
    String? status, // ASSIGNED или ACTIVE (ACCEPTED/PICKED_UP/ON_THE_WAY)
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;

      final response = await apiClient.get(
        '/api/v1/driver/orders',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = apiClient.parseListResponse(response);
      if (data == null) {
        return [];
      }
      return data
          .map((json) => DeliveryOrder.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getDriverOrders error: $e');
      }
      rethrow;
    }
  }

  /// Получить заявку по ID
  Future<DeliveryOrder> getDeliveryOrderById(int orderId) async {
    try {
      final response = await apiClient.get('/api/v1/delivery-orders/$orderId');
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse order');
      }
      return DeliveryOrder.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getDeliveryOrderById error: $e');
      }
      rethrow;
    }
  }

  /// Получить заказ по ID (старый метод для обратной совместимости)
  @Deprecated('Use getDeliveryOrderById instead')
  Future<DeliveryOrder> getOrder(int orderId) async {
    return getDeliveryOrderById(orderId);
  }

  /// Принять заказ (для водителя)
  Future<DeliveryOrder> acceptOrder(int orderId) async {
    try {
      final response = await apiClient.post(
        '/api/v1/delivery-orders/$orderId/accept',
      );
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse order');
      }
      return DeliveryOrder.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.acceptOrder error: $e');
      }
      rethrow;
    }
  }

  /// Получить доступных водителей для заказа
  Future<List<Driver>> getAvailableDrivers({
    required int orderId,
    double? radiusKm,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (radiusKm != null) queryParams['radius_km'] = radiusKm.toString();

      final response = await apiClient.get(
        '/api/v1/delivery-orders/$orderId/available-drivers',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = apiClient.parseListResponse(response);
      if (data == null) {
        return [];
      }
      return data
          .map((json) => Driver.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getAvailableDrivers error: $e');
      }
      rethrow;
    }
  }

  /// Обновить статус заказа (для водителя)
  /// Доступные переходы: accepted → picked_up → on_the_way → delivered
  Future<DeliveryOrder> updateOrderStatus({
    required int orderId,
    required String status, // picked_up, on_the_way, delivered
    String? driverComment,
  }) async {
    try {
      final body = <String, dynamic>{'status': status};
      if (driverComment != null && driverComment.isNotEmpty) {
        body['driver_comment'] = driverComment;
      }

      final response = await apiClient.post(
        '/api/v1/delivery-orders/$orderId/status',
        body: body,
      );

      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse order');
      }
      return DeliveryOrder.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.updateOrderStatus error: $e');
      }
      rethrow;
    }
  }

  // ==================== Delivery Calculator ====================

  /// Рассчитать стоимость доставки
  Future<DeliveryCalculationResponse> calculateDelivery({
    required double pickupLatitude,
    required double pickupLongitude,
    required double deliveryLatitude,
    required double deliveryLongitude,
    double weightKg = 0.0,
    double volumeM3 = 0.0,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/v1/delivery-calculator/calculate',
        body: {
          'pickup_latitude': pickupLatitude,
          'pickup_longitude': pickupLongitude,
          'delivery_latitude': deliveryLatitude,
          'delivery_longitude': deliveryLongitude,
          'weight_kg': weightKg,
          'volume_m3': volumeM3,
        },
      );

      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse calculation');
      }
      return DeliveryCalculationResponse.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.calculateDelivery error: $e');
      }
      rethrow;
    }
  }

  // ==================== Pricing ====================

  /// Получить список размеров посылок
  Future<List<PackageSize>> getPackageSizes({int? regionId}) async {
    try {
      final queryParams = <String, String>{};
      if (regionId != null) {
        queryParams['region_id'] = regionId.toString();
      }

      final response = await apiClient.get(
        '/api/v1/pricing/package-sizes',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = apiClient.parseListResponse(response);
      if (data == null) {
        return [];
      }

      return data
          .map((json) => PackageSize.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getPackageSizes error: $e');
      }
      rethrow;
    }
  }

  /// Получить размеры посылок с ценами (с повтором при ошибках соединения)
  Future<List<PackageSize>> getPackageSizesWithPrices({int? regionId}) async {
    const maxAttempts = 3;
    const retryDelay = Duration(milliseconds: 1500);

    final queryParams = <String, String>{};
    if (regionId != null) {
      queryParams['region_id'] = regionId.toString();
    }

    Object? lastError;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await apiClient.get(
          '/api/v1/pricing/package-sizes/with-prices',
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );

        final data = apiClient.parseListResponse(response);
        if (data == null) {
          return [];
        }

        return data
            .map((json) => PackageSize.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        lastError = e;
        final msg = e.toString().toLowerCase();
        final isConnectionError =
            msg.contains('connection closed') ||
            msg.contains('connection refused') ||
            msg.contains('connection reset') ||
            msg.contains('socketexception') ||
            msg.contains('clientexception');
        if (isConnectionError && attempt < maxAttempts) {
          if (kDebugMode) {
            print(
              'DeliveryService.getPackageSizesWithPrices attempt $attempt failed, retrying in ${retryDelay.inMilliseconds}ms: $e',
            );
          }
          await Future<void>.delayed(retryDelay);
          continue;
        }
        if (kDebugMode) {
          print('DeliveryService.getPackageSizesWithPrices error: $e');
        }
        rethrow;
      }
    }
    throw lastError ?? Exception('Failed to load package sizes');
  }

  /// Получить размер посылки по ID
  Future<PackageSize> getPackageSizeById(int sizeId) async {
    try {
      final response = await apiClient.get(
        '/api/v1/pricing/package-sizes/$sizeId',
      );
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse package size');
      }
      return PackageSize.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getPackageSizeById error: $e');
      }
      rethrow;
    }
  }

  /// Рассчитать цену доставки
  Future<PriceCalculationResponse> calculatePrice({
    required int packageSizeId,
    int? regionId,
    double? weight,
  }) async {
    try {
      final body = <String, dynamic>{'package_size_id': packageSizeId};
      if (regionId != null) body['region_id'] = regionId;
      if (weight != null) body['weight'] = weight;

      final response = await apiClient.post(
        '/api/v1/pricing/calculate',
        body: body,
      );

      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Failed to parse price calculation');
      }
      return PriceCalculationResponse.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.calculatePrice error: $e');
      }
      rethrow;
    }
  }

  // ==================== Delivery API (ТЗ) ====================

  /// Расчёт стоимости POST /api/v1/delivery/calculate-price (ТЗ п.2.4)
  Future<DeliveryCalculatePriceResponse> calculateDeliveryPrice({
    required DeliveryAddressPoint pickup,
    required DeliveryAddressPoint dropoff,
  }) async {
    try {
      final response = await apiClient.post(
        '/api/v1/delivery/calculate-price',
        body: {'pickup': pickup.toJson(), 'dropoff': dropoff.toJson()},
      );
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Не удалось рассчитать стоимость');
      }
      return DeliveryCalculatePriceResponse.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.calculateDeliveryPrice error: $e');
      }
      rethrow;
    }
  }

  /// Создать заказ POST /api/v1/delivery/orders (ТЗ п.4)
  Future<DeliveryOrder> createOrderByPoints({
    required DeliveryAddressPoint pickup,
    required DeliveryAddressPoint dropoff,
    String? parcelDescription,
    double? parcelEstimatedValue,
  }) async {
    try {
      final body = <String, dynamic>{
        'pickup': pickup.toJson(),
        'dropoff': dropoff.toJson(),
      };
      if (parcelDescription != null && parcelDescription.isNotEmpty) {
        body['parcel_description'] = parcelDescription;
      }
      if (parcelEstimatedValue != null) {
        body['parcel_estimated_value'] = parcelEstimatedValue;
      }
      final response = await apiClient.post(
        '/api/v1/delivery/orders',
        body: body,
      );
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Не удалось создать заказ');
      }
      return DeliveryOrder.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.createOrderByPoints error: $e');
      }
      rethrow;
    }
  }

  /// Мои заказы GET /api/v1/delivery/orders (ТЗ)
  /// Ответ API: {"items": [...], "total": 1, "skip": 0, "limit": 50}
  Future<List<DeliveryOrder>> getMyOrders({
    int? skip,
    int? limit,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (status != null) queryParams['status'] = status;
      final response = await apiClient.get(
        '/api/v1/delivery/orders',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      // Парсим ответ: может быть объект с полем items или массив
      // Сначала пробуем как объект
      final responseData = apiClient.parseResponse(response);
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📦 DeliveryService.getMyOrders response:');
        print('Status: ${response.statusCode}');
        print('Response data type: ${responseData.runtimeType}');
        print('Response data: $responseData');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      if (responseData == null) {
        if (kDebugMode) {
          print('⚠️ Response data is null');
        }
        return [];
      }

      List<dynamic> items;
      // Проверяем, является ли ответ объектом с полем items
      if (responseData is Map && responseData.containsKey('items')) {
        // Новый формат: {"items": [...], "total": ..., "skip": ..., "limit": ...}
        final itemsData = (responseData as Map<String, dynamic>)['items'];
        if (itemsData is List) {
          items = itemsData;
          if (kDebugMode) {
            print('✅ Found ${items.length} orders in items array');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ items field is not a List: ${itemsData.runtimeType}');
          }
          return [];
        }
      } else {
        // Если нет поля items, пробуем как массив через parseListResponse
        final listData = apiClient.parseListResponse(response);
        if (listData != null) {
          items = listData;
          if (kDebugMode) {
            print('✅ Found ${items.length} orders in direct array');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ Could not parse as list');
          }
          return [];
        }
      }

      final orders = items.map((json) {
        try {
          return DeliveryOrder.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error parsing order: $e');
            print('Order JSON: $json');
          }
          rethrow;
        }
      }).toList();

      if (kDebugMode) {
        print('✅ Successfully parsed ${orders.length} orders');
      }

      return orders;
    } catch (e) {
      if (kDebugMode) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ DeliveryService.getMyOrders error: $e');
        print('Error type: ${e.runtimeType}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
      rethrow;
    }
  }

  /// Заказ по ID GET /api/v1/delivery/orders/{id} (ТЗ)
  Future<DeliveryOrder> getOrderById(int orderId) async {
    try {
      final response = await apiClient.get('/api/v1/delivery/orders/$orderId');
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Заказ не найден');
      }
      return DeliveryOrder.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getOrderById error: $e');
      }
      rethrow;
    }
  }

  /// Отмена заказа POST /api/v1/delivery/orders/{id}/cancel (ТЗ п.8)
  Future<DeliveryOrder> cancelOrder(int orderId, {String? reason}) async {
    try {
      final body = <String, dynamic>{};
      if (reason != null && reason.isNotEmpty) {
        body['reason'] = reason;
      }

      final response = await apiClient.post(
        '/api/v1/delivery/orders/$orderId/cancel',
        body: body.isNotEmpty ? body : null,
      );
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Не удалось отменить заказ');
      }
      return DeliveryOrder.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.cancelOrder error: $e');
      }
      rethrow;
    }
  }

  /// Баланс GET /api/v1/delivery/balance (ТЗ п.5)
  Future<DeliveryBalanceResponse> getDeliveryBalance() async {
    try {
      final response = await apiClient.get('/api/v1/delivery/balance');
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Не удалось получить баланс');
      }
      return DeliveryBalanceResponse.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getDeliveryBalance error: $e');
      }
      rethrow;
    }
  }

  /// История баланса GET /api/v1/delivery/balance/log
  Future<List<DeliveryBalanceLogEntry>> getDeliveryBalanceLog({
    int? skip,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (skip != null) queryParams['skip'] = skip.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      final response = await apiClient.get(
        '/api/v1/delivery/balance/log',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = apiClient.parseListResponse(response);
      if (data == null) return [];
      return data
          .map(
            (json) =>
                DeliveryBalanceLogEntry.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getDeliveryBalanceLog error: $e');
      }
      rethrow;
    }
  }

  /// Заказы водителя GET /api/v1/delivery/driver/orders (ТЗ)
  Future<List<DeliveryOrder>> getDriverOrdersTZ({String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      final response = await apiClient.get(
        '/api/v1/delivery/driver/orders',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      final data = apiClient.parseListResponse(response);
      if (data == null) return [];
      return data
          .map((json) => DeliveryOrder.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getDriverOrdersTZ error: $e');
      }
      rethrow;
    }
  }

  /// Заказ водителя по ID GET /api/v1/delivery/driver/orders/{id}
  Future<DeliveryOrder> getDriverOrderById(int orderId) async {
    try {
      final response = await apiClient.get(
        '/api/v1/delivery/driver/orders/$orderId',
      );
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Заказ не найден');
      }
      return DeliveryOrder.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.getDriverOrderById error: $e');
      }
      rethrow;
    }
  }

  /// Принять заказ POST /api/v1/delivery/driver/orders/{id}/accept (ТЗ п.6.3)
  Future<DeliveryOrder> acceptDriverOrder(int orderId) async {
    try {
      final response = await apiClient.post(
        '/api/v1/delivery/driver/orders/$orderId/accept',
      );
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Не удалось принять заказ');
      }
      return DeliveryOrder.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.acceptDriverOrder error: $e');
      }
      rethrow;
    }
  }

  /// Отклонить заказ POST /api/v1/delivery/driver/orders/{id}/reject (ТЗ п.6.3)
  Future<void> rejectDriverOrder(int orderId) async {
    try {
      await apiClient.post('/api/v1/delivery/driver/orders/$orderId/reject');
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.rejectDriverOrder error: $e');
      }
      rethrow;
    }
  }

  /// Смена статуса PATCH /api/v1/delivery/driver/orders/{id}/status (ТЗ п.7)
  Future<DeliveryOrder> updateDriverOrderStatus(
    int orderId,
    String status,
  ) async {
    try {
      final response = await apiClient.patch(
        '/api/v1/delivery/driver/orders/$orderId/status',
        body: jsonEncode({'status': status}),
      );
      final data = apiClient.parseResponse(response);
      if (data == null) {
        throw Exception('Не удалось обновить статус');
      }
      return DeliveryOrder.fromJson(data);
    } catch (e) {
      if (kDebugMode) {
        print('DeliveryService.updateDriverOrderStatus error: $e');
      }
      rethrow;
    }
  }
}
