import 'package:dartz/dartz.dart';
import 'package:client/api/client.dart';
import 'package:client/domain/entities/cart_item_entity.dart';
import 'package:client/domain/repositories/cart_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CartRepository)
class CartRepositoryImpl implements CartRepository {
  @override
  Future<Either<String, List<CartItemEntity>>> getCartItems() async {
    try {
      final response = await ApiClient.getCart();
      final items = response['items'] as List<dynamic>;
      final cartItems = items
          .map((item) => CartItemEntity.fromJson(item as Map<String, dynamic>))
          .toList();
      return Right(cartItems);
    } catch (e) {
      return Left('Ошибка загрузки корзины: $e');
    }
  }

  @override
  Future<Either<String, CartItemEntity>> addToCart(int productId, int quantity) async {
    try {
      final response = await ApiClient.addToCart(productId, quantity);
      return Right(CartItemEntity.fromJson(response));
    } catch (e) {
      return Left('Ошибка добавления в корзину: $e');
    }
  }

  @override
  Future<Either<String, CartItemEntity>> updateCartItem(int productId, int quantity) async {
    try {
      final response = await ApiClient.updateCartItem(productId, quantity);
      return Right(CartItemEntity.fromJson(response));
    } catch (e) {
      return Left('Ошибка обновления корзины: $e');
    }
  }

  @override
  Future<Either<String, void>> removeFromCart(int productId) async {
    try {
      await ApiClient.removeFromCart(productId);
      return const Right(null);
    } catch (e) {
      return Left('Ошибка удаления из корзины: $e');
    }
  }

  @override
  Future<Either<String, void>> clearCart() async {
    try {
      final cartItems = await getCartItems();
      
      return await cartItems.fold(
        (error) => Left(error),
        (items) async {
          for (final item in items) {
            await ApiClient.removeFromCart(item.product.id);
          }
          return const Right(null);
        },
      );
    } catch (e) {
      return Left('Ошибка очистки корзины: $e');
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>>> createOrder({
    required String shippingAddress,
    String? notes,
  }) async {
    try {
      final cartItemsResult = await getCartItems();
      
      return await cartItemsResult.fold(
        (error) => Left(error),
        (cartItems) async {
          final items = cartItems.map((item) {
            return {
              'product_id': item.product.id,
              'quantity': item.quantity,
              'price': item.discountPrice ?? item.product.price,
            };
          }).toList();

          final response = await ApiClient.createOrder(
            shippingAddress,
            notes ?? '',
            items,
          );

          await clearCart();

          return Right(response);
        },
      );
    } catch (e) {
      return Left('Ошибка создания заказа: $e');
    }
  }
}