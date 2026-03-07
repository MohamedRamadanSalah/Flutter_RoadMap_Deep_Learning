# Code Generation — Complete In-Depth Reference

---

## Table of Contents

1. [Overview & Philosophy](#overview--philosophy)
2. [What Is Code Generation in Dart/Flutter?](#what-is-code-generation-in-dartflutter)
3. [The build_runner Engine](#the-build_runner-engine)
4. [How Dart `part` / `part of` Directives Work](#how-dart-part--part-of-directives-work)
5. [Running Generators — Commands & Flags](#running-generators--commands--flags)
6. [Riverpod Generator (`riverpod_generator`)](#riverpod-generator-riverpod_generator)
7. [Freezed (`freezed`)](#freezed-freezed)
8. [JSON Serializable (`json_serializable`)](#json-serializable-json_serializable)
9. [Retrofit Generator (`retrofit_generator`)](#retrofit-generator-retrofit_generator)
10. [Drift (`drift_dev`)](#drift-drift_dev)
11. [Slang (`slang_build_runner`)](#slang-slang_build_runner)
12. [How Multiple Generators Coexist](#how-multiple-generators-coexist)
13. [Generated File Naming Conventions](#generated-file-naming-conventions)
14. [build.yaml Configuration](#buildyaml-configuration)
15. [Common Errors & Troubleshooting](#common-errors--troubleshooting)
16. [Rules & Best Practices](#rules--best-practices)
17. [Full Annotated Example From This Project](#full-annotated-example-from-this-project)

---

## Overview & Philosophy

This project uses `build_runner` as its central code-generation engine together
with the following generator packages:

| Generator Package    | Annotation Package           | Generates              | Purpose                                   |
| -------------------- | ---------------------------- | ---------------------- | ----------------------------------------- |
| `riverpod_generator` | `riverpod_annotation`        | `*.g.dart`             | Riverpod providers from annotated classes |
| `freezed`            | `freezed_annotation`         | `*.freezed.dart`       | Immutable data classes, unions, copyWith  |
| `json_serializable`  | `json_annotation`            | `*.g.dart`             | JSON fromJson/toJson boilerplate          |
| `retrofit_generator` | `retrofit`                   | `*.g.dart`             | Dio-based REST client from abstract class |
| `drift_dev`          | `drift`                      | `*.g.dart`             | Type-safe SQLite database layer           |
| `slang_build_runner` | (reads JSON/YAML i18n files) | `lib/core/i18n/*.dart` | Type-safe internationalization strings    |

**Why code generation?**
Dart does not have runtime reflection like Java. Code generation at compile time
lets us get the same benefits — automatic serialization, exhaustive pattern
matching, boilerplate-free providers — while keeping the app tree-shakable,
AOT-compiled, and fast.

---

## What Is Code Generation in Dart/Flutter?

Code generation is the process of having a **builder** program read your source
code annotations, analyze them, and emit new Dart source files **before** you
compile your Flutter app. The process is:

```
┌────────────────────┐
│ You write:         │
│  @riverpod         │
│  @freezed          │
│  @JsonSerializable │
│  @RestApi          │
│  @DriftDatabase    │
└────────┬───────────┘
         │ (annotations trigger builders)
         ▼
┌────────────────────┐
│ build_runner reads │
│ your .dart files,  │
│ finds annotations, │
│ invokes matching   │
│ generators         │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│ Generators emit    │
│ new .dart files:   │
│  *.g.dart          │
│  *.freezed.dart    │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│ Dart compiler      │
│ compiles everything│
│ (your code +       │
│  generated code)   │
└────────────────────┘
```

**Key mental model**: You NEVER edit generated files. They are output artifacts.
If you need to change the generated code, you change the annotated source file
and re-run the generator.

---

## The build_runner Engine

### What Is build_runner?

`build_runner` is a Dart package from the Dart team that provides a unified CLI
for running **builders**. A builder is a Dart class that:

1. Reads input files (your `.dart` sources).
2. Uses the `analyzer` package to understand annotations.
3. Writes output files (`.g.dart`, `.freezed.dart`, etc.).

### How build_runner Discovers Builders

When you run `dart run build_runner build`, the engine:

1. Reads every package's `build.yaml` file (or uses defaults).
2. Collects all builders declared by your dependencies.
3. For each builder, it scans globs (e.g., `lib/**/*.dart`) for inputs.
4. Runs builders in **phases** — outputs of one builder become inputs for the next.
5. Writes final files.

### Incremental Builds

`build_runner` caches analysis results in the `.dart_tool/build/` directory.
When you run `build` or `watch`, only files that changed (or whose dependencies
changed) are re-analyzed. This makes subsequent runs much faster than the first.

### Build Phases & Ordering

Builders run in a topologically sorted order. For example:

1. `freezed` runs first → emits `*.freezed.dart` (creates `copyWith`, unions).
2. `json_serializable` runs next → reads the freezed output + your annotations → emits `toJson`/`fromJson` in `*.g.dart`.
3. `riverpod_generator` runs → emits provider declarations in `*.g.dart`.
4. `retrofit_generator` runs → emits Dio client code in `*.g.dart`.

Multiple generators can write to the **same** `.g.dart` file. `build_runner`
aggregates their output using the `SharedPartBuilder` mechanism.

---

## How Dart `part` / `part of` Directives Work

### The `part` Directive

```dart
// file: auth_providers.dart
part 'auth_providers.g.dart';        // ← Declares that auth_providers.g.dart is part of this library
```

This tells the Dart analyzer: "The file `auth_providers.g.dart` is part of the
same library as `auth_providers.dart`." The generated file has **full access** to
private members of the host file, and vice versa.

### The Generated File's Header

The generated file automatically contains:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'auth_providers.dart';       // ← Points back to the host file
```

### Why This Matters

- The generated code can reference `_$AuthController`, `_$ExampleModel`, etc.
  These are private classes that only exist because of the `part` relationship.
- If you forget the `part` directive, the build will fail with:
  `"Could not generate part file for auth_providers.dart. No part directive found."`

### Rules for `part`

| Rule                               | Explanation                                                |
| ---------------------------------- | ---------------------------------------------------------- |
| One library per file               | A `.dart` file is one library. `part` files extend it.     |
| `part` goes AFTER imports          | Always place `part` directives below all imports.          |
| Never use `part of` in your code   | Only generated files use `part of`.                        |
| Each generator has its own `part`  | Freezed → `*.freezed.dart`, others → `*.g.dart`.           |
| You can have multiple `part` lines | e.g., both `part 'x.freezed.dart';` and `part 'x.g.dart';` |

---

## Running Generators — Commands & Flags

### Primary Commands

```sh
# One-time full build — deletes and regenerates all conflicting outputs
dart run build_runner build --delete-conflicting-outputs

# Watch mode — auto-rebuilds when you save a file
dart run build_runner watch --delete-conflicting-outputs

# Clean — deletes all cached build artifacts
dart run build_runner clean
```

### Important Flags

| Flag                           | Effect                                                                                                                                                                  |
| ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--delete-conflicting-outputs` | Required. Deletes stale generated files that conflict with new output. Without this, build_runner may fail if a `.g.dart` was generated by a different builder version. |
| `--verbose`                    | Prints detailed logs including which builders ran and timing.                                                                                                           |
| `--output <dir>`               | Writes build output to a separate directory instead of in-place. Rarely used for Flutter.                                                                               |
| `--fail-on-severe`             | Exits with non-zero code on severe issues. Useful in CI.                                                                                                                |
| `--low-resources-mode`         | Uses less memory at the cost of speed. Useful on CI runners with limited RAM.                                                                                           |

### Performance Tips

| Tip                                | Explanation                        |
| ---------------------------------- | ---------------------------------- |
| Use `watch` during dev             | Avoids repeated cold starts.       |
| Limit glob scope in `build.yaml`   | Reduces files scanned.             |
| Run `clean` if builds are broken   | Stale cache causes phantom errors. |
| Split large projects into packages | Each package builds independently. |

### Slang-Specific Command

Slang has its own optimized CLI that is faster than going through build_runner:

```sh
dart run slang
```

Translation source files: `assets/i18n/`
Generated output: `lib/core/i18n/`

---

## Riverpod Generator (`riverpod_generator`)

### What It Does

`riverpod_generator` reads `@riverpod` and `@Riverpod(...)` annotations and
generates strongly-typed provider declarations so you don't have to write them
manually. It eliminates the verbose `Provider`, `StateNotifierProvider`,
`AsyncNotifierProvider` declarations.

### Packages Required

```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^2.6.1 # Core Riverpod for Flutter
  riverpod_annotation: ^2.6.1 # Annotations: @riverpod, @Riverpod(...)

dev_dependencies:
  riverpod_generator: ^2.6.3 # The build_runner generator
  build_runner: ^2.4.14 # The engine that runs generators
```

### Two Kinds of Providers

#### 1. Functional Providers (Simple / Computed Values)

```dart
// A simple provider that computes a value from other providers
@riverpod
User? currentUser(Ref ref) {                  // ← Top-level function
  final authState = ref.watch(authControllerProvider);
  return switch (authState) {
    Authenticated(:final user) => user,
    _ => null,
  };
}
```

**Generated output** (in `*.g.dart`):

```dart
final currentUserProvider = AutoDisposeProvider<User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  ...
);
```

**Naming rule**: The function name `currentUser` becomes `currentUserProvider`
(appends `Provider`).

#### 2. Class-Based (Notifier) Providers — Mutable State

```dart
@riverpod
class AuthController extends _$AuthController {  // ← Must extend _$ClassName
  @override
  AuthState build() {                             // ← build() returns initial state
    return const AuthState.unauthenticated();
  }

  Future<void> login(...) async { ... }          // ← Methods mutate `state`
  Future<void> logout() async { ... }
}
```

**Generated output** (in `*.g.dart`):

```dart
final authControllerProvider =
    AutoDisposeNotifierProvider<AuthController, AuthState>.internal(
      AuthController.new,
      name: r'authControllerProvider',
      ...
    );

typedef _$AuthController = AutoDisposeNotifier<AuthState>;
```

**Naming rule**: The class `AuthController` becomes `authControllerProvider`
(camelCase + `Provider`).

### `@Riverpod(...)` — Custom Configuration

```dart
@Riverpod(keepAlive: true)        // ← Keeps provider alive even without listeners
class AuthController extends _$AuthController {
  // ...
}
```

| Parameter      | Default | Effect                                                                                                                    |
| -------------- | ------- | ------------------------------------------------------------------------------------------------------------------------- |
| `keepAlive`    | `false` | `false` → `AutoDispose` provider (disposed when no listener). `true` → never auto-disposed; lives for the app's lifetime. |
| `dependencies` | `null`  | Explicitly lists providers this one depends on. Used for scoped providers.                                                |

### Async Providers

```dart
@riverpod
Future<List<Order>> orders(Ref ref) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getAll();
}
```

This generates an `AutoDisposeFutureProvider<List<Order>>`. In the UI you
consume it with:

```dart
final asyncOrders = ref.watch(ordersProvider);
asyncOrders.when(
  data: (orders) => ListView(...),
  loading: () => CircularProgressIndicator(),
  error: (e, st) => Text('Error: $e'),
);
```

### Stream Providers

```dart
@riverpod
Stream<int> counter(Ref ref) {
  return Stream.periodic(Duration(seconds: 1), (i) => i);
}
```

Generates `AutoDisposeStreamProvider<int>`.

### How `ref` Works in Generated Providers

| Method                           | When to Use                          | Behavior                                                      |
| -------------------------------- | ------------------------------------ | ------------------------------------------------------------- |
| `ref.watch(provider)`            | In `build()` or functional providers | Rebuilds this provider when the watched provider changes.     |
| `ref.read(provider)`             | In methods (login, logout, etc.)     | Reads the current value once. Does NOT create a subscription. |
| `ref.listen(provider, callback)` | When you need side effects on change | Calls callback on every change.                               |
| `ref.invalidateSelf()`           | Force re-computation                 | Causes `build()` to re-execute.                               |

### Family Providers (Parameterized)

```dart
@riverpod
Future<Order> orderById(Ref ref, String orderId) async {
  final repo = ref.watch(orderRepositoryProvider);
  return repo.getById(orderId);
}
```

Generated: `orderByIdProvider(orderId)` — a **family** that creates a separate
provider instance for each unique `orderId`.

### Project Example — auth_providers.dart

This project's actual code in `lib/core/auth/auth_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:testing_state_managment_riverpod/core/auth/auth_state.dart';
import 'package:testing_state_managment_riverpod/core/auth/user.dart';

part 'auth_providers.g.dart';   // ← REQUIRED: tells build_runner where to write

@riverpod
class AuthController extends _$AuthController {    // ← _$AuthController is generated
  @override
  AuthState build() {
    return const AuthState.unauthenticated();       // ← Initial state
  }

  Future<void> login(String accessToken, String refreshToken, User user) async {
    state = const AuthState.loading();              // ← `state` setter is inherited
    await Future.delayed(const Duration(seconds: 2));
    state = AuthState.authenticated(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> logout() async {
    state = const AuthState.unauthenticated();
  }
}

@riverpod
User? currentUser(Ref ref) {
  final authstate = ref.watch(authControllerProvider);
  return switch (authstate) {
    Authenticated(:final user) => user,
    _ => null,
  };
}

@riverpod
String? authToken(Ref ref) {
  final authstate = ref.watch(authControllerProvider);
  return switch (authstate) {
    Authenticated(:final accessToken) => accessToken,
    _ => null,
  };
}
```

The generated `auth_providers.g.dart` contains:

- `currentUserProvider` — `AutoDisposeProvider<User?>`
- `authTokenProvider` — `AutoDisposeProvider<String?>`
- `authControllerProvider` — `AutoDisposeNotifierProvider<AuthController, AuthState>`
- `typedef _$AuthController = AutoDisposeNotifier<AuthState>`

### Consuming Providers in UI

```dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // WATCH: rebuilds widget when authState changes
    final authState = ref.watch(authControllerProvider);

    // READ (in callbacks): read current value without subscribing
    ref.read(authControllerProvider.notifier).login(...);
  }
}
```

| Widget Base Class        | Access to ref                                       |
| ------------------------ | --------------------------------------------------- |
| `ConsumerWidget`         | `ref` is a parameter of `build()`                   |
| `ConsumerStatefulWidget` | `ref` is available as `this.ref` in `ConsumerState` |
| `HookConsumerWidget`     | Combines `flutter_hooks` + Riverpod                 |

---

## Freezed (`freezed`)

### What It Does

Freezed generates **immutable data classes** with:

- `copyWith` (deep copy with selective field override)
- `==` and `hashCode` (value equality)
- `toString`
- Sealed union types with pattern matching
- Optional JSON serialization (when combined with `json_serializable`)

### Packages Required

```yaml
dependencies:
  freezed_annotation: ^2.4.1

dev_dependencies:
  freezed: ^2.4.7
  json_serializable: ^6.7.1 # Only if you need JSON support
  build_runner: ^2.4.14
```

### Basic Freezed Class

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';         // ← For copyWith, ==, hashCode, toString
part 'user.g.dart';               // ← For JSON (only if fromJson factory exists)

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    @Default('') String email,    // ← Default value annotation
    int? age,                     // ← Nullable = optional
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

### What Gets Generated

| Generated Artifact          | File                | Purpose                                        |
| --------------------------- | ------------------- | ---------------------------------------------- |
| `_$User` mixin              | `user.freezed.dart` | `copyWith`, `==`, `hashCode`, `toString`       |
| `_User` class               | `user.freezed.dart` | Private implementation class                   |
| `_$UserFromJson`            | `user.g.dart`       | JSON deserialization (via `json_serializable`) |
| `_$UserToJson` → `toJson()` | `user.g.dart`       | JSON serialization                             |

### Freezed Unions (Sealed Classes)

This is the most powerful Freezed feature. The current project uses a
**hand-written** sealed class for `AuthState`. With Freezed it would be:

```dart
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.authenticated({
    required User user,
    required String accessToken,
    required String refreshToken,
  }) = Authenticated;

  const factory AuthState.unauthenticated() = Unauthenticated;
  const factory AuthState.loading() = AuthLoading;
}
```

**What Freezed generates for unions:**

- A `when()` method for exhaustive matching.
- A `maybeWhen()` with an `orElse` fallback.
- A `map()` and `maybeMap()` for type-based mapping.
- `copyWith` on each variant.
- Full `==`, `hashCode`, `toString` on each variant.

**Usage in Dart 3+ (pattern matching):**

```dart
final result = switch (authState) {
  Authenticated(:final user) => 'Hello ${user.name}',
  Unauthenticated()          => 'Please login',
  AuthLoading()              => 'Loading...',
};
```

### Freezed with Custom Methods / Getters

To add custom methods, add a private constructor:

```dart
@freezed
class Temperature with _$Temperature {
  const Temperature._();                    // ← Enables custom members

  const factory Temperature.celsius(double value) = _Celsius;
  const factory Temperature.fahrenheit(double value) = _Fahrenheit;

  double get asCelsius => switch (this) {
    _Celsius(:final value) => value,
    _Fahrenheit(:final value) => (value - 32) * 5 / 9,
  };
}
```

### JSON Customization with Freezed

```dart
@freezed
class ApiResponse with _$ApiResponse {
  const factory ApiResponse({
    @JsonKey(name: 'status_code') required int statusCode,   // Rename field
    @JsonKey(defaultValue: []) required List<String> items,  // Default
    @JsonKey(includeFromJson: false) String? localOnly,      // Skip in JSON
  }) = _ApiResponse;

  factory ApiResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseFromJson(json);
}
```

---

## JSON Serializable (`json_serializable`)

### What It Does

Generates `fromJson` and `toJson` methods for Dart classes annotated with
`@JsonSerializable()`.

### Packages Required

```yaml
dependencies:
  json_annotation: ^4.8.1

dev_dependencies:
  json_serializable: ^6.7.1
  build_runner: ^2.4.14
```

### Standalone Usage (Without Freezed)

```dart
import 'package:json_annotation/json_annotation.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  final String id;
  final double total;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Order({required this.id, required this.total, required this.createdAt});

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}
```

### Key Annotations

| Annotation                           | Purpose                            | Example                        |
| ------------------------------------ | ---------------------------------- | ------------------------------ |
| `@JsonSerializable()`                | Marks class for generation         | `@JsonSerializable()`          |
| `@JsonKey(name: 'x')`                | Maps Dart field to JSON key        | `@JsonKey(name: 'created_at')` |
| `@JsonKey(defaultValue: x)`          | Default when JSON key is missing   | `@JsonKey(defaultValue: 0)`    |
| `@JsonKey(includeFromJson: false)`   | Exclude from deserialization       | Computed fields                |
| `@JsonKey(includeToJson: false)`     | Exclude from serialization         | Local-only fields              |
| `@JsonKey(fromJson: fn, toJson: fn)` | Custom converter functions         | Date transforms                |
| `@JsonEnum(valueField: 'code')`      | Serialize enum by a specific field | API enum mapping               |

### Generic Classes

```dart
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final T data;
  final String message;

  ApiResponse({required this.data, required this.message});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);
}
```

### build.yaml Defaults for json_serializable

```yaml
targets:
  $default:
    builders:
      json_serializable:
        options:
          explicit_to_json: true # Nested objects call toJson()
          field_rename: snake # Auto snake_case <-> camelCase
          include_if_null: false # Omit null fields from JSON
```

---

## Retrofit Generator (`retrofit_generator`)

### What It Does

Generates a Dio-based HTTP client implementation from an abstract class
annotated with `@RestApi()`. You declare endpoints as abstract methods
with HTTP annotations (`@GET`, `@POST`, etc.) and Retrofit generates the
implementation.

### Packages Required

```yaml
dependencies:
  retrofit: ^4.1.0
  dio: ^5.4.3

dev_dependencies:
  retrofit_generator: ^8.1.0
  json_serializable: ^6.7.1 # Retrofit uses json_serializable for models
  build_runner: ^2.4.14
```

### Declaring an API Service

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api_service.g.dart';

@RestApi()
abstract class AuthApiService {
  factory AuthApiService(Dio dio, {String? baseUrl}) = _AuthApiService;

  @POST('/auth/login')
  Future<LoginResponseDto> login(@Body() LoginRequestDto request);

  @POST('/auth/refresh')
  Future<TokensDto> refreshToken(@Body() RefreshTokenRequest request);

  @GET('/auth/me')
  Future<UserDto> me();

  @DELETE('/auth/logout')
  Future<void> logout();
}
```

### HTTP Method Annotations

| Annotation         | HTTP Method | Example                   |
| ------------------ | ----------- | ------------------------- |
| `@GET('/path')`    | GET         | `@GET('/orders')`         |
| `@POST('/path')`   | POST        | `@POST('/orders')`        |
| `@PUT('/path')`    | PUT         | `@PUT('/orders/{id}')`    |
| `@PATCH('/path')`  | PATCH       | `@PATCH('/orders/{id}')`  |
| `@DELETE('/path')` | DELETE      | `@DELETE('/orders/{id}')` |

### Parameter Annotations

| Annotation        | Purpose             | Example                                             |
| ----------------- | ------------------- | --------------------------------------------------- |
| `@Path('id')`     | URL path segment    | `Future<Order> get(@Path('id') String orderId)`     |
| `@Query('key')`   | Query parameter     | `Future<List<Order>> list(@Query('page') int page)` |
| `@Queries()`      | Map of query params | `@Queries() Map<String, dynamic> filters`           |
| `@Body()`         | Request body (JSON) | `@Body() CreateOrderDto dto`                        |
| `@Header('key')`  | Single header       | `@Header('X-Custom') String value`                  |
| `@Headers({...})` | Static headers      | `@Headers({'Accept': 'application/json'})`          |
| `@Field('key')`   | Form field          | `@Field('email') String email`                      |
| `@Part()`         | Multipart file      | `@Part() File image`                                |

### Connecting Retrofit to Riverpod

```dart
@riverpod
AuthApiService authApiService(Ref ref) {
  final dio = ref.watch(dioProvider);
  return AuthApiService(dio);
}
```

---

## Drift (`drift_dev`)

### What It Does

Drift (formerly Moor) generates a type-safe, reactive SQLite database layer.
You define tables as Dart classes, write queries, and Drift generates
the SQL and Dart code.

### Packages Required

```yaml
dependencies:
  drift: ^2.15.0
  sqlite3_flutter_libs: ^0.5.0 # SQLite binary for mobile
  path_provider: ^2.0.0
  path: ^1.8.0

dev_dependencies:
  drift_dev: ^2.15.0
  build_runner: ^2.4.14
```

### Defining Tables

```dart
import 'package:drift/drift.dart';

class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  RealColumn get total => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}
```

### Database Declaration

```dart
import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Orders, Users])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}
```

### Generated Output

Drift generates in `app_database.g.dart`:

- `Order` data class (matching table row)
- `OrdersCompanion` (for inserts/updates)
- `$OrdersTable` (table metadata)
- Type-safe select, insert, update, delete methods

---

## Slang (`slang_build_runner`)

### What It Does

Slang generates type-safe i18n (internationalization) strings from JSON or YAML
translation files. Instead of `AppLocalizations.of(context).hello`, you get
`t.hello` with full autocomplete.

### Source Files

Translation JSON files live in: `assets/i18n/`

```
assets/i18n/
├── strings_en.i18n.json        # English (base)
├── strings_ar.i18n.json        # Arabic
└── strings_fr.i18n.json        # French
```

### Generated Output

Goes to: `lib/core/i18n/`

### Running Slang

Use the standalone CLI for faster regeneration:

```sh
dart run slang
```

Or through build_runner (slower but integrated):

```sh
dart run build_runner build --delete-conflicting-outputs
```

### Usage in Code

```dart
import 'package:your_app/core/i18n/strings.g.dart';

// Access translations
Text(t.auth.loginButton)         // Type-safe, auto-completed
Text(t.orders.itemCount(n: 5))   // Pluralization

// Change locale
LocaleSettings.setLocale(AppLocale.ar);
```

---

## How Multiple Generators Coexist

### The SharedPartBuilder Mechanism

When multiple generators need to write to the same `*.g.dart` file (e.g.,
`json_serializable` AND `riverpod_generator` for the same source file),
they use `SharedPartBuilder`. Each generator writes a **section** inside
the `.g.dart` file, separated by comment markers:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MyModel _$MyModelFromJson(Map<String, dynamic> json) => ...

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

final myModelProvider = ...
```

### Freezed Gets Its Own File

Freezed uses `PartBuilder` (not `SharedPartBuilder`), so it writes
to `*.freezed.dart` — a **separate** file. This is why Freezed-annotated
classes need **two** `part` directives:

```dart
part 'my_model.freezed.dart';   // ← Freezed output
part 'my_model.g.dart';         // ← json_serializable + riverpod output
```

### Resolution Order

```
1. freezed           → *.freezed.dart    (creates classes)
2. json_serializable → *.g.dart          (reads freezed output, writes JSON methods)
3. riverpod_generator → *.g.dart         (generates provider wrappers)
4. retrofit_generator → *.g.dart         (generates Dio client)
5. drift_dev         → *.g.dart          (generates DB layer)
```

---

## Generated File Naming Conventions

| Source File             | Generated File(s)                           | Generator                       |
| ----------------------- | ------------------------------------------- | ------------------------------- |
| `auth_providers.dart`   | `auth_providers.g.dart`                     | `riverpod_generator`            |
| `auth_state.dart`       | `auth_state.freezed.dart`                   | `freezed`                       |
| `user_dto.dart`         | `user_dto.g.dart` + `user_dto.freezed.dart` | `json_serializable` + `freezed` |
| `auth_api_service.dart` | `auth_api_service.g.dart`                   | `retrofit_generator`            |
| `app_database.dart`     | `app_database.g.dart`                       | `drift_dev`                     |

**Pattern**: `<source_name>.g.dart` for most generators, `<source_name>.freezed.dart` for Freezed.

---

## build.yaml Configuration

Create `build.yaml` at the project root to customize generator behavior:

```yaml
targets:
  $default:
    builders:
      # json_serializable settings
      json_serializable:
        options:
          explicit_to_json: true
          field_rename: snake
          include_if_null: false
          checked: true

      # freezed settings
      freezed:
        options:
          # Make all freezed classes immutable by default
          immutable: true
          # Add to_string: true / false
          to_string: true
          # equal: true / false
          equal: true

      # Limit which files each builder processes
      source_gen|combining_builder:
        options:
          ignore_for_file:
            - type=lint
            - subtype_of_sealed_class
```

---

## Common Errors & Troubleshooting

### 1. "Could not generate part file — No part directive found"

**Cause**: You annotated a class with `@riverpod` / `@freezed` but forgot `part`
directive.

**Fix**: Add the correct `part` line:

```dart
part 'my_file.g.dart';           // For riverpod, json_serializable, retrofit, drift
part 'my_file.freezed.dart';     // For freezed
```

### 2. "The name '\_$ClassName' isn't defined"

**Cause**: Generated file doesn't exist yet or is outdated.

**Fix**: Run `dart run build_runner build --delete-conflicting-outputs`.

### 3. "Conflicting outputs"

**Cause**: A previously generated file was created by a different builder
version.

**Fix**: Always use `--delete-conflicting-outputs` flag.

### 4. "type 'Null' is not a subtype of type 'String'"

**Cause**: JSON field is null but the Dart field is non-nullable and has no
default.

**Fix**: Either make the field nullable (`String?`) or add `@Default('')`.

### 5. Build takes forever

**Cause**: Too many files being scanned.

**Fix**:

- Use `watch` mode instead of repeated `build`.
- Add glob filters in `build.yaml`.
- Split into packages.
- Run `dart run build_runner clean` to clear stale cache.

### 6. "Stack Overflow" during build

**Cause**: Circular dependencies between generated files.

**Fix**: Break the circular import. Ensure models don't import providers that
import models.

### 7. Changes not reflected after build

**Cause**: Stale cache.

**Fix**:

```sh
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### 8. "Part of directive points to non-existent file"

**Cause**: The source file was renamed but the `part` directive still references
the old name.

**Fix**: Update the `part` directive to match the new filename.

---

## Rules & Best Practices

### Must Do

- **DO** use `part` files for generated code, never `part of`.
- **DO** commit generated files (`*.g.dart`, `*.freezed.dart`) to version control.
- **DO** run `dart run build_runner build --delete-conflicting-outputs` after
  modifying any annotated class.
- **DO** add `*.g.dart` and `*.freezed.dart` to your IDE's file nesting rules
  so they collapse under the source file.
- **DO** use `@Riverpod(keepAlive: true)` for providers that must survive
  the entire app lifecycle (auth, theme, locale).
- **DO** prefer `AutoDispose` (default in riverpod_generator) for feature-level
  providers — they clean up when the screen is popped.
- **DO** use Freezed for all DTOs that cross serialization boundaries (API to Dart).
- **DO** use sealed classes / Freezed unions for state that has distinct variants.
- **DO** place `part` directives AFTER all imports.
- **DO** run `dart run build_runner clean` when switching branches with
  different model definitions.

### Must NOT Do

- **DO NOT** hand-edit generated files (`*.g.dart`, `*.freezed.dart`).
- **DO NOT** import a `.g.dart` or `.freezed.dart` file directly — they are
  automatically included via the `part` directive.
- **DO NOT** use both hand-written providers and generated providers for the
  same state — pick one approach per provider.
- **DO NOT** forget the `--delete-conflicting-outputs` flag.
- **DO NOT** reference `_$ClassName` in files other than the one declaring the
  class — it's private to that library.
- **DO NOT** put business logic inside generated files.
- **DO NOT** skip running generators in CI — add the build step to your CI
  pipeline or commit generated files.

---

## Full Annotated Example From This Project

### Step-by-Step: How `auth_providers.dart` Becomes a Working Provider

**Step 1 — You write the annotated source:**

```dart
// lib/core/auth/auth_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';     // For Ref
import 'package:riverpod_annotation/riverpod_annotation.dart'; // For @riverpod
import 'auth_state.dart';                                     // Your sealed class
import 'user.dart';                                           // Your model

part 'auth_providers.g.dart';     // CRITICAL: part directive for generated code

// --- CLASS-BASED NOTIFIER PROVIDER ---
// @riverpod tells riverpod_generator: "Generate a provider for this class."
// The class MUST extend _$AuthController (generated base class).
@riverpod
class AuthController extends _$AuthController {
  // build() is the initialization method.
  // Its return TYPE determines the provider's state type (AuthState).
  @override
  AuthState build() {
    return const AuthState.unauthenticated();
  }

  // Methods can mutate `state` (inherited from the generated base class).
  Future<void> login(String accessToken, String refreshToken, User user) async {
    state = const AuthState.loading();
    await Future.delayed(const Duration(seconds: 2));
    state = AuthState.authenticated(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> logout() async {
    state = const AuthState.unauthenticated();
  }
}

// --- FUNCTIONAL PROVIDER (Computed / Derived Value) ---
// Functional providers are simple functions annotated with @riverpod.
// They're ideal for derived/computed values.
@riverpod
User? currentUser(Ref ref) {
  final authstate = ref.watch(authControllerProvider);   // Watch = reactive
  return switch (authstate) {
    Authenticated(:final user) => user,
    _ => null,
  };
}

@riverpod
String? authToken(Ref ref) {
  final authstate = ref.watch(authControllerProvider);
  return switch (authstate) {
    Authenticated(:final accessToken) => accessToken,
    _ => null,
  };
}
```

**Step 2 — You run the generator:**

```sh
dart run build_runner build --delete-conflicting-outputs
```

**Step 3 — The generator produces `auth_providers.g.dart`:**

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'auth_providers.dart';

// RiverpodGenerator

// Hash strings for cache invalidation
String _$currentUserHash() => r'8f59c1d69c07e856d18533807cc369b8ef0ce0b1';

// Provider for the currentUser functional provider
final currentUserProvider = AutoDisposeProvider<User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

// Provider for the AuthController notifier
final authControllerProvider =
    AutoDisposeNotifierProvider<AuthController, AuthState>.internal(
      AuthController.new,
      name: r'authControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null : _$authControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

// The generated base class your AuthController extends
typedef _$AuthController = AutoDisposeNotifier<AuthState>;
```

**Step 4 — You use it in the UI:**

```dart
class LoginScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch -> subscribes to changes, rebuilds widget on state change
    final authState = ref.watch(authControllerProvider);

    // ref.read -> one-time read in callbacks (never rebuilds)
    // .notifier accesses the AuthController instance (to call methods)
    ref.read(authControllerProvider.notifier).login(...);

    // Derived provider — automatically updates when authState changes
    final user = ref.watch(currentUserProvider);
  }
}
```

### Flow Summary

```
You write @riverpod class -> run build_runner -> get *.g.dart
                                                     |
     +-----------------------------------------------+
     |
     +-- authControllerProvider  (notifier provider, holds AuthState)
     +-- currentUserProvider     (computed, derives User? from auth state)
     +-- authTokenProvider       (computed, derives String? from auth state)
                                                     |
     +-----------------------------------------------+
     |
     UI uses ref.watch(authControllerProvider) -> rebuilds on auth change
     Interceptor uses ref.read(authTokenProvider) -> reads token for HTTP header
```

---

## Appendix A: Annotation Cheat Sheet

| Annotation                      | Package               | What It Triggers                    |
| ------------------------------- | --------------------- | ----------------------------------- |
| `@riverpod`                     | `riverpod_annotation` | Provider code in `*.g.dart`         |
| `@Riverpod(keepAlive: true)`    | `riverpod_annotation` | Non-auto-dispose provider           |
| `@freezed`                      | `freezed_annotation`  | Immutable class in `*.freezed.dart` |
| `@unfreezed`                    | `freezed_annotation`  | Mutable freezed class               |
| `@JsonSerializable()`           | `json_annotation`     | JSON code in `*.g.dart`             |
| `@JsonKey(...)`                 | `json_annotation`     | Field-level JSON config             |
| `@RestApi()`                    | `retrofit`            | Dio client in `*.g.dart`            |
| `@GET` / `@POST` / ...          | `retrofit`            | HTTP method mapping                 |
| `@DriftDatabase(tables: [...])` | `drift`               | Database code in `*.g.dart`         |
| `@DataClassName('X')`           | `drift`               | Custom data class name              |

---

## Appendix B: Full Dependency Map for pubspec.yaml

```yaml
dependencies:
  # Riverpod
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # Freezed
  freezed_annotation: ^2.4.1

  # JSON
  json_annotation: ^4.8.1

  # Retrofit + Dio
  retrofit: ^4.1.0
  dio: ^5.4.3

  # Drift
  drift: ^2.15.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.0.0
  path: ^1.8.0

dev_dependencies:
  # Generators (all run via build_runner)
  build_runner: ^2.4.14
  riverpod_generator: ^2.6.3
  freezed: ^2.4.7
  json_serializable: ^6.7.1
  retrofit_generator: ^8.1.0
  drift_dev: ^2.15.0
```

---

## Appendix C: When to Use Which Generator (Decision Matrix)

| You Need                  | Use                         | Annotation                      | Example                         |
| ------------------------- | --------------------------- | ------------------------------- | ------------------------------- |
| Immutable data model      | Freezed                     | `@freezed`                      | User, Order, AuthState          |
| JSON serialization        | json_serializable           | `@JsonSerializable`             | DTOs from API                   |
| Both immutable + JSON     | Freezed + json_serializable | `@freezed` + `fromJson` factory | API response models             |
| State management provider | riverpod_generator          | `@riverpod`                     | AuthController, OrdersProvider  |
| REST API client           | Retrofit                    | `@RestApi`                      | AuthApiService, OrderApiService |
| Local database            | Drift                       | `@DriftDatabase`                | AppDatabase, OfflineCache       |
| Translations              | Slang                       | (JSON/YAML files)               | i18n strings                    |
| Mutable data model        | Freezed (unfreezed)         | `@unfreezed`                    | Form state, draft models        |

---

## Appendix D: CI Integration

Add this step to your CI pipeline to ensure generated files are up to date:

```yaml
# In .github/workflows/ci.yml
- name: Run code generation
  run: dart run build_runner build --delete-conflicting-outputs --fail-on-severe

- name: Check for uncommitted generated files
  run: |
    git diff --exit-code lib/
    if [ $? -ne 0 ]; then
      echo "Generated files are out of date. Run build_runner locally and commit."
      exit 1
    fi
```
