// user_management_repository.dart
import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/user_entity.dart';

abstract class UserManagementRepository {
  Future<Either<String, List<UserEntity>>> getUsers();
  Future<Either<String, UserEntity>> blockUser(int userId);
  Future<Either<String, UserEntity>> unblockUser(int userId);
  Future<Either<String, UserEntity>> changeUserRole(int userId, String newRole);
}