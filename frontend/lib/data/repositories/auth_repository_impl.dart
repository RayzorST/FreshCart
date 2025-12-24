import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/user_entity.dart';
import 'package:client/domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  @override
  Future<Either<String, UserEntity>> login(String email, String password) async {
    try {
      final response = await ApiClient.login(email, password);
      final token = response['access_token'] as String;

      await saveToken(token);

      final profile = await ApiClient.getProfile();

      final user = UserEntity(
        id: profile['id'] as int,
        email: profile['email'] as String,
        firstName: profile['first_name'] as String?,
        lastName: profile['last_name'] as String?,
        avatarUrl: profile['avatar_url'] as String?,
      );

      await _saveUserData(user);
      
      return Right(user);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, UserEntity>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await ApiClient.registration(
        email,
        password,
        firstName,
        lastName,
      );
      final token = response['access_token'] as String;

      await saveToken(token);

      final user = UserEntity(
        id: 0,
        email: email,
        firstName: firstName,
        lastName: lastName,
      );

      await _saveUserData(user);
      
      return Right(user);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    ApiClient.setToken(token);
  }

  @override
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  @override
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    ApiClient.clearToken();
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveUserData(UserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = {
      'email': user.email,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'avatarUrl': user.avatarUrl,
    };
    await prefs.setString(_userKey, json.encode(userJson));
  }

  Future<UserEntity?> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJsonString = prefs.getString(_userKey);
    if (userJsonString != null) {
      final userJson = json.decode(userJsonString) as Map<String, dynamic>;
      return UserEntity(
        id: 0,
        email: userJson['email'] as String,
        firstName: userJson['firstName'] as String?,
        lastName: userJson['lastName'] as String?,
        avatarUrl: userJson['avatarUrl'] as String?,
      );
    }
    return null;
  }

  @override
  Future<Either<String, UserEntity>> getCurrentUser() async {
    try {
      final token = await getToken();
      if (token == null || token.isEmpty) {
        return Left('Токен не найден');
      }

      ApiClient.setToken(token);

      final profile = await ApiClient.getProfile();

      final user = UserEntity(
        id: 0,
        email: profile['email'] as String,
        firstName: profile['first_name'] as String?,
        lastName: profile['last_name'] as String?,
        avatarUrl: profile['avatar_url'] as String?,
      );
      await _saveUserData(user);
      
      return Right(user);
    } catch (e) {
      final cachedUser = await _getUserData();
      if (cachedUser != null) {
        return Right(cachedUser);
      }
      return Left('Не удалось получить данные пользователя: $e');
    }
  }
}