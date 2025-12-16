import 'package:drift/drift.dart';
import 'products_table.dart';


class FavoriteItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)(); // Ссылка на продукт
  DateTimeColumn get addedAt => dateTime().withDefault(Constant(DateTime.now()))();

  TextColumn get syncStatus => text()
    .withDefault(const Constant('pending'))
    .named('sync_status')();
      
  DateTimeColumn get lastSyncedAt => dateTime()
    .nullable()
    .named('last_synced_at')();
  
  @override
  List<Set<Column<Object>>>? get uniqueKeys => [{productId}];
}