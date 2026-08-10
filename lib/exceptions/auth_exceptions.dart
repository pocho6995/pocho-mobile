/// Базовый класс для исключений авторизации
abstract class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  
  @override
  String toString() => message;
}

/// Ошибка сети (нет интернета, таймаут и т.д.)
class NetworkException extends AuthException {
  const NetworkException([super.message = 'Ошибка сети. Проверьте подключение к интернету']);
}

/// Ошибка сервера (5xx)
class ServerException extends AuthException {
  const ServerException([super.message = 'Ошибка сервера. Попробуйте позже']);
}

/// Ошибка валидации (400)
class ValidationException extends AuthException {
  const ValidationException([super.message = 'Неверные данные']);
}

/// Неавторизован (401)
class UnauthorizedException extends AuthException {
  const UnauthorizedException([super.message = 'Неверный код подтверждения']);
}

/// Не найдено (404)
class NotFoundException extends AuthException {
  const NotFoundException([super.message = 'Ресурс не найден']);
}

/// Неверный код подтверждения
class InvalidCodeException extends AuthException {
  const InvalidCodeException([super.message = 'Неверный код подтверждения']);
}

/// Пользователь уже зарегистрирован
class UserExistsException extends AuthException {
  const UserExistsException([super.message = 'Пользователь уже зарегистрирован']);
}

/// Неизвестная ошибка
class UnknownException extends AuthException {
  const UnknownException([super.message = 'Произошла неизвестная ошибка']);
}













