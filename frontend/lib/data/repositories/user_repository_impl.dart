import 'package:dartz/dartz.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/user_entity.dart';
import 'package:client/domain/repositories/user_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  @override
  Future<Either<String, UserEntity>> getProfile() async {
    try {
      final response = await ApiClient.getProfile();
      final user = UserEntity.fromJson(response);
      return Right(user);
    } catch (e) {
      return Left('Ошибка загрузки профиля: $e');
    }
  }

  @override
  Future<Either<String, UserEntity>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await ApiClient.updateProfile(profileData);
      final user = UserEntity.fromJson(response);
      return Right(user);
    } catch (e) {
      return Left('Ошибка обновления профиля: $e');
    }
  }

  @override
  Future<Either<String, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await ApiClient.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } catch (e) {
      return Left('Ошибка изменения пароля: $e');
    }
  }

  @override
  Future<Either<String, void>> logout() async {
    try {
      // API клиент сам должен обработать logout
      // Например, очистить токены и т.д.
      return const Right(null);
    } catch (e) {
      return Left('Ошибка выхода: $e');
    }
  }
}