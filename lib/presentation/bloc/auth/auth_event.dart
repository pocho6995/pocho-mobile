import 'package:equatable/equatable.dart';

/// Базовый класс для событий авторизации
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

/// Событие проверки регистрации
class CheckRegistrationEvent extends AuthEvent {
  final String phone;

  const CheckRegistrationEvent(this.phone);

  @override
  List<Object> get props => [phone];
}

/// Событие отправки кода
class SendCodeEvent extends AuthEvent {
  final String phone;

  const SendCodeEvent(this.phone);

  @override
  List<Object> get props => [phone];
}

/// Событие входа
class LoginEvent extends AuthEvent {
  final String phone;
  final String code;

  const LoginEvent({required this.phone, required this.code});

  @override
  List<Object> get props => [phone, code];
}

/// Событие регистрации
class RegisterEvent extends AuthEvent {
  final String phone;
  final String code;
  final String name;

  const RegisterEvent({
    required this.phone,
    required this.code,
    required this.name,
  });

  @override
  List<Object> get props => [phone, code, name];
}

/// Событие выхода
class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

/// Событие загрузки текущего пользователя
class LoadCurrentUserEvent extends AuthEvent {
  const LoadCurrentUserEvent();
}










