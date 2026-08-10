import '../../core/errors/failures.dart';
import '../../core/utils/either.dart';
import '../entities/user.dart';

/// Интерфейс репозитория авторизации (domain слой)
abstract class AuthRepository {
  /// Проверка регистрации пользователя
  Future<Either<Failure, bool>> checkRegistration(String phone);

  /// Отправка кода подтверждения
  Future<Either<Failure, void>> sendCode(String phone);

  /// Вход для зарегистрированного пользователя
  Future<Either<Failure, User>> login(String phone, String code);

  /// Регистрация нового пользователя
  Future<Either<Failure, User>> register(String phone, String code, String name);

  /// Выход из системы
  Future<Either<Failure, void>> logout();

  /// Получение текущего пользователя
  Future<Either<Failure, User?>> getCurrentUser();

  /// Сохранение токена
  Future<Either<Failure, void>> saveToken(String token);

  /// Получение токена
  Future<Either<Failure, String?>> getToken();
}










