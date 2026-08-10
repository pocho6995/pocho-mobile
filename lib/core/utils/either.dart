/// Функциональный тип для обработки успеха или ошибки
abstract class Either<L, R> {
  const Either();

  /// Создает Left (ошибка)
  const factory Either.left(L value) = Left<L, R>;

  /// Создает Right (успех)
  const factory Either.right(R value) = Right<L, R>;

  /// Проверяет, является ли это Left
  bool get isLeft;

  /// Проверяет, является ли это Right
  bool get isRight;

  /// Получает значение Left
  L? get left;

  /// Получает значение Right
  R? get right;

  /// Применяет функцию к значению
  Either<L, T> map<T>(T Function(R) f);

  /// Применяет функцию к Left
  Either<T, R> mapLeft<T>(T Function(L) f);

  /// Сворачивает Either в одно значение
  T fold<T>(T Function(L) onLeft, T Function(R) onRight);
}

class Left<L, R> extends Either<L, R> {
  final L value;

  const Left(this.value);

  @override
  bool get isLeft => true;

  @override
  bool get isRight => false;

  @override
  L? get left => value;

  @override
  R? get right => null;

  @override
  Either<L, T> map<T>(T Function(R) f) => Left<L, T>(value);

  @override
  Either<T, R> mapLeft<T>(T Function(L) f) => Left<T, R>(f(value));

  @override
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) => onLeft(value);
}

class Right<L, R> extends Either<L, R> {
  final R value;

  const Right(this.value);

  @override
  bool get isLeft => false;

  @override
  bool get isRight => true;

  @override
  L? get left => null;

  @override
  R? get right => value;

  @override
  Either<L, T> map<T>(T Function(R) f) => Right<L, T>(f(value));

  @override
  Either<T, R> mapLeft<T>(T Function(L) f) => Right<T, R>(value);

  @override
  T fold<T>(T Function(L) onLeft, T Function(R) onRight) => onRight(value);
}









