import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:client/domain/entities/cart_item_entity.dart';
import 'package:client/domain/repositories/cart_repository.dart';

@injectable
class GetCartItemsUseCase {
  final CartRepository _repository;

  GetCartItemsUseCase(this._repository);

  Future<Either<String, List<CartItemEntity>>> call() {
    return _repository.getCartItems();
  }
}

@injectable
class AddToCartUseCase {
  final CartRepository _repository;

  AddToCartUseCase(this._repository);

  Future<Either<String, CartItemEntity>> call(CartItemEntity item) {
    return _repository.addToCart(item);
  }
}

@injectable
class UpdateCartItemUseCase {
  final CartRepository _repository;

  UpdateCartItemUseCase(this._repository);

  Future<Either<String, CartItemEntity>> call(CartItemEntity item) {
    return _repository.updateCartItem(item);
  }
}

@injectable
class RemoveFromCartUseCase {
  final CartRepository _repository;

  RemoveFromCartUseCase(this._repository);

  Future<Either<String, void>> call(int productId) {
    return _repository.removeFromCart(productId);
  }
}

@injectable
class SyncCartUseCase {
  final CartRepository _repository;

  SyncCartUseCase(this._repository);

  Future<Either<String, void>> call() {
    return _repository.syncCartWithServer();
  }
}