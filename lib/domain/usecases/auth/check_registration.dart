import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../../repositories/auth_repository.dart';

/// Use case для проверки регистрации пользователя
class CheckRegistration implements UseCase<bool, CheckRegistrationParams> {
  final AuthRepository repository;

  CheckRegistration(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckRegistrationParams params) async {
    return await repository.checkRegistration(params.phone);
  }
}

class CheckRegistrationParams {
  final String phone;

  CheckRegistrationParams({required this.phone});
}










