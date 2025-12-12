import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:client/domain/entities/favorite_item_entity.dart';
import 'package:client/domain/repositories/favorite_repository.dart';

@injectable
class GetFavoritesUseCase {
  final FavoriteRepository _repository;

  GetFavoritesUseCase(this._repository);

  Future<Either<String, List<FavoriteItemEntity>>> call() {
    return _repository.getFavorites();
  }
}

@injectable
class AddToFavoritesUseCase {
  final FavoriteRepository _repository;

  AddToFavoritesUseCase(this._repository);

  Future<Either<String, FavoriteItemEntity>> call(FavoriteItemEntity item) {
    return _repository.addToFavorites(item);
  }
}

@injectable
class RemoveFromFavoritesUseCase {
  final FavoriteRepository _repository;

  RemoveFromFavoritesUseCase(this._repository);

  Future<Either<String, void>> call(int productId) {
    return _repository.removeFromFavorites(productId);
  }
}

@injectable
class ClearFavoritesUseCase {
  final FavoriteRepository _repository;

  ClearFavoritesUseCase(this._repository);

  Future<Either<String, void>> call() {
    return _repository.clearFavorites();
  }
}

@injectable
class IsFavoriteUseCase {
  final FavoriteRepository _repository;

  IsFavoriteUseCase(this._repository);

  Future<bool> call(int productId) {
    return _repository.isFavorite(productId);
  }
}