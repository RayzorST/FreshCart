import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:client/domain/entities/user_entity.dart';
import 'package:client/domain/repositories/auth_repository.dart';

@injectable
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<Either<String, UserEntity>> call(String email, String password) {
    return _repository.login(email, password);
  }
}