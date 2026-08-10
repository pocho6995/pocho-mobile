import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

/// Use case для входа пользователя
class Login implements UseCase<User, LoginParams> {
  final AuthRepository repository;

  Login(this.repository);

  @override
  Future<Either<Failure, User>> call(LoginParams params) async {
    return await repository.login(params.phone, params.code);
  }
}

class LoginParams {
  final String phone;
  final String code;

  LoginParams({required this.phone, required this.code});
}










