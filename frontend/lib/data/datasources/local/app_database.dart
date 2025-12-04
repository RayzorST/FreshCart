import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:injectable/injectable.dart';

import 'tables/cart_items_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [CartItems])
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

  // Методы для работы с корзиной
  Future<int> addToCart(CartItemsCompanion item) => into(cartItems).insert(item);
  
  Future<void> updateCartItem(CartItemsCompanion item) => update(cartItems).replace(item);
  
  Future<void> removeFromCart(int productId) =>
      (delete(cartItems)..where((tbl) => tbl.productId.equals(productId))).go();
  
  Future<List<CartItem>> getCartItems() => select(cartItems).get();
  
  Future<CartItem?> getCartItemByProductId(int productId) =>
      (select(cartItems)..where((tbl) => tbl.productId.equals(productId))).getSingleOrNull();
  
  Future<void> clearCart() => delete(cartItems).go();
  
  Future<void> markAsSynced(int productId) async {
    await (update(cartItems)
          ..where((tbl) => tbl.productId.equals(productId)))
        .write(CartItemsCompanion(
          isSynced: const Value(true),
          updatedAt: Value(DateTime.now()),
        ));
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