# Authentication

## Overview

Auth is a **core concern**, not a feature slice. Auth state lives in `lib/core/auth/`
so every feature can reactively access the current user and token via Riverpod.

## Architecture

```
lib/core/auth/
├── auth_providers.dart       # AuthController, currentUserProvider, tokenProvider
├── auth_providers.g.dart     # Generated
├── auth_state.dart           # AuthState sealed class (Freezed)
├── auth_state.freezed.dart   # Generated
└── user.dart                 # Minimal User entity
```

The **auth feature slice** (`lib/features/auth/`) owns login/logout screens,
the auth API service, and the auth repository. The core module owns only the
reactive state that other features consume.

```
lib/features/auth/
├── auth.dart                 # Barrel file
├── providers.dart            # authRepositoryProvider, authApiServiceProvider
├── presentation/
│   ├── routes.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   └── otp_screen.dart
│   └── controllers/
│       ├── login_controller.dart
│       └── login_controller.g.dart
├── domain/
│   ├── entities/
│   │   └── auth_tokens.dart
│   └── repositories/
│       └── auth_repository.dart
└── data/
    ├── repositories/
    │   └── auth_repository_impl.dart
    ├── data_sources/remote/
    │   ├── auth_api_service.dart
    │   └── auth_api_service.g.dart
    └── models/
        ├── auth_tokens_dto.dart
        └── login_request_dto.dart
```

## Auth State

Use a sealed class for exhaustive handling:

```dart
// lib/core/auth/auth_state.dart
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

## Auth Controller (Core)

```dart
// lib/core/auth/auth_providers.dart
@riverpod
class AuthController extends _$AuthController {
  @override
  AuthState build() {
    // Check persisted token on startup
    final storage = ref.watch(localStorageProvider);
    final token = storage.token;
    if (token != null) {
      // Validate token, fetch user, return Authenticated
      // On failure, return Unauthenticated
    }
    return const AuthState.unauthenticated();
  }

  Future<void> login(String accessToken, String refreshToken, User user) async {
    state = const AuthState.loading();
    await ref.read(localStorageProvider).setToken(accessToken);
    state = AuthState.authenticated(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> logout() async {
    await ref.read(localStorageProvider).removeToken();
    state = const AuthState.unauthenticated();
  }
}

/// Convenience provider — null when not authenticated.
@riverpod
User? currentUser(Ref ref) {
  final authState = ref.watch(authControllerProvider);
  return switch (authState) {
    Authenticated(:final user) => user,
    _ => null,
  };
}

/// Current access token — used by Dio interceptor.
@riverpod
String? authToken(Ref ref) {
  final authState = ref.watch(authControllerProvider);
  return switch (authState) {
    Authenticated(:final accessToken) => accessToken,
    _ => null,
  };
}
```

## Token Refresh Strategy

Token refresh is handled in a **Dio interceptor**, not in the auth controller:

```dart
// lib/core/network/auth_interceptor.dart
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._ref);

  final Ref _ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _ref.read(authTokenProvider);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Attempt refresh
      final refreshed = await _tryRefresh();
      if (refreshed) {
        // Retry original request with new token
        final retryResponse = await _retry(err.requestOptions);
        return handler.resolve(retryResponse);
      }
      // Refresh failed — force logout
      _ref.read(authControllerProvider.notifier).logout();
    }
    handler.next(err);
  }
}
```

Key points:
- Use `QueuedInterceptor` (not `Interceptor`) to serialize concurrent 401
  retries — only one refresh happens at a time.
- On refresh failure, call `logout()` which resets `AuthState` to
  `Unauthenticated`, triggering the router guard.

## Router Auth Guard

```dart
// lib/core/router/app_router.dart
@riverpod
GoRouter router(Ref ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    redirect: (context, state) {
      final isAuth = authState is Authenticated;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuth && !isAuthRoute) return '/auth/login';
      if (isAuth && isAuthRoute) return '/';
      return null;
    },
    routes: [
      ...authRoutes,
      ...orderRoutes,
      // ... other feature routes
    ],
  );
}
```

When `authControllerProvider` changes, GoRouter rebuilds its redirect and
navigates automatically — no manual `context.go()` needed.

## Token Storage

Tokens are stored via `LocalStorage` (SharedPreferences wrapper):

```dart
final storage = ref.read(localStorageProvider);
await storage.setToken(accessToken);        // Persist
final token = storage.token;                // Read
await storage.removeToken();                // Clear on logout
```

For sensitive tokens, consider migrating to `flutter_secure_storage` (requires
constitution approval). SharedPreferences is acceptable for MVP if the token
is a short-lived JWT.

## Rules

- **DO** place auth state in `core/auth/`, not inside a feature slice.
- **DO** use `QueuedInterceptor` for token refresh to prevent race conditions.
- **DO** use `ref.watch(currentUserProvider)` in features that need the user.
- **DO** guard routes via GoRouter `redirect`, not per-screen checks.
- **DO NOT** store long-lived secrets in SharedPreferences without encryption.
- **DO NOT** call auth API directly from controllers — go through the repository.
- **DO NOT** import `features/auth/` internals from other features — use core providers.
