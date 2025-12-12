import 'package:drift/drift.dart';

class Products extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  RealColumn get price => real()();
  IntColumn get stockQuantity => integer().named('stock_quantity')();
  TextColumn get category => text().nullable()();
  BoolColumn get isActive => boolean().named('is_active').withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(Constant(DateTime.now()))();

  @override
  Set<Column> get primaryKey => {id};
}