import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/favorite_item_entity.dart';
import 'package:client/domain/repositories/favorite_repository.dart';

@LazySingleton(as: FavoriteRepository)
class FavoriteRepositoryImpl implements FavoriteRepository {
  @override
  Future<Either<String, List<FavoriteItemEntity>>> getFavorites({String? search}) async {
    try {
      final response = await ApiClient.getFavorites(search: search);
      final favorites = (response)
          .map((json) => FavoriteItemEntity.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return Right(favorites);
    } catch (e) {
      return Left('Ошибка загрузки избранного: $e');
    }
  }

  @override
  Future<Either<String, FavoriteItemEntity>> addToFavorites(int productId) async {
    try {
      final response = await ApiClient.addToFavorites(productId);
      return Right(FavoriteItemEntity.fromJson(response));
    } catch (e) {
      return Left('Ошибка добавления в избранное: $e');
    }
  }

  @override
  Future<Either<String, void>> removeFromFavorites(int productId) async {
    try {
      await ApiClient.removeFromFavorites(productId);
      return const Right(null);
    } catch (e) {
      return Left('Ошибка удаления из избранного: $e');
    }
  }

  @override
  Future<Either<String, bool>> isFavorite(int productId) async {
    try {
      final response = await ApiClient.checkFavorite(productId);
      return Right(response['is_favorite'] as bool);
    } catch (e) {
      return Left('Ошибка проверки избранного: $e');
    }
  }
}