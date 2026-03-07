# Error Handling

## Overview

Errors are caught at clearly defined boundaries — Dio interceptors for network
errors, repositories for data-layer failures, and controllers for
presentation-layer error states. No global try-catch wrappers.

## Architecture

```
Network Error (Dio)
  → DioException
    → Interceptor maps to AppException
      → Repository catches and returns Result/throws
        → Controller exposes AsyncValue.error
          → Screen shows error UI
```

## Error Types

Define a sealed class for typed error handling:

```dart
// lib/core/network/app_exception.dart
@freezed
sealed class AppException with _$AppException implements Exception {
  /// No internet or server unreachable.
  const factory AppException.network({String? message}) = NetworkException;

  /// Server returned an error response (4xx, 5xx).
  const factory AppException.server({
    required int statusCode,
    String? message,
  }) = ServerException;

  /// 401 — token expired or invalid.
  const factory AppException.unauthorized() = UnauthorizedException;

  /// Request-level validation error from the API.
  const factory AppException.validation({
    required Map<String, List<String>> fieldErrors,
  }) = ValidationException;

  /// Catch-all for unexpected errors.
  const factory AppException.unknown({String? message}) = UnknownException;
}
```

## Dio Error Interceptor

Map `DioException` to `AppException` in a Dio interceptor:

```dart
// lib/core/network/error_interceptor.dart
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final exception = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        const AppException.network(message: 'Connection timed out'),

      DioExceptionType.badResponse => _mapResponse(err.response!),

      _ => AppException.unknown(message: err.message),
    };

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        response: err.response,
        type: err.type,
      ),
    );
  }

  AppException _mapResponse(Response response) {
    return switch (response.statusCode) {
      401 => const AppException.unauthorized(),
      422 => AppException.validation(
          fieldErrors: _parseValidationErrors(response.data),
        ),
      >= 400 && < 500 => AppException.server(
          statusCode: response.statusCode!,
          message: response.data?['message']?.toString(),
        ),
      >= 500 => AppException.server(
          statusCode: response.statusCode!,
          message: 'Server error',
        ),
      _ => AppException.unknown(message: 'Unexpected status ${response.statusCode}'),
    };
  }
}
```

Register the interceptor in `dio_client.dart`:

```dart
dio.interceptors.addAll([
  ErrorInterceptor(),
  AuthInterceptor(ref),
  if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
]);
```

Order matters: `ErrorInterceptor` first, `AuthInterceptor` second (so 401
handling sees `AppException.unauthorized`).

## Repository Error Handling

Repositories catch and either re-throw typed exceptions or return fallback data:

```dart
@override
Future<List<Order>> getOrders() async {
  try {
    final dtos = await apiService.getOrders();
    await _cacheLocally(dtos);
    return dtos.map((d) => d.toEntity()).toList();
  } on DioException catch (e) {
    if (e.error is NetworkException) {
      // Fallback to cache
      return _getFromCache();
    }
    rethrow; // Let controller handle other errors
  }
}
```

## Controller Error States

Controllers use `AsyncNotifier` — errors are handled by `AsyncValue`:

```dart
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
}
```

`AsyncValue.guard` automatically catches exceptions and wraps them in
`AsyncValue.error`.

## Screen Error UI

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final ordersAsync = ref.watch(orderListControllerProvider);

  return ordersAsync.when(
    data: (orders) => OrderListView(orders: orders),
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stack) => _ErrorView(
      error: error,
      onRetry: () => ref.invalidate(orderListControllerProvider),
    ),
  );
}
```

### User-Facing Error Messages

Map `AppException` to user-facing strings via i18n:

```dart
// lib/shared/extensions/app_exception_ext.dart
extension AppExceptionMessage on Object {
  String toUserMessage() {
    return switch (this) {
      NetworkException() => t.errors.network,
      ServerException(:final statusCode) when statusCode >= 500 =>
        t.errors.serverError,
      UnauthorizedException() => t.errors.sessionExpired,
      ValidationException() => t.errors.validationFailed,
      _ => t.errors.unknown,
    };
  }
}
```

## Form Validation Errors

For API validation errors (422), map field errors to form fields:

```dart
final state = ref.watch(loginControllerProvider);
if (state case AsyncError(:final error)) {
  if (error is ValidationException) {
    final emailErrors = error.fieldErrors['email'];
    // Show under the email field
  }
}
```

## Logging

Use Dart's `developer.log` in debug mode:

```dart
import 'dart:developer' as dev;

void logError(String tag, Object error, [StackTrace? stack]) {
  dev.log(
    error.toString(),
    name: tag,
    error: error,
    stackTrace: stack,
  );
}
```

For production crash reporting, integrate Firebase Crashlytics (requires
constitution approval and adding the `firebase_crashlytics` dependency).

## Rules

- **DO** use `AppException` sealed class for all typed errors.
- **DO** map `DioException` to `AppException` in the interceptor.
- **DO** use `AsyncValue.guard()` in controllers for consistent error wrapping.
- **DO** show user-facing error messages via i18n, not raw exception messages.
- **DO** provide retry actions on error screens.
- **DO NOT** catch and swallow errors silently.
- **DO NOT** show stack traces or technical details to users.
- **DO NOT** use `try-catch` in widgets — let `AsyncValue.error` handle display.
- **DO NOT** log sensitive data (tokens, passwords, PII).
