import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/favorite_item_entity.dart';

abstract class FavoriteRepository {
  Future<Either<String, List<FavoriteItemEntity>>> getFavorites();
  Future<Either<String, FavoriteItemEntity>> addToFavorites(FavoriteItemEntity item);
  Future<Either<String, void>> removeFromFavorites(int productId);
  Future<Either<String, void>> clearFavorites();
  Future<bool> isFavorite(int productId);
}