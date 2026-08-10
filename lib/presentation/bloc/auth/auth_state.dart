import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

/// Базовый класс для состояний авторизации
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Начальное состояние
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Состояние загрузки
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Состояние успешной авторизации
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

/// Состояние неавторизованного пользователя
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Состояние ошибки
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

/// Состояние проверки регистрации
class RegistrationChecked extends AuthState {
  final bool isRegistered;

  const RegistrationChecked(this.isRegistered);

  @override
  List<Object> get props => [isRegistered];
}

/// Состояние отправки кода
class CodeSent extends AuthState {
  const CodeSent();
}










