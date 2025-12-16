// sync_log_table.dart - новая таблица:
import 'package:drift/drift.dart';

class SyncLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // 'product', 'cart', 'favorite'
  IntColumn get entityId => integer().nullable()();
  TextColumn get operation => text()(); // 'create', 'update', 'delete', 'sync'
  TextColumn get status => text()(); // 'success', 'error', 'pending'
  TextColumn get message => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(Constant(DateTime.now()))();
  
  @override
  Set<Column> get primaryKey => {id};
}