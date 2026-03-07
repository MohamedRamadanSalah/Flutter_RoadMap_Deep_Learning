import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'data_drift.g.dart';

// ...existing code...
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get remoteId => integer().unique()();
  TextColumn get name => text().unique()();
  RealColumn get price => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}

class Order extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  DateTimeColumn get orderDate => dateTime()();
}

@DriftDatabase(tables: [Products, Order])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'app.sqlite');
}
