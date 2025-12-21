import 'package:dartz/dartz.dart';
import 'package:client/domain/entities/cart_item_entity.dart';

abstract class CartRepository {
  Future<Either<String, List<CartItemEntity>>> getCartItems();
  Future<Either<String, CartItemEntity>> addToCart(int productId, int quantity);
  Future<Either<String, CartItemEntity>> updateCartItem(int productId, int quantity);
  Future<Either<String, void>> removeFromCart(int productId);
  Future<Either<String, void>> clearCart();
}