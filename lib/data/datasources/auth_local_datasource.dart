import '../../../core/errors/failures.dart';
import '../../../domain/entities/user.dart';
import '../../services/token_storage.dart';

/// Интерфейс локального источника данных для авторизации
abstract class AuthLocalDataSource {
  Future<User?> getCurrentUser();
  Future<void> saveUser(User user);
  Future<void> clearUser();
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
}

/// Реализация локального источника данных для авторизации
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final TokenStorage tokenStorage;
  User? _cachedUser;

  AuthLocalDataSourceImpl({required this.tokenStorage});

  @override
  Future<User?> getCurrentUser() async {
    try {
      if (_cachedUser != null) {
        return _cachedUser;
      }
      // Можно добавить сохранение в SharedPreferences
      return null;
    } catch (e) {
      throw CacheFailure('Ошибка при получении пользователя: ${e.toString()}');
    }
  }

  @override
  Future<void> saveUser(User user) async {
    try {
      _cachedUser = user;
      // Можно добавить сохранение в SharedPreferences
    } catch (e) {
      throw CacheFailure('Ошибка при сохранении пользователя: ${e.toString()}');
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      _cachedUser = null;
      // Можно добавить очистку SharedPreferences
    } catch (e) {
      throw CacheFailure('Ошибка при очистке пользователя: ${e.toString()}');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await tokenStorage.getAccessToken();
    } catch (e) {
      throw CacheFailure('Ошибка при получении токена: ${e.toString()}');
    }
  }

  @override
  Future<void> saveToken(String token) async {
    try {
      // TokenStorage требует tokenType, используем 'bearer' по умолчанию
      await tokenStorage.saveToken(token, 'bearer');
    } catch (e) {
      throw CacheFailure('Ошибка при сохранении токена: ${e.toString()}');
    }
  }

  @override
  Future<void> clearToken() async {
    try {
      await tokenStorage.clearToken();
    } catch (e) {
      throw CacheFailure('Ошибка при очистке токена: ${e.toString()}');
    }
  }
}

