# Database (Drift)

## Overview

Drift provides type-safe SQLite access with compile-time SQL verification,
auto-generated DAOs, and schema migrations. Use Drift for **structured local
data** that requires queries, relations, or migrations. Use SharedPreferences
for simple key-value flags.

## Architecture

```
lib/core/database/
├── app_database.dart         # Single AppDatabase class + table definitions
├── app_database.g.dart       # Generated
└── migrations.dart           # Migration steps

lib/features/<feature>/data/
├── data_sources/local/
│   └── <feature>_dao.dart    # Feature-scoped DAO (extends DatabaseAccessor)
```

One database instance, many DAOs. Each feature owns its DAO but the database
and table definitions live in `core/`.

## Database Setup

```dart
// lib/core/database/app_database.dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

part 'app_database.g.dart';

// ── Table definitions ──────────────────────────────────────

class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().unique()();
  TextColumn get title => text()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

class CachedUsers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get remoteId => text().unique()();
  TextColumn get name => text()();
  TextColumn get email => text()();
}

// ── Database ───────────────────────────────────────────────

@DriftDatabase(tables: [Orders, CachedUsers])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Bump this when the schema changes.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Run incremental migrations
          await runMigrations(m, from, to);
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'hayyacom.db'));
    return NativeDatabase(file);
  });
}
```

## Database Provider

```dart
// lib/core/di/database_provider.dart
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
```

## Feature DAO Pattern

Each feature creates a DAO that extends `DatabaseAccessor`:

```dart
// lib/features/orders/data/data_sources/local/order_dao.dart
import 'package:drift/drift.dart';
import 'package:hayyacom/core/database/app_database.dart';

part 'order_dao.g.dart';

@DriftAccessor(tables: [Orders])
class OrderDao extends DatabaseAccessor<AppDatabase> with _$OrderDaoMixin {
  OrderDao(super.db);

  Future<List<Order>> getAllOrders() => select(orders).get();

  Stream<List<Order>> watchAllOrders() => select(orders).watch();

  Future<Order?> getByRemoteId(String remoteId) =>
      (select(orders)..where((o) => o.remoteId.equals(remoteId)))
          .getSingleOrNull();

  Future<int> insertOrder(OrdersCompanion entry) =>
      into(orders).insert(entry, mode: InsertMode.insertOrReplace);

  Future<bool> updateOrder(OrdersCompanion entry) =>
      update(orders).replace(entry);

  Future<int> deleteByRemoteId(String remoteId) =>
      (delete(orders)..where((o) => o.remoteId.equals(remoteId))).go();
}
```

Wire the DAO in the feature's `providers.dart`:

```dart
// lib/features/orders/providers.dart
@riverpod
OrderDao orderDao(Ref ref) {
  return OrderDao(ref.watch(appDatabaseProvider));
}
```

## Migrations

Add incremental migration steps:

```dart
// lib/core/database/migrations.dart
import 'package:drift/drift.dart';

Future<void> runMigrations(Migrator m, int from, int to) async {
  if (from < 2) {
    // v1 → v2: add 'priority' column to orders
    await m.addColumn(orders, orders.priority);
  }
  if (from < 3) {
    // v2 → v3: create new table
    await m.createTable(notifications);
  }
}
```

After changing the schema:
1. Bump `schemaVersion` in `AppDatabase`.
2. Add the migration step in `runMigrations`.
3. Run `dart run build_runner build --delete-conflicting-outputs`.
4. Test the migration (see Testing section below).

## Repository Integration

The repository coordinates remote + local:

```dart
// lib/features/orders/data/repositories/order_repository_impl.dart
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({required this.apiService, required this.dao});

  final OrderApiService apiService;
  final OrderDao dao;

  @override
  Future<List<Order>> getOrders() async {
    try {
      // Fetch from API
      final dtos = await apiService.getOrders();
      // Cache locally
      for (final dto in dtos) {
        await dao.insertOrder(dto.toCompanion());
      }
      return dtos.map((d) => d.toEntity()).toList();
    } catch (_) {
      // Fallback to cache on network failure
      final cached = await dao.getAllOrders();
      return cached.map((row) => row.toEntity()).toList();
    }
  }
}
```

## Testing

Use Drift's in-memory database for tests:

```dart
// test/features/orders/data/order_dao_test.dart
import 'package:drift/native.dart';

AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}

void main() {
  late AppDatabase db;
  late OrderDao dao;

  setUp(() {
    db = createTestDatabase();
    dao = OrderDao(db);
  });

  tearDown(() => db.close());

  test('inserts and retrieves order', () async {
    await dao.insertOrder(OrdersCompanion.insert(
      remoteId: 'abc-123',
      title: 'Test Order',
      status: 'pending',
      createdAt: DateTime.now(),
    ));
    final orders = await dao.getAllOrders();
    expect(orders, hasLength(1));
    expect(orders.first.remoteId, 'abc-123');
  });
}
```

Add a `forTesting` named constructor to `AppDatabase`:

```dart
AppDatabase.forTesting(super.e);
```

## Rules

- **DO** define all tables in `core/database/app_database.dart`.
- **DO** use `DatabaseAccessor` (DAO) per feature for data access.
- **DO** always write migration steps — never delete and recreate the database.
- **DO** test migrations with in-memory databases.
- **DO** use `ref.onDispose(db.close)` to clean up the database connection.
- **DO NOT** use raw SQL strings — use Drift's type-safe query API.
- **DO NOT** access the database directly from presentation layer — go through repositories.
- **DO NOT** create multiple `AppDatabase` instances.
