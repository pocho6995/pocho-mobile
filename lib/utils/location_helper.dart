import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

/// Утилита для работы с геолокацией
class LocationHelper {
  /// Проверка и запрос разрешений на геолокацию
  static Future<bool> checkAndRequestPermission() async {
    try {
      // Проверяем, включены ли службы геолокации
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (kDebugMode) {
        print('🔍 LocationHelper: Location service enabled: $serviceEnabled');
      }

      if (!serviceEnabled) {
        if (kDebugMode) {
          print('⚠️ LocationHelper: Location services are disabled');
        }
        return false;
      }

      // Проверяем текущий статус разрешения
      LocationPermission permission = await Geolocator.checkPermission();
      if (kDebugMode) {
        print('🔍 LocationHelper: Current permission status: $permission');
      }

      // Если разрешение отклонено, запрашиваем его
      if (permission == LocationPermission.denied) {
        if (kDebugMode) {
          print('📱 LocationHelper: Requesting location permission...');
        }
        permission = await Geolocator.requestPermission();
        if (kDebugMode) {
          print('🔍 LocationHelper: Permission after request: $permission');
        }

        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            print('⚠️ LocationHelper: Location permissions are denied by user');
          }
          return false;
        }
      }

      // Проверяем, не отклонено ли разрешение навсегда
      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          print(
            '⚠️ LocationHelper: Location permissions are permanently denied',
          );
        }
        return false;
      }

      // Проверяем, что разрешение предоставлено
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        if (kDebugMode) {
          print('✅ LocationHelper: Location permission granted: $permission');
        }
        return true;
      }

      if (kDebugMode) {
        print('⚠️ LocationHelper: Unexpected permission status: $permission');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ LocationHelper: Error checking/requesting permission: $e');
      }
      return false;
    }
  }

  /// Получение текущего местоположения пользователя
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (kDebugMode) {
        print('📍 User location: ${position.latitude}, ${position.longitude}');
      }

      return position;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting location: $e');
      }
      return null;
    }
  }

  /// Вычисление расстояния между двумя точками в километрах
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Получение потока обновлений местоположения пользователя
  static Stream<Position>? getPositionStream({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    int distanceFilter = 10, // Минимальное расстояние в метрах для обновления
  }) {
    try {
      return Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: desiredAccuracy,
          distanceFilter: distanceFilter,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting position stream: $e');
      }
      return null;
    }
  }
}
