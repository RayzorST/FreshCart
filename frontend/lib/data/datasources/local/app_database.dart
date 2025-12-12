import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Миграции при обновлении схемы
        },
      );

  // ========== Products ==========
  Future<int> insertProduct(ProductsCompanion product) =>
      into(products).insert(product, mode: InsertMode.insertOrReplace);
  
  Future<void> insertProducts(List<ProductsCompanion> productsList) =>
      batch((batch) => batch.insertAll(products, productsList, mode: InsertMode.insertOrReplace));
  
  Future<List<Product>> getAllProducts() => select(products).get();
  
  Future<Product?> getProductById(int id) =>
      (select(products)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  
  Future<void> updateProduct(ProductsCompanion product) =>
      update(products).replace(product);
  
  Future<void> deleteProduct(int id) =>
      (delete(products)..where((tbl) => tbl.id.equals(id))).go();
  
  Future<void> clearProducts() => delete(products).go();

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
        ));
  }
  
  Future<int> getCartItemCount() => select(cartItems).get().then((items) => items.length);
  
  Future<bool> isProductInCart(int productId) =>
      getCartItemByProductId(productId).then((item) => item != null);

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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return driftDatabase(
      name: 'cart.db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationDocumentsDirectory,
      ),
    );
  });
}