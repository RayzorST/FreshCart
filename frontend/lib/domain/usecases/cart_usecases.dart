import 'package:client/domain/entities/cart_item_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
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
class ClearCartUseCase {
  final CartRepository _repository;

  ClearCartUseCase(this._repository);

  Future<Either<String, void>> call() {
    return _repository.clearCart();
  }
}

@injectable
class GetTotalAmountUseCase {
  final CartRepository _repository;

  GetTotalAmountUseCase(this._repository);

  Future<Either<String, double>> call() {
    return _repository.getTotalAmount();
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

@injectable
class IsInCartUseCase {
  final CartRepository _repository;

  IsInCartUseCase(this._repository);

  Future<bool> call(int productId) {
    return _repository.isInCart(productId);
  }
}

@injectable
class GetCartItemCountUseCase {
  final CartRepository _repository;

  GetCartItemCountUseCase(this._repository);

  Future<int> call() {
    return _repository.getCartItemCount();
  }
}