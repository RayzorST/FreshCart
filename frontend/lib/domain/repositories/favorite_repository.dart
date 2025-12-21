import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/favorite_item_entity.dart';

abstract class FavoriteRepository {
  Future<Either<String, List<FavoriteItemEntity>>> getFavorites({String? search});
  Future<Either<String, FavoriteItemEntity>> addToFavorites(int productId);
  Future<Either<String, void>> removeFromFavorites(int productId);
  Future<Either<String, bool>> isFavorite(int productId);
}