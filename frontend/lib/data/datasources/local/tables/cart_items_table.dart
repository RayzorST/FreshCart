import 'package:drift/drift.dart';

class CartItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer()();
  TextColumn get productName => text()();
  TextColumn get productCategory => text()();
  RealColumn get price => real()();
  RealColumn get originalPrice => real().nullable()();
  IntColumn get quantity => integer()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get promotions => text().nullable()();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(Constant(DateTime.now()))();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').withDefault(Constant(DateTime.now()))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [{productId}];
}