// user_management_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/user_entity.dart';
import 'package:client/domain/repositories/user_management_repository.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  @override
  Future<Either<String, List<UserEntity>>> getUsers() async {
    try {
      final response = await ApiClient.getAdminUsers();
      
      final users = (response as List)
          .map((json) => UserEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return Right(users);
    } catch (e) {
      return Left('Ошибка загрузки пользователей: $e');
    }
  }

  @override
  Future<Either<String, UserEntity>> blockUser(int userId) async {
    try {
      final response = await ApiClient.blockUser(userId);
      final user = UserEntity.fromJson(response as Map<String, dynamic>);
      return Right(user);
    } catch (e) {
      return Left('Ошибка при блокировке пользователя: $e');
    }
  }

  @override
  Future<Either<String, UserEntity>> unblockUser(int userId) async {
    try {
      final response = await ApiClient.unblockUser(userId);
      final user = UserEntity.fromJson(response as Map<String, dynamic>);
      return Right(user);
    } catch (e) {
      return Left('Ошибка при разблокировке пользователя: $e');
    }
  }

  @override
  Future<Either<String, UserEntity>> changeUserRole(int userId, String newRole) async {
    try {
      final response = await ApiClient.setUserRole(userId, newRole);
      final user = UserEntity.fromJson(response as Map<String, dynamic>);
      return Right(user);
    } catch (e) {
      return Left('Ошибка при смене роли пользователя: $e');
    }
  }
}