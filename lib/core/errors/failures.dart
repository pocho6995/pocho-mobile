import 'package:equatable/equatable.dart';

/// Базовый класс для всех ошибок в приложении
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Ошибка сервера
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Ошибка сети
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Ошибка авторизации
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Ошибка валидации
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Ошибка кэша
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Неизвестная ошибка
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}










