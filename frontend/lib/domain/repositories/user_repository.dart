import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<Either<String, UserEntity>> getProfile();
  Future<Either<String, UserEntity>> updateProfile(Map<String, dynamic> profileData);
  Future<Either<String, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<Either<String, void>> logout();
}