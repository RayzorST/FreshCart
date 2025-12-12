import 'package:drift/drift.dart';
import 'products_table.dart';

class CartItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)(); 
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  RealColumn get appliedPrice => real().nullable().named('applied_price')();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false)).named('is_synced')();
  DateTimeColumn get addedAt => dateTime().withDefault(Constant(DateTime.now()))();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [{productId}];
}