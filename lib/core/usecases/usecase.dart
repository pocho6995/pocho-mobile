import 'dart:async';
import '../errors/failures.dart';
import '../utils/either.dart';

/// Базовый интерфейс для всех use cases
/// Возвращает Either<Failure, Type> для обработки ошибок
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Параметры для use case без параметров
class NoParams {
  const NoParams();
}
