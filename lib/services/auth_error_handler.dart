import 'package:flutter/foundation.dart';
import 'token_storage.dart';
import '../repositories/auth_repository.dart';
import '../di/injection_container.dart' as di;
import '../screens/auth/phone_auth_screen.dart';
import '../main.dart' show navigatorKey;

/// Сервис для обработки ошибок авторизации
class AuthErrorHandler {
  static bool _isHandling = false;

  /// Обработка ошибки 401 Unauthorized
  static Future<void> handleUnauthorized() async {
    // Предотвращаем множественные вызовы
    if (_isHandling) {
      if (kDebugMode) {
        print('⚠️ Already handling unauthorized error');
      }
      return;
    }

    _isHandling = true;

    try {
      if (kDebugMode) {
        print('🔒 Handling 401 Unauthorized - clearing token and logging out');
      }

      // Получаем зависимости
      final tokenStorage = di.getIt<TokenStorage>();
      final authRepository = di.getIt<AuthRepository>();

      // Удаляем токен локально
      await tokenStorage.clearToken();

      if (kDebugMode) {
        print('✅ Token cleared from local storage');
      }

      // Вызываем logout на сервере (игнорируем ошибки)
      try {
        await authRepository.logout();
        if (kDebugMode) {
          print('✅ Logout called on server');
        }
      } catch (e) {
        // Игнорируем ошибки logout, так как токен уже удален
        if (kDebugMode) {
          print('⚠️ Logout error (ignored): $e');
        }
      }

      if (kDebugMode) {
        print('✅ Unauthorized error handled successfully');
      }

      // Перенаправляем на экран авторизации
      final navigator = navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamedAndRemoveUntil(
          PhoneAuthScreen.routeName,
          (route) => false,
        );
        if (kDebugMode) {
          print('✅ Navigated to login screen');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Navigator not available');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling unauthorized: $e');
      }
    } finally {
      _isHandling = false;
    }
  }
}

