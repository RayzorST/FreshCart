import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/cart_item_entity.dart';

abstract class CartRepository {
  Future<Either<String, List<CartItemEntity>>> getCartItems();
  Future<Either<String, CartItemEntity>> addToCart(CartItemEntity item);
  Future<Either<String, CartItemEntity>> updateCartItem(CartItemEntity item);
  Future<Either<String, void>> removeFromCart(int productId);
  Future<Either<String, void>> clearCart();
  Future<Either<String, double>> getTotalAmount();
  Future<Either<String, void>> syncCartWithServer();
  Future<bool> isInCart(int productId);
  Future<int> getCartItemCount();
}