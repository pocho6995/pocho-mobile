import '../exceptions/auth_exceptions.dart';
import '../models/auth/check_registration_request.dart';
import '../models/auth/send_code_request.dart';
import '../models/auth/verify_code_request.dart';
import '../models/auth/verify_code_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/login_response.dart';
import '../services/auth_service.dart';

/// Репозиторий для работы с авторизацией
/// Инкапсулирует бизнес-логику и обработку ошибок
class AuthRepository {
  final AuthService authService;

  AuthRepository({required this.authService});

  /// Проверка регистрации пользователя
  /// Возвращает true, если пользователь зарегистрирован
  Future<bool> checkRegistration(String phone) async {
    try {
      final request = CheckRegistrationRequest(phone: phone);
      final response = await authService.checkRegistration(request);
      return response.isRegistered;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw UnknownException(
        'Ошибка при проверке регистрации: ${e.toString()}',
      );
    }
  }

  /// Отправка кода подтверждения
  Future<void> sendCode(String phone) async {
    try {
      final request = SendCodeRequest(phone: phone);
      await authService.sendCode(request);
      // Если запрос успешен (200), код отправлен
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw UnknownException('Ошибка при отправке кода: ${e.toString()}');
    }
  }

  /// Вход для зарегистрированного пользователя
  Future<LoginResponse> login(String phone, String code) async {
    // Проверка входных данных
    if (phone.isEmpty || phone.trim().isEmpty) {
      throw ValidationException('Номер телефона не может быть пустым');
    }
    if (code.isEmpty || code.trim().isEmpty) {
      throw ValidationException('Код не может быть пустым');
    }
    
    try {
      final request = LoginRequest(phone: phone.trim(), code: code.trim());
      return await authService.login(request);
    } on AuthException {
      rethrow;
    } on FormatException catch (e) {
      throw UnknownException('Ошибка формата ответа при входе: ${e.message}');
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw UnknownException('Ошибка при входе: ${e.toString()}');
    }
  }

  /// Верификация кода для регистрации нового пользователя
  Future<VerifyCodeResponse> verifyCode(String phone, String code) async {
    // Проверка входных данных
    if (phone.isEmpty || phone.trim().isEmpty) {
      throw ValidationException('Номер телефона не может быть пустым');
    }
    if (code.isEmpty || code.trim().isEmpty) {
      throw ValidationException('Код не может быть пустым');
    }
    
    try {
      final request = VerifyCodeRequest(phone: phone.trim(), code: code.trim());
      return await authService.verifyCode(request);
    } on AuthException {
      rethrow;
    } on FormatException catch (e) {
      throw UnknownException('Ошибка формата ответа при верификации: ${e.message}');
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw UnknownException('Ошибка при верификации кода: ${e.toString()}');
    }
  }

  /// Выход из системы
  Future<void> logout() async {
    try {
      await authService.logout();
    } on AuthException {
      // Игнорируем ошибки при logout, так как токен все равно будет удален локально
      rethrow;
    } catch (e) {
      // Игнорируем ошибки при logout
    }
  }
}
