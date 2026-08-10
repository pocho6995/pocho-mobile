import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/utils/either.dart';
import '../../repositories/auth_repository.dart';

/// Use case для отправки кода подтверждения
class SendCode implements UseCase<void, SendCodeParams> {
  final AuthRepository repository;

  SendCode(this.repository);

  @override
  Future<Either<Failure, void>> call(SendCodeParams params) async {
    return await repository.sendCode(params.phone);
  }
}

class SendCodeParams {
  final String phone;

  SendCodeParams({required this.phone});
}










