# Testing

## Overview

Constitution requires 80% line coverage per feature slice, widget tests for
every screen, and at least one integration test per major feature. All tests
must pass with zero failures before merge.

## Test Structure

Tests mirror `lib/`:

```
test/
├── core/
│   ├── auth/
│   │   └── auth_controller_test.dart
│   ├── network/
│   │   └── auth_interceptor_test.dart
│   └── database/
│       └── migrations_test.dart
├── features/
│   └── orders/
│       ├── presentation/
│       │   ├── screens/
│       │   │   └── order_list_screen_test.dart      # Widget test
│       │   └── controllers/
│       │       └── order_list_controller_test.dart   # Unit test
│       ├── domain/
│       │   └── entities/
│       │       └── order_test.dart                   # Unit test
│       └── data/
│           └── repositories/
│               └── order_repository_impl_test.dart   # Unit test
├── shared/
│   └── widgets/
│       └── primary_button_test.dart
└── helpers/
    ├── mocks.dart             # Shared mocks
    ├── test_app.dart          # ProviderScope wrapper for widget tests
    └── fakes.dart             # Fake data factories
```

## Unit Tests (Domain + Data)

Test pure logic — entities, repositories, use cases:

```dart
// test/features/orders/data/repositories/order_repository_impl_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOrderApiService extends Mock implements OrderApiService {}
class MockOrderDao extends Mock implements OrderDao {}

void main() {
  late OrderRepositoryImpl repository;
  late MockOrderApiService mockApi;
  late MockOrderDao mockDao;

  setUp(() {
    mockApi = MockOrderApiService();
    mockDao = MockOrderDao();
    repository = OrderRepositoryImpl(apiService: mockApi, dao: mockDao);
  });

  group('getOrders', () {
    test('returns orders from API and caches them', () async {
      when(() => mockApi.getOrders()).thenAnswer(
        (_) async => [fakeOrderDto],
      );
      when(() => mockDao.insertOrder(any())).thenAnswer((_) async => 1);

      final result = await repository.getOrders();

      expect(result, hasLength(1));
      verify(() => mockDao.insertOrder(any())).called(1);
    });

    test('falls back to cache on API failure', () async {
      when(() => mockApi.getOrders()).thenThrow(Exception('network'));
      when(() => mockDao.getAllOrders()).thenAnswer(
        (_) async => [fakeCachedOrder],
      );

      final result = await repository.getOrders();

      expect(result, hasLength(1));
      verify(() => mockDao.getAllOrders()).called(1);
    });
  });
}
```

## Controller Tests (Riverpod)

Test controllers using `ProviderContainer` with overrides:

```dart
// test/features/orders/presentation/controllers/order_list_controller_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late ProviderContainer container;
  late MockOrderRepository mockRepo;

  setUp(() {
    mockRepo = MockOrderRepository();
    container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('loads orders on build', () async {
    when(() => mockRepo.getOrders()).thenAnswer(
      (_) async => [fakeOrder],
    );

    // Read the provider to trigger build()
    final controller = container.read(orderListControllerProvider.future);
    final orders = await controller;

    expect(orders, hasLength(1));
  });
}
```

## Widget Tests

Test screens with a wrapped `ProviderScope`:

```dart
// test/helpers/test_app.dart
Widget testApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}
```

```dart
// test/features/orders/presentation/screens/order_list_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  late MockOrderRepository mockRepo;

  setUp(() {
    mockRepo = MockOrderRepository();
  });

  testWidgets('shows order list when data loads', (tester) async {
    when(() => mockRepo.getOrders()).thenAnswer(
      (_) async => [fakeOrder],
    );

    await tester.pumpWidget(testApp(
      child: const OrderListScreen(),
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockRepo),
      ],
    ));

    // Wait for async data
    await tester.pumpAndSettle();

    expect(find.text('Test Order'), findsOneWidget);
  });

  testWidgets('shows error message on failure', (tester) async {
    when(() => mockRepo.getOrders()).thenThrow(Exception('fail'));

    await tester.pumpWidget(testApp(
      child: const OrderListScreen(),
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockRepo),
      ],
    ));

    await tester.pumpAndSettle();

    expect(find.text(t.errors.unknown), findsOneWidget);
  });
}
```

## Integration Tests

Place in `integration_test/`:

```dart
// integration_test/order_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:hayyacom/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('golden path: view orders', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Navigate to orders
    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle();

    // Verify list loads
    expect(find.byType(OrderCard), findsWidgets);
  });
}
```

Run: `flutter test integration_test/`

## Mocking Strategy

Use `mocktail` (no codegen needed):

```dart
// test/helpers/mocks.dart
import 'package:mocktail/mocktail.dart';

class MockOrderRepository extends Mock implements OrderRepository {}
class MockAuthController extends Mock implements AuthController {}
class MockDio extends Mock implements Dio {}
```

Use `fakes.dart` for test data factories:

```dart
// test/helpers/fakes.dart
final fakeOrder = Order(
  id: '1',
  title: 'Test Order',
  status: OrderStatus.pending,
  createdAt: DateTime(2026, 1, 1),
);

final fakeOrderDto = OrderDto(
  id: '1',
  title: 'Test Order',
  status: 'pending',
  createdAt: '2026-01-01T00:00:00Z',
);
```

## Coverage

Run with coverage:

```sh
flutter test --coverage
# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

Target: **80% line coverage per feature slice** (constitution mandate).

## What to Test

| Layer | What to test | Type |
|-------|-------------|------|
| `domain/entities/` | Value equality, computed properties, edge cases | Unit |
| `domain/use_cases/` | Business logic, multi-repo coordination | Unit |
| `data/repositories/` | API-to-entity mapping, cache fallback, error handling | Unit |
| `data/data_sources/` | DAO queries (in-memory DB), API contract | Unit |
| `presentation/controllers/` | State transitions, side effects | Unit (Riverpod) |
| `presentation/screens/` | Widget renders correctly, user interactions | Widget |
| Golden-path flows | End-to-end user journeys | Integration |

## Rules

- **DO** use `mocktail` for mocking — no codegen overhead.
- **DO** use `ProviderContainer` with `overrides` for controller tests.
- **DO** use `testApp()` wrapper for widget tests.
- **DO** create test data factories in `test/helpers/fakes.dart`.
- **DO** test error/loading states, not just happy paths.
- **DO NOT** test generated code (`*.g.dart`, `*.freezed.dart`).
- **DO NOT** test Flutter framework internals (e.g., "Scaffold renders").
- **DO NOT** use `setUp`/`tearDown` for ProviderContainer without `dispose()`.
- **DO NOT** skip flaky tests — quarantine and fix within the sprint.
