import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:client/api/client.dart';
import 'package:client/data/datasources/local/app_database.dart';
import 'package:client/domain/entities/cart_item_entity.dart';
import 'package:client/domain/repositories/cart_repository.dart';

@LazySingleton(as: CartRepository)
class CartRepositoryImpl implements CartRepository {
  final AppDatabase _database;

  CartRepositoryImpl(this._database);

  @override
  Future<Either<String, List<CartItemEntity>>> getCartItems() async {
    try {
      final items = await _database.getCartItems();
      
      final entities = items.map((item) {
        return CartItemEntity(
          id: item.id,
          productId: item.productId,
          productName: item.productName,
          productCategory: item.productCategory,
          price: item.price,
          originalPrice: item.originalPrice,
          quantity: item.quantity,
          imageUrl: item.imageUrl,
          promotions: item.promotions != null
              ? List<Map<String, dynamic>>.from(jsonDecode(item.promotions!))
              : [],
          isSynced: item.isSynced,
          createdAt: item.createdAt,
          updatedAt: item.updatedAt,
        );
      }).toList();
      
      return Right(entities);
    } catch (e) {
      return Left('Ошибка загрузки корзины: $e');
    }
  }

  @override
  Future<Either<String, CartItemEntity>> addToCart(CartItemEntity item) async {
    try {
      // Используем .insert который автоматически создает Value обертки
      final id = await _database.addToCart(
        CartItemsCompanion.insert(
          productId: item.productId,
          productName: item.productName,
          productCategory: item.productCategory,
          price: item.price,
          originalPrice: item.originalPrice != null 
              ? Value(item.originalPrice!)
              : const Value.absent(),
          quantity: item.quantity,
          imageUrl: item.imageUrl != null 
              ? Value(item.imageUrl!)
              : const Value.absent(),
          promotions: item.promotions.isNotEmpty 
              ? Value(jsonEncode(item.promotions))
              : const Value.absent(),
          isSynced: Value(item.isSynced),
        ),
      );
      
      return Right(item.copyWith(id: id));
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
      
      final companion = CartItemsCompanion(
        id: Value(item.id!),
        productId: Value(item.productId),
        productName: Value(item.productName),
        productCategory: Value(item.productCategory),
        price: Value(item.price),
        originalPrice: Value(item.originalPrice),
        quantity: Value(item.quantity),
        imageUrl: Value(item.imageUrl),
        promotions: Value(item.promotions.isNotEmpty 
            ? jsonEncode(item.promotions)
            : null),
        isSynced: Value(item.isSynced),
        updatedAt: Value(DateTime.now()),
      );
      
      await _database.updateCartItem(companion);
      
      return Right(item.copyWith(updatedAt: DateTime.now()));
    } catch (e) {
      return Left('Ошибка обновления корзины: $e');
    }
  }

  @override
  Future<Either<String, void>> removeFromCart(int productId) async {
    try {
      await _database.removeFromCart(productId);
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
      final items = await _database.getCartItems();
      double total = 0.0;
      
      for (final item in items) {
        total += item.price * item.quantity;
      }
      
      return Right(total);
    } catch (e) {
      return Left('Ошибка расчета суммы: $e');
    }
  }

  @override
  Future<Either<String, void>> syncCartWithServer() async {
    try {
      // 1. Получаем локальные несинхронизированные товары
      final localItems = await _database.getCartItems();
      final unsyncedItems = localItems.where((item) => !item.isSynced).toList();
      
      // 2. Синхронизируем с сервером
      for (final item in unsyncedItems) {
        try {
          if (item.quantity == 0) {
            await ApiClient.removeFromCart(item.productId);
          } else {
            await ApiClient.addToCart(item.productId, item.quantity);
          }
          
          // Помечаем как синхронизированный
          await _database.markAsSynced(item.productId);
        } catch (e) {
          // Продолжаем синхронизацию других товаров
          print('Ошибка синхронизации товара ${item.productId}: $e');
        }
      }
      
      // 3. Получаем актуальную корзину с сервера
      final serverCart = await ApiClient.getCart();
      final serverItems = serverCart['items'] as List<dynamic>? ?? [];
      
      // 4. Обновляем локальную БД данными с сервера
      for (final serverItem in serverItems) {
        final itemMap = _convertToSafeMap(serverItem);
        final productId = itemMap['product_id'] as int;
        final quantity = itemMap['quantity'] as int;
        
        final localItem = await _database.getCartItemByProductId(productId);
        
        if (localItem == null) {
          // Добавляем новый товар
          await _database.addToCart(CartItemsCompanion.insert(
            productId: productId,
            productName: '',
            productCategory: '',
            price: 0.0,
            quantity: quantity,
            isSynced: const Value(true),
          ));
        } else if (localItem.quantity != quantity) {
          // Обновляем количество
          await _database.updateCartItem(CartItemsCompanion(
            id: Value(localItem.id),
            productId: Value(productId),
            productName: Value(localItem.productName),
            productCategory: Value(localItem.productCategory),
            price: Value(localItem.price),
            originalPrice: Value(localItem.originalPrice),
            quantity: Value(quantity),
            imageUrl: Value(localItem.imageUrl),
            promotions: Value(localItem.promotions),
            isSynced: const Value(true),
            updatedAt: Value(DateTime.now()),
          ));
        }
      }
      
      return const Right(null);
    } catch (e) {
      return Left('Ошибка синхронизации корзины: $e');
    }
  }

  Map<String, dynamic> _convertToSafeMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      try {
        return Map<String, dynamic>.from(data);
      } catch (e) {
        return {};
      }
    }
    return {};
  }
}