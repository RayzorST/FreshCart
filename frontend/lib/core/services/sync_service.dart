// sync_service.dart - исправленный
import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:client/api/client.dart';
import 'package:client/data/datasources/local/app_database.dart';
import 'package:client/domain/entities/product_entity.dart';

@LazySingleton()
class SyncService {
  final AppDatabase _database;

  SyncService(this._database);

  // Синхронизация корзины
  Future<Either<String, void>> syncCart() async {
    try {
      // 1. Отправляем локальные изменения
      final pendingCartItems = await _database.getCartItemsPendingSync();
      
      for (final item in pendingCartItems) {
        try {
          if (item.quantity == 0) {
            await ApiClient.removeFromCart(item.productId);
          } else {
            await ApiClient.addToCart(item.productId, item.quantity);
          }
          
          await _database.markCartItemAsSynced(item.productId);
        } catch (e) {
          print('Ошибка синхронизации товара ${item.productId}: $e');
          // Не бросаем исключение, продолжаем с другими товарами
        }
      }

      // 2. Получаем актуальную корзину с сервера (если пользователь авторизован)
      try {
        final serverCart = await ApiClient.getCart();
        final serverItems = serverCart['items'] as List<dynamic>? ?? [];

        // 3. Обновляем локальную БД
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
          } else {
            // Обновляем
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
      } catch (e) {
        // Если не авторизован, просто пропускаем загрузку с сервера
        print('Не удалось загрузить корзину с сервера: $e');
      }

      return const Right(null);
    } catch (e) {
      return Left('Ошибка синхронизации корзины: $e');
    }
  }

  // Синхронизация продуктов
  Future<Either<String, void>> syncProducts() async {
    try {
      final response = await ApiClient.getProducts();
      
      for (final productJson in response) {
        final product = ProductEntity.fromJson(productJson);
        
        await _database.insertProduct(ProductsCompanion(
          id: Value(product.id),
          name: Value(product.name),
          description: Value(product.description),
          price: Value(product.price),
          stockQuantity: Value(product.stockQuantity),
          category: Value(product.category),
          isActive: Value(product.isActive),
          updatedAt: Value(product.updatedAt),
          createdAt: Value(product.createdAt),
          syncStatus: const Value('synced'),
          lastSyncedAt: Value(DateTime.now()),
        ));
      }
      
      return const Right(null);
    } catch (e) {
      return Left('Ошибка синхронизации продуктов: $e');
    }
  }

  // Синхронизация избранного (если нужно)
  Future<Either<String, void>> syncFavorites() async {
    try {
      // Если API поддерживает избранное
      // final favorites = await ApiClient.getFavorites();
      // ... синхронизация ...
      return const Right(null);
    } catch (e) {
      return Left('Ошибка синхронизации избранного: $e');
    }
  }

  // Проверка обновлений продуктов
  Future<bool> checkProductsUpdate() async {
    try {
      final serverProducts = await ApiClient.getProducts();
      if (serverProducts.isEmpty) return false;
      
      // Берем время обновления последнего продукта как индикатор
      final latestProduct = serverProducts
          .map((json) => ProductEntity.fromJson(json))
          .reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b);
      
      final localProducts = await _database.getAllProducts();
      if (localProducts.isEmpty) return true;
      
      final latestLocal = localProducts
          .reduce((a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b);
      
      return latestProduct.updatedAt.isAfter(latestLocal.updatedAt);
    } catch (e) {
      print('Ошибка проверки обновлений: $e');
      return false;
    }
  }
}