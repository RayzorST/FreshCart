import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:client/api/client.dart';
import 'package:client/data/datasources/local/app_database.dart';
import 'package:client/domain/entities/cart_item_entity.dart';
import 'package:client/domain/entities/product_entity.dart';
import 'package:client/domain/repositories/cart_repository.dart';
import 'package:client/domain/repositories/product_repository.dart';

@LazySingleton(as: CartRepository)
class CartRepositoryImpl implements CartRepository {
  final AppDatabase _database;
  final ProductRepository _productRepository;

  CartRepositoryImpl(this._database, this._productRepository);

  @override
  Future<Either<String, List<CartItemEntity>>> getCartItems() async {
    try {
      final results = await _database.getCartItemsWithProducts();
      
      final cartItems = await Future.wait(results.map((result) async {
        final cartItem = result.$1;
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
        
        return CartItemEntity(
          id: cartItem.id,
          product: product,
          quantity: cartItem.quantity,
          appliedPrice: cartItem.appliedPrice,
          isSynced: cartItem.isSynced,
          addedAt: cartItem.addedAt,
        );
      }));
      
      return Right(cartItems);
    } catch (e) {
      return Left('Ошибка загрузки корзины: $e');
    }
  }
  
  @override
  Future<Either<String, CartItemEntity>> addToCart(CartItemEntity item) async {
    try {
      final existing = await _database.getCartItemByProductId(item.product.id);
      
      if (existing != null) {
        // Обновляем
        final updatedItem = item.copyWith(
          id: existing.id,
          quantity: existing.quantity + item.quantity,
        );
        
        await _database.updateCartItem(CartItemsCompanion(
          id: Value(updatedItem.id!),
          productId: Value(updatedItem.product.id),
          quantity: Value(updatedItem.quantity),
          syncStatus: const Value('pending'), // Помечаем для синхронизации
        ));
        
        return Right(updatedItem);
      } else {
        // Добавляем новый
        final id = await _database.insertCartItem(CartItemsCompanion(
          productId: Value(item.product.id),
          quantity: Value(item.quantity),
          syncStatus: const Value('pending'), // Помечаем для синхронизации
          addedAt: Value(DateTime.now()),
        ));
        
        return Right(item.copyWith(id: id));
      }
    } catch (e) {
      return Left('Ошибка добавления в корзину: $e');
    }
  }

  @override
  Future<Either<String, CartItemEntity>> updateCartItem(CartItemEntity item) async {
    try {
      if (item.id == null) {
        return Left('Элемент корзины не имеет id');
      }
      
      await _updateCartItemInDb(item);
      return Right(item);
    } catch (e) {
      return Left('Ошибка обновления корзины: $e');
    }
  }

  @override
  Future<Either<String, void>> removeFromCart(int productId) async {
    try {
      await _database.removeCartItem(productId);
      return const Right(null);
    } catch (e) {
      return Left('Ошибка удаления из корзины: $e');
    }
  }

  @override
  Future<Either<String, void>> clearCart() async {
    try {
      await _database.clearCart();
      return const Right(null);
    } catch (e) {
      return Left('Ошибка очистки корзины: $e');
    }
  }

  @override
  Future<Either<String, double>> getTotalAmount() async {
    try {
      final cartItems = await getCartItems();
      
      return cartItems.fold(
        (error) => Left(error),
        (items) {
          double total = 0.0;
          for (final item in items) {
            total += item.totalPrice;
          }
          return Right(total);
        },
      );
    } catch (e) {
      return Left('Ошибка расчета суммы: $e');
    }
  }

  @override
  Future<Either<String, void>> syncCartWithServer() async {
    try {
      // 1. Отправляем изменения
      final pendingItems = await _database.getCartItemsPendingSync();
      
      for (final item in pendingItems) {
        try {
          if (item.quantity == 0) {
            await ApiClient.removeFromCart(item.productId);
          } else {
            await ApiClient.addToCart(item.productId, item.quantity);
          }
          
          await _database.markCartItemAsSynced(item.productId);
        } catch (e) {
          print('Ошибка синхронизации товара ${item.productId}: $e');
        }
      }

      // 2. Загружаем актуальную корзину
      final serverCart = await ApiClient.getCart();
      final serverItems = serverCart['items'] as List<dynamic>? ?? [];

      // 3. Обновляем локально
      for (final serverItem in serverItems) {
        final productId = serverItem['product_id'] as int;
        final quantity = serverItem['quantity'] as int;

        final localItem = await _database.getCartItemByProductId(productId);

        if (localItem == null) {
          // Добавляем новый
          await _database.insertCartItem(CartItemsCompanion(
            productId: Value(productId),
            quantity: Value(quantity),
            isSynced: const Value(true),
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(DateTime.now()),
            addedAt: Value(DateTime.now()),
          ));
        } else if (localItem.quantity != quantity) {
          // Обновляем количество
          await _database.updateCartItem(CartItemsCompanion(
            id: Value(localItem.id),
            productId: Value(productId),
            quantity: Value(quantity),
            appliedPrice: Value(localItem.appliedPrice),
            isSynced: const Value(true),
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(DateTime.now()),
            addedAt: Value(localItem.addedAt),
          ));
        }
      }

      return const Right(null);
    } catch (e) {
      return Left('Ошибка синхронизации корзины: $e');
    }
  }

  @override
  Future<bool> isInCart(int productId) async {
    return await _database.isProductInCart(productId);
  }

  @override
  Future<int> getCartItemCount() async {
    return await _database.getCartItemCount();
  }

  // Приватные методы
  Future<void> _updateCartItemInDb(CartItemEntity item) async {
    await _database.updateCartItem(CartItemsCompanion(
      id: Value(item.id!),
      productId: Value(item.product.id),
      quantity: Value(item.quantity),
      appliedPrice: Value(item.appliedPrice),
      isSynced: Value(item.isSynced),
      addedAt: Value(item.addedAt),
    ));
  }
}