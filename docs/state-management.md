# State Management

## Overview

Riverpod 3.x is the single source of truth for all reactive state.
`setState` MUST NOT be used outside of trivial, widget-local animations.
Riverpod also serves as the DI container — no `get_it` or service locators.

## Provider Types

### Provider (synchronous singleton)

For services that are created once and shared:

```dart
final dioProvider = Provider<Dio>((ref) {
  // build and return Dio instance
});
```

### FutureProvider (one-time async init)

For async initialization that resolves once:

```dart
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});
```

### @riverpod Code Generation (Preferred)

Use `@riverpod` annotation for all new providers:

#### Function-based (auto-disposed, read-only)

```dart
// lib/features/orders/providers.dart
@riverpod
OrderApiService orderApiService(Ref ref) {
  return OrderApiService(ref.watch(dioProvider));
}

@riverpod
OrderRepository orderRepository(Ref ref) {
  return OrderRepositoryImpl(
    apiService: ref.watch(orderApiServiceProvider),
    dao: ref.watch(orderDaoProvider),
  );
}
```

Generated: `orderApiServiceProvider`, `orderRepositoryProvider`

#### Class-based (stateful controllers)

```dart
// lib/features/orders/presentation/controllers/order_list_controller.dart
@riverpod
class OrderListController extends _$OrderListController {
  @override
  Future<List<Order>> build() async {
    return ref.watch(orderRepositoryProvider).getOrders();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(orderRepositoryProvider).getOrders(),
    );
  }

  Future<void> deleteOrder(String id) async {
    await ref.read(orderRepositoryProvider).deleteOrder(id);
    ref.invalidateSelf(); // Re-fetch the list
  }
}
```

Generated: `orderListControllerProvider`

### When to Use What

| Need | Provider type |
|------|--------------|
| Singleton service (Dio, Storage) | `Provider` or `@riverpod` function |
| Async init (SharedPreferences) | `FutureProvider` or `@riverpod Future` |
| Screen state with mutations | `@riverpod class ... extends _$...` (AsyncNotifier) |
| Derived/filtered data | `@riverpod` function that watches another provider |
| Parameterized data | Family provider (see below) |

## AsyncNotifier Pattern (Controllers)

Every screen gets one controller. The controller is an `AsyncNotifier`:

```dart
@riverpod
class OrderDetailController extends _$OrderDetailController {
  @override
  Future<Order> build(String orderId) async {
    // build() is called with the parameter
    return ref.watch(orderRepositoryProvider).getOrder(orderId);
  }

  Future<void> cancelOrder() async {
    final orderId = state.requireValue.id;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(orderRepositoryProvider).cancelOrder(orderId),
    );
  }
}
```

Usage in widget:

```dart
final orderAsync = ref.watch(orderDetailControllerProvider(orderId));

return orderAsync.when(
  data: (order) => OrderDetailView(order: order),
  loading: () => const LoadingIndicator(),
  error: (e, st) => ErrorView(error: e, onRetry: () {
    ref.invalidate(orderDetailControllerProvider(orderId));
  }),
);
```

## Family Providers (Parameterized)

When a provider needs a parameter (e.g., an ID):

```dart
@riverpod
Future<Order> orderDetail(Ref ref, String orderId) async {
  return ref.watch(orderRepositoryProvider).getOrder(orderId);
}
```

Generated: `orderDetailProvider(orderId)`

For class-based, add the parameter to `build()`:

```dart
@riverpod
class OrderDetailController extends _$OrderDetailController {
  @override
  Future<Order> build(String orderId) async { ... }
}
```

## Derived Providers (select / filter)

Create lightweight derived providers for filtered views:

```dart
@riverpod
List<Order> pendingOrders(Ref ref) {
  final allOrders = ref.watch(orderListControllerProvider).valueOrNull ?? [];
  return allOrders.where((o) => o.status == OrderStatus.pending).toList();
}
```

### select() for Rebuild Optimization

Watch only a subset to minimize rebuilds:

```dart
// Only rebuilds when the count changes, not when list contents change
final count = ref.watch(
  orderListControllerProvider.select((s) => s.valueOrNull?.length ?? 0),
);
```

## ref.watch vs ref.read vs ref.listen

| Method | When to use | Where |
|--------|------------|-------|
| `ref.watch()` | Reactive — rebuild when value changes | `build()` method |
| `ref.read()` | One-shot — get current value without subscribing | Callbacks, event handlers |
| `ref.listen()` | Side effects — run code on change without rebuilding | Controllers, `build()` for navigation/snackbars |

```dart
// ref.listen for side effects (e.g., show snackbar on error)
ref.listen(orderListControllerProvider, (prev, next) {
  if (next is AsyncError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(next.error.toUserMessage())),
    );
  }
});
```

## Provider Scoping

### Feature-scoped providers

Each feature's `providers.dart` wires its DI graph:

```dart
// lib/features/orders/providers.dart
@riverpod
OrderApiService orderApiService(Ref ref) { ... }

@riverpod
OrderRepository orderRepository(Ref ref) { ... }
```

### Core providers

Shared infrastructure in `lib/core/di/`:

```dart
// lib/core/di/database_provider.dart
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
```

### Cross-feature communication

Features MUST NOT import each other's providers. Share via core:

```dart
// Feature A needs user from core/auth
final user = ref.watch(currentUserProvider); // from core/auth
```

## Resource Cleanup

```dart
@riverpod
NotificationService notificationService(Ref ref) {
  final service = NotificationService();
  ref.onDispose(service.dispose); // Clean up on provider disposal
  return service;
}
```

## Testing Providers

Override providers in tests:

```dart
final container = ProviderContainer(
  overrides: [
    orderRepositoryProvider.overrideWithValue(mockRepo),
  ],
);
```

See `docs/testing.md` for full testing patterns.

## Rules

- **DO** use `@riverpod` codegen for all new providers.
- **DO** use `ref.watch()` in `build()` for reactive data.
- **DO** use `ref.read()` in callbacks for one-shot actions.
- **DO** use `ref.listen()` for side effects (snackbars, navigation).
- **DO** use `ref.onDispose()` for resource cleanup.
- **DO** use `AsyncValue.guard()` in controller methods.
- **DO** use `select()` to minimize unnecessary rebuilds.
- **DO** expose repositories as abstract types, not implementations.
- **DO NOT** use `setState` for anything beyond trivial local animations.
- **DO NOT** import providers from one feature into another.
- **DO NOT** use `ref.watch()` in callbacks — use `ref.read()`.
- **DO NOT** create providers that depend on `BuildContext`.
