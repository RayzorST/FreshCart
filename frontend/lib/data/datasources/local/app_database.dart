// app_database.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:injectable/injectable.dart';

import 'tables/products_table.dart';
import 'tables/cart_items_table.dart';
import 'tables/favorite_items_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Products, CartItems, FavoriteItems])
@lazySingleton
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // Увеличиваем версию для синхронизации

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Добавляем поля синхронизации в версии 2
            await m.addColumn(products, products.syncStatus);
            await m.addColumn(products, products.lastSyncedAt);
            
            await m.addColumn(cartItems, cartItems.syncStatus);
            await m.addColumn(cartItems, cartItems.lastSyncedAt);
            
            await m.addColumn(favoriteItems, favoriteItems.syncStatus);
            await m.addColumn(favoriteItems, favoriteItems.lastSyncedAt);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ========== Products ==========
  
  Future<int> insertProduct(ProductsCompanion product) =>
      into(products).insert(product, mode: InsertMode.insertOrReplace);
  
  Future<void> insertProducts(List<ProductsCompanion> productsList) async {
    await batch((batch) {
      batch.insertAll(products, productsList, mode: InsertMode.insertOrReplace);
    });
  }
  
  Future<List<Product>> getAllProducts() => select(products).get();
  
  Future<Product?> getProductById(int id) =>
      (select(products)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  
  Future<void> updateProduct(ProductsCompanion product) =>
      update(products).replace(product);
  
  Future<void> deleteProduct(int id) =>
      (delete(products)..where((tbl) => tbl.id.equals(id))).go();
  
  Future<void> clearProducts() => delete(products).go();

  // Методы для синхронизации продуктов
  Future<void> markProductAsSynced(int productId) async {
    await (update(products)
          ..where((tbl) => tbl.id.equals(productId)))
        .write(ProductsCompanion(
          syncStatus: const Value('synced'),
          lastSyncedAt: Value(DateTime.now()),
        ));
  }
  
  Future<void> markProductAsPending(int productId) async {
    await (update(products)
          ..where((tbl) => tbl.id.equals(productId)))
        .write(ProductsCompanion(
          syncStatus: const Value('pending'),
        ));
  }
  
  Future<List<Product>> getProductsPendingSync() {
    return (select(products)
          ..where((tbl) => tbl.syncStatus.equals('pending')))
        .get();
  }

  // ========== Cart Items ==========
  
  Future<int> insertCartItem(CartItemsCompanion item) =>
      into(cartItems).insert(item);
  
  Future<void> updateCartItem(CartItemsCompanion item) =>
      update(cartItems).replace(item);
  
  Future<void> removeCartItem(int productId) =>
      (delete(cartItems)..where((tbl) => tbl.productId.equals(productId))).go();
  
  Future<List<CartItem>> getCartItems() => select(cartItems).get();
  
  Future<CartItem?> getCartItemByProductId(int productId) =>
      (select(cartItems)..where((tbl) => tbl.productId.equals(productId))).getSingleOrNull();
  
  Future<void> clearCart() => delete(cartItems).go();
  
  Future<void> markCartItemAsSynced(int productId) async {
    await (update(cartItems)
          ..where((tbl) => tbl.productId.equals(productId)))
        .write(CartItemsCompanion(
          isSynced: const Value(true),
          syncStatus: const Value('synced'),
          lastSyncedAt: Value(DateTime.now()),
        ));
  }
  
  Future<int> getCartItemCount() => select(cartItems).get().then((items) => items.length);
  
  Future<bool> isProductInCart(int productId) =>
      getCartItemByProductId(productId).then((item) => item != null);
  
  Future<List<CartItem>> getCartItemsPendingSync() {
    return (select(cartItems)
          ..where((tbl) => tbl.syncStatus.equals('pending')))
        .get();
  }

  // ========== Favorite Items ==========
  
  Future<int> insertFavoriteItem(FavoriteItemsCompanion item) =>
      into(favoriteItems).insert(item);
  
  Future<void> removeFavoriteItem(int productId) =>
      (delete(favoriteItems)..where((tbl) => tbl.productId.equals(productId))).go();
  
  Future<List<FavoriteItem>> getFavoriteItems() => select(favoriteItems).get();
  
  Future<FavoriteItem?> getFavoriteItemByProductId(int productId) =>
      (select(favoriteItems)..where((tbl) => tbl.productId.equals(productId))).getSingleOrNull();
  
  Future<void> clearFavorites() => delete(favoriteItems).go();
  
  Future<bool> isProductFavorite(int productId) =>
      getFavoriteItemByProductId(productId).then((item) => item != null);
  
  Future<List<FavoriteItem>> getFavoritesPendingSync() {
    return (select(favoriteItems)
          ..where((tbl) => tbl.syncStatus.equals('pending')))
        .get();
  }
  
  Future<void> markFavoriteAsSynced(int productId) async {
    await (update(favoriteItems)
          ..where((tbl) => tbl.productId.equals(productId)))
        .write(FavoriteItemsCompanion(
          syncStatus: const Value('synced'),
          lastSyncedAt: Value(DateTime.now()),
        ));
  }

  // ========== Join Queries ==========
  
  Future<List<(CartItem, Product)>> getCartItemsWithProducts() {
    final query = select(cartItems).join([
      innerJoin(products, products.id.equalsExp(cartItems.productId)),
    ]);
    
    return query.map((row) {
      final cartItem = row.readTable(cartItems);
      final product = row.readTable(products);
      return (cartItem, product);
    }).get();
  }
  
  Future<List<(FavoriteItem, Product)>> getFavoritesWithProducts() {
    final query = select(favoriteItems).join([
      innerJoin(products, products.id.equalsExp(favoriteItems.productId)),
    ]);
    
    return query.map((row) {
      final favoriteItem = row.readTable(favoriteItems);
      final product = row.readTable(products);
      return (favoriteItem, product);
    }).get();
  }
  
  // ========== Утилиты ==========
  
  Future<void> markAllCartItemsAsSynced() async {
    await (update(cartItems)
          ..where((tbl) => tbl.syncStatus.equals('pending')))
        .write(CartItemsCompanion(
          isSynced: const Value(true),
          syncStatus: const Value('synced'),
          lastSyncedAt: Value(DateTime.now()),
        ));
  }
  
  Future<void> markAllFavoritesAsSynced() async {
    await (update(favoriteItems)
          ..where((tbl) => tbl.syncStatus.equals('pending')))
        .write(FavoriteItemsCompanion(
          syncStatus: const Value('synced'),
          lastSyncedAt: Value(DateTime.now()),
        ));
  }
  
  Future<void> markAllProductsAsSynced() async {
    await (update(products)
          ..where((tbl) => tbl.syncStatus.equals('pending')))
        .write(ProductsCompanion(
          syncStatus: const Value('synced'),
          lastSyncedAt: Value(DateTime.now()),
        ));
  }
  
  // Проверка наличия ожидающих синхронизации элементов
  Future<bool> hasPendingSync() async {
    final cartPending = await getCartItemsPendingSync();
    final favoritesPending = await getFavoritesPendingSync();
    final productsPending = await getProductsPendingSync();
    
    return cartPending.isNotEmpty || 
           favoritesPending.isNotEmpty || 
           productsPending.isNotEmpty;
  }
  
  // Получить количество ожидающих элементов
  Future<Map<String, int>> getPendingSyncCounts() async {
    final cartPending = await getCartItemsPendingSync();
    final favoritesPending = await getFavoritesPendingSync();
    final productsPending = await getProductsPendingSync();
    
    return {
      'cart': cartPending.length,
      'favorites': favoritesPending.length,
      'products': productsPending.length,
    };
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cart.db'));
    
    return NativeDatabase(
      file,
      setup: (db) {
        // Включаем поддержку внешних ключей
        db.execute('PRAGMA foreign_keys = ON');
      },
    );
  });
}