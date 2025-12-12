import 'package:drift/drift.dart';
import 'products_table.dart';


class FavoriteItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)(); // Ссылка на продукт
  DateTimeColumn get addedAt => dateTime().withDefault(Constant(DateTime.now()))();
  
  @override
  List<Set<Column<Object>>>? get uniqueKeys => [{productId}];
}