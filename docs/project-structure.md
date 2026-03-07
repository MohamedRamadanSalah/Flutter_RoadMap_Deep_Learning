# Project Structure

## High-Level Layout

```
lib/
├── main.dart                         # Entry point, ProviderScope, init
├── app.dart                          # MaterialApp.router root widget
├── core/                             # Shared infrastructure (no business logic)
│   ├── auth/                         # Shared auth state + providers
│   ├── database/                     # Single Drift AppDatabase + table defs
│   ├── di/                           # App-wide Riverpod providers
│   ├── router/                       # GoRouter config, route composition
│   ├── network/                      # Dio client, interceptors
│   ├── storage/                      # SharedPreferences wrapper
│   ├── notifications/                # NotificationService (FCM + local)
│   ├── i18n/                         # Slang-generated translations
│   ├── theme/                        # Material 3 ThemeData, ColorScheme
│   └── utils/                        # Logger, shared constants
├── features/                         # One directory per feature slice
│   └── <feature_name>/              # See "Feature Slice Anatomy" below
├── shared/
│   ├── models/                       # Cross-feature value objects
│   ├── widgets/                      # Reusable UI components
│   └── extensions/                   # Dart extension methods
assets/
├── svg/                              # SVG files (auto-compiled via transformer)
├── images/                           # Raster images
├── fonts/                            # Custom fonts
└── i18n/                             # Translation source files for slang
test/
├── core/
├── features/
│   └── <feature_name>/              # Mirrors lib/features/ structure
└── shared/
```

## Feature Slice Anatomy

Every feature is a self-contained vertical slice. Name features after
**functional requirements** (what users do), not screens.

Good: `auth`, `orders`, `messaging`, `invitations`
Bad: `home_screen`, `settings_page`, `bottom_nav`

```
lib/features/<feature_name>/
├── <feature_name>.dart               # Barrel file — public API only
├── providers.dart                    # All feature-scoped Riverpod providers
├── providers.g.dart                  # Generated
├── presentation/
│   ├── routes.dart                   # GoRouter route definitions
│   ├── screens/                      # Full-page widgets (one per route)
│   │   ├── example_list_screen.dart
│   │   └── example_detail_screen.dart
│   ├── widgets/                      # Feature-scoped UI components
│   │   ├── example_card.dart
│   │   └── example_status_badge.dart
│   └── controllers/                  # AsyncNotifier / Notifier subclasses
│       ├── example_list_controller.dart
│       ├── example_list_controller.g.dart
│       ├── example_detail_controller.dart
│       └── example_detail_controller.g.dart
├── domain/
│   ├── entities/                     # Pure business objects (Freezed, no JSON)
│   │   ├── example.dart
│   │   ├── example.freezed.dart
│   │   └── example_status.dart
│   ├── repositories/                 # Abstract interfaces only
│   │   └── example_repository.dart
│   └── use_cases/                    # OPTIONAL — only when needed
│       └── cancel_example_use_case.dart
└── data/
    ├── repositories/                 # Concrete implementations
    │   └── example_repository_impl.dart
    ├── data_sources/
    │   ├── remote/                   # Retrofit API services
    │   │   ├── example_api_service.dart
    │   │   └── example_api_service.g.dart
    │   └── local/                    # Drift DAOs, cache helpers
    │       └── example_local_source.dart
    └── models/                       # DTOs with JSON serialization
        ├── example_dto.dart
        ├── example_dto.freezed.dart
        └── example_dto.g.dart
```

### Layer Responsibilities

#### `presentation/` — UI and state management

- **`screens/`**: One `ConsumerWidget` per route. Watches controllers,
  delegates all logic. No business logic here.
- **`widgets/`**: Feature-scoped UI components reused across screens within
  this feature. Truly reusable widgets go to `lib/shared/widgets/`.
- **`controllers/`**: `AsyncNotifier` or `Notifier` subclasses via
  `@riverpod` codegen. One controller per screen or meaningful state scope.
  Controllers talk to repositories via `ref.watch()`, never to data sources
  directly.
- **`routes.dart`**: Exports `List<RouteBase>` consumed by the app router.

#### `domain/` — Business rules (pure Dart, no Flutter imports)

- **`entities/`**: Immutable value objects via Freezed. No
  `json_serializable` — entities know nothing about serialization.
- **`repositories/`**: Abstract interfaces defining the data contract.
  The presentation layer depends on these, not on implementations.
- **`use_cases/`**: OPTIONAL. Add only when logic coordinates multiple
  repositories, or when the same business logic is reused by multiple
  controllers.

#### `data/` — Implementation details

- **`repositories/`**: Concrete implementations of domain interfaces.
  Coordinates remote + local sources, converts DTOs to entities.
- **`data_sources/remote/`**: Retrofit `@RestApi()` classes. One API service
  per feature.
- **`data_sources/local/`**: Drift DAOs or SharedPreferences wrappers for
  local caching.
- **`models/`**: DTOs with `@freezed` + `@JsonSerializable`. Include a
  `toEntity()` method for conversion to domain entities. Entities never know
  about DTOs; DTOs know about entities.

### Barrel File

Each feature has one barrel file at `<feature_name>.dart`. It exports
**only the public API**:

```dart
// lib/features/orders/orders.dart

// Domain entities (safe for shared/core references)
export 'domain/entities/order.dart';
export 'domain/entities/order_status.dart';

// Providers (DI wiring)
export 'providers.dart';

// Routes (for app_router composition)
export 'presentation/routes.dart';
```

Never export internal implementation details (repository implementations,
DTOs, controllers).

### Feature Providers

Each feature has one `providers.dart` at the feature root that wires
the full DI graph:

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
    localSource: ref.watch(orderLocalSourceProvider),
  );
}
```

Expose repositories as **abstract types** (e.g., `OrderRepository`, not
`OrderRepositoryImpl`) to maintain dependency inversion.

### Feature Routes

Each feature exports its routes for composition in the app router:

```dart
// lib/features/orders/presentation/routes.dart
final orderRoutes = <RouteBase>[
  GoRoute(
    path: '/orders',
    name: 'orders',
    builder: (context, state) => const OrderListScreen(),
    routes: [
      GoRoute(
        path: ':orderId',
        name: 'order-detail',
        builder: (context, state) => OrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
    ],
  ),
];
```

The app router in `core/router/app_router.dart` composes all feature routes:

```dart
@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    redirect: (context, state) {
      // Auth guard logic
    },
    routes: [
      ...authRoutes,
      ...orderRoutes,
      ...messagingRoutes,
    ],
  );
}
```

## Dependency Flow

```
ALLOWED:
  presentation/  →  domain/           Controllers use entities + repo interfaces
  presentation/  →  providers.dart    Controllers receive deps via Riverpod
  data/          →  domain/           Impls implement repo interfaces, DTOs map to entities
  providers.dart →  data/             Wires concrete implementations
  providers.dart →  domain/           Exposes abstract repo type
  providers.dart →  core/             Accesses Dio, Database, Auth
  any layer      →  shared/           Shared models, extensions, widgets
  any layer      →  core/             Infrastructure providers

FORBIDDEN:
  domain/        →  data/             Domain never knows about implementation
  domain/        →  presentation/     Domain never knows about UI
  feature_a/     →  feature_b/*       No cross-feature internal imports
  core/          →  features/         Core never depends on features
```

## Cross-Feature Communication

Features MUST NOT import each other's internal files. When Feature A needs
data from Feature B:

1. Extract the shared contract into `core/` (e.g., `core/auth/` for auth state).
2. Both features depend on the core abstraction via `ref.watch()`.
3. Riverpod's reactive provider model handles cross-feature data flow —
   any feature can watch a core provider.

Example — auth state shared across all features:

```dart
// core/auth/auth_providers.dart (any feature can ref.watch this)
@riverpod
class AuthState extends _$AuthState {
  @override
  Future<User?> build() async { ... }
}

// features/orders/presentation/controllers/order_list_controller.dart
@riverpod
class OrderListController extends _$OrderListController {
  @override
  Future<List<Order>> build() async {
    final user = ref.watch(currentUserProvider);  // from core
    if (user == null) return [];
    return ref.watch(orderRepositoryProvider).getOrdersForUser(user.id);
  }
}
```

## When to Add Optional Layers

| Layer | Add when... |
|---|---|
| `domain/use_cases/` | Logic coordinates multiple repositories, or is reused by 2+ controllers |
| `data/mappers/` | DTO-to-entity conversion is complex enough to warrant a separate class |
| `presentation/providers/` | Simple derived/filtered providers that aren't full controllers |

If a layer only has one file, it probably doesn't need to exist yet. Start
lean; add structure when complexity demands it.

## Test Structure

Tests mirror the `lib/` structure:

```
test/features/<feature_name>/
├── presentation/
│   ├── screens/
│   │   └── example_list_screen_test.dart    # Widget tests
│   └── controllers/
│       └── example_list_controller_test.dart # Unit tests
├── domain/
│   ├── entities/
│   │   └── example_test.dart                # Unit tests
│   └── use_cases/
│       └── cancel_example_use_case_test.dart # Unit tests
└── data/
    └── repositories/
        └── example_repository_impl_test.dart # Unit tests (mock data sources)
```
