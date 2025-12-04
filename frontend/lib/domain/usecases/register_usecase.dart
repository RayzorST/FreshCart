import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:client/domain/entities/user_entity.dart';
import 'package:client/domain/repositories/auth_repository.dart';

@injectable
class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<Either<String, UserEntity>> call({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) {
    return _repository.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
  }
}