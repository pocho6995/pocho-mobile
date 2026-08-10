import '../../../core/errors/failures.dart';
import '../../../core/utils/either.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Реализация репозитория авторизации (data слой)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, bool>> checkRegistration(String phone) async {
    try {
      final result = await remoteDataSource.checkRegistration(phone);
      return Right(result);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> sendCode(String phone) async {
    try {
      await remoteDataSource.sendCode(phone);
      return const Right(null);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> login(String phone, String code) async {
    try {
      final user = await remoteDataSource.login(phone, code);
      if (user.accessToken != null) {
        await localDataSource.saveToken(user.accessToken!);
      }
      await localDataSource.saveUser(user);
      return Right(user);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User>> register(
    String phone,
    String code,
    String name,
  ) async {
    try {
      final user = await remoteDataSource.register(phone, code, name);
      if (user.accessToken != null) {
        await localDataSource.saveToken(user.accessToken!);
      }
      await localDataSource.saveUser(user);
      return Right(user);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearUser();
      await localDataSource.clearToken();
      return const Right(null);
    } on ServerFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getCurrentUser();
      return Right(user);
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveToken(String token) async {
    try {
      await localDataSource.saveToken(token);
      return const Right(null);
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String?>> getToken() async {
    try {
      final token = await localDataSource.getToken();
      return Right(token);
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnknownFailure('Неизвестная ошибка: ${e.toString()}'));
    }
  }
}










