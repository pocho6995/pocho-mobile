import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/usecases/auth/check_registration.dart';
import '../../../domain/usecases/auth/login.dart';
import '../../../domain/usecases/auth/send_code.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC для управления состоянием авторизации
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CheckRegistration checkRegistration;
  final SendCode sendCode;
  final Login login;

  AuthBloc({
    required this.checkRegistration,
    required this.sendCode,
    required this.login,
  }) : super(const AuthInitial()) {
    on<CheckRegistrationEvent>(_onCheckRegistration);
    on<SendCodeEvent>(_onSendCode);
    on<LoginEvent>(_onLogin);
  }

  Future<void> _onCheckRegistration(
    CheckRegistrationEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await checkRegistration(
      CheckRegistrationParams(phone: event.phone),
    );

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (isRegistered) => emit(RegistrationChecked(isRegistered)),
    );
  }

  Future<void> _onSendCode(
    SendCodeEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await sendCode(SendCodeParams(phone: event.phone));

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (_) => emit(const CodeSent()),
    );
  }

  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await login(
      LoginParams(phone: event.phone, code: event.code),
    );

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return failure.message;
      case NetworkFailure:
        return 'Ошибка сети. Проверьте подключение к интернету.';
      case AuthFailure:
        return failure.message;
      case ValidationFailure:
        return failure.message;
      default:
        return 'Произошла ошибка. Попробуйте еще раз.';
    }
  }
}










