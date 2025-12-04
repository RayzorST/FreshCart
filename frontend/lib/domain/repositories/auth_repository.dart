import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<String, UserEntity>> login(String email, String password);
  
  Future<Either<String, UserEntity>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });
  
  Future<Either<String, UserEntity>> getCurrentUser();
  
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
  Future<bool> isLoggedIn();
}