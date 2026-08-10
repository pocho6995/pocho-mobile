import '../../../core/errors/failures.dart';
import '../../../domain/entities/user.dart';
import '../../models/auth/check_registration_request.dart';
import '../../models/auth/login_request.dart';
import '../../models/auth/login_response.dart';
import '../../models/auth/send_code_request.dart';
import '../../models/auth/verify_code_request.dart';
import '../../models/auth/verify_code_response.dart';
import '../../services/auth_service.dart';

/// Интерфейс удаленного источника данных для авторизации
abstract class AuthRemoteDataSource {
  Future<bool> checkRegistration(String phone);
  Future<void> sendCode(String phone);
  Future<User> login(String phone, String code);
  Future<User> register(String phone, String code, String name);
  Future<void> logout();
}

/// Реализация удаленного источника данных для авторизации
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final AuthService authService;

  AuthRemoteDataSourceImpl({required this.authService});

  @override
  Future<bool> checkRegistration(String phone) async {
    try {
      final request = CheckRegistrationRequest(phone: phone);
      final response = await authService.checkRegistration(request);
      return response.isRegistered;
    } catch (e) {
      throw ServerFailure('Ошибка при проверке регистрации: ${e.toString()}');
    }
  }

  @override
  Future<void> sendCode(String phone) async {
    try {
      final request = SendCodeRequest(phone: phone);
      await authService.sendCode(request);
    } catch (e) {
      throw ServerFailure('Ошибка при отправке кода: ${e.toString()}');
    }
  }

  @override
  Future<User> login(String phone, String code) async {
    try {
      final request = LoginRequest(phone: phone, code: code);
      final response = await authService.login(request);
      return _mapLoginResponseToUser(response);
    } catch (e) {
      throw ServerFailure('Ошибка при входе: ${e.toString()}');
    }
  }

  @override
  Future<User> register(String phone, String code, String name) async {
    try {
      // VerifyCodeRequest не поддерживает name, передаем только phone и code
      final request = VerifyCodeRequest(phone: phone, code: code);
      final response = await authService.verifyCode(request);
      return _mapVerifyResponseToUser(response, name: name);
    } catch (e) {
      throw ServerFailure('Ошибка при регистрации: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await authService.logout();
    } catch (e) {
      throw ServerFailure('Ошибка при выходе: ${e.toString()}');
    }
  }

  /// Маппинг LoginResponse в User entity
  /// Примечание: LoginResponse не содержит данные пользователя,
  /// поэтому создаем временного пользователя с токеном
  User _mapLoginResponseToUser(LoginResponse response) {
    // TODO: Получить данные пользователя из токена или через ProfileService
    return User(
      id: 0, // Будет обновлено после получения профиля
      phone: '', // Будет обновлено после получения профиля
      accessToken: response.accessToken,
    );
  }

  /// Маппинг VerifyCodeResponse в User entity
  /// Примечание: VerifyCodeResponse не содержит данные пользователя,
  /// поэтому создаем временного пользователя с токеном
  User _mapVerifyResponseToUser(VerifyCodeResponse response, {String? name}) {
    // TODO: Получить данные пользователя из токена или через ProfileService
    return User(
      id: 0, // Будет обновлено после получения профиля
      phone: '', // Будет обновлено после получения профиля
      name: name,
      accessToken: response.accessToken,
    );
  }
}

