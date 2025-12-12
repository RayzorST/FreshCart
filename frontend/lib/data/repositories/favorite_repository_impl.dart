import 'package:client/domain/entities/favorite_item_entity.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:client/data/datasources/local/app_database.dart';
import 'package:client/domain/repositories/favorite_repository.dart';
import 'package:client/domain/repositories/product_repository.dart';

@LazySingleton(as: FavoriteRepository)
class FavoriteRepositoryImpl implements FavoriteRepository {
  final AppDatabase _database;
  final ProductRepository _productRepository;

  FavoriteRepositoryImpl(this._database, this._productRepository);

  @override
  Future<Either<String, List<FavoriteItemEntity>>> getFavorites() async {
    try {
      final results = await _database.getFavoritesWithProducts();
      
      final favorites = await Future.wait(results.map((result) async {
        final favoriteItem = result.$1;
        final dbProduct = result.$2;
        
        final product = ProductEntity(
          id: dbProduct.id,
          name: dbProduct.name,
          description: dbProduct.description,
          price: dbProduct.price,
          stockQuantity: dbProduct.stockQuantity,
          category: dbProduct.category,
          isActive: dbProduct.isActive,
          createdAt: dbProduct.createdAt,
          updatedAt: dbProduct.updatedAt,
        );
        
        return FavoriteItemEntity(
          id: favoriteItem.id,
          product: product,
          addedAt: favoriteItem.addedAt,
        );
      }));
      
      return Right(favorites);
    } catch (e) {
      return Left('Ошибка загрузки избранного: $e');
    }
  }

  @override
  Future<Either<String, FavoriteItemEntity>> addToFavorites(FavoriteItemEntity item) async {
    try {
      final id = await _database.insertFavoriteItem(FavoriteItemsCompanion(
        productId: Value(item.product.id),
        addedAt: Value(DateTime.now()),
      ));
      
      return Right(item.copyWith(id: id));
    } catch (e) {
      return Left('Ошибка добавления в избранное: $e');
    }
  }

  @override
  Future<Either<String, void>> removeFromFavorites(int productId) async {
    try {
      await _database.removeFavoriteItem(productId);
      return const Right(null);
    } catch (e) {
      return Left('Ошибка удаления из избранного: $e');
    }
  }

  @override
  Future<Either<String, void>> clearFavorites() async {
    try {
      await _database.clearFavorites();
      return const Right(null);
    } catch (e) {
      return Left('Ошибка очистки избранного: $e');
    }
  }

  @override
  Future<bool> isFavorite(int productId) async {
    return await _database.isProductFavorite(productId);
  }
}