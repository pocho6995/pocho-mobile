import 'package:flutter/material.dart';

import '../di/injection_container.dart' as di;
import '../services/token_storage.dart';
import '../repositories/auth_repository.dart';
import '../repositories/notification_repository.dart';
import '../utils/location_helper.dart';
import '../widgets/app_logo.dart';
import 'auth/phone_auth_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Небольшая задержка для показа splash screen
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Запрашиваем разрешение на использование геолокации сразу при входе
    try {
      await LocationHelper.checkAndRequestPermission();
    } catch (e) {
      // Игнорируем ошибки запроса разрешения - приложение должно работать и без геолокации
      if (mounted) {
        debugPrint('⚠️ Error requesting location permission: $e');
      }
    }

    try {
      final tokenStorage = di.getIt<TokenStorage>();
      final hasToken = await tokenStorage.hasToken();

      if (hasToken) {
        // Проверяем валидность токена
        final isValid = await tokenStorage.isTokenValid();

        if (isValid) {
          // Токен валиден - подключаемся к WebSocket и переходим на главный экран
          try {
            final notificationRepository = di.getIt<NotificationRepository>();
            await notificationRepository.connectWebSocket();
          } catch (e) {
            // Игнорируем ошибки подключения WebSocket
          }
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(MainShell.routeName);
          }
        } else {
          // Токен истек - вызываем logout и переходим на авторизацию
          try {
            final authRepository = di.getIt<AuthRepository>();
            await authRepository.logout();
          } catch (e) {
            // Игнорируем ошибки logout
          }
          // Удаляем токен локально
          await tokenStorage.clearToken();
          if (mounted) {
            Navigator.of(
              context,
            ).pushReplacementNamed(PhoneAuthScreen.routeName);
          }
        }
      } else {
        // Токена нет - переходим на авторизацию
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(PhoneAuthScreen.routeName);
        }
      }
    } catch (e) {
      // При любой ошибке переходим на авторизацию
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(PhoneAuthScreen.routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(width: 120, height: 120, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'PoCho',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
