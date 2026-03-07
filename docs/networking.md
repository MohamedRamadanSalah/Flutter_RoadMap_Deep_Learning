# Networking

## Overview

HTTP is handled by Dio with Retrofit for type-safe API services.
One API service per feature slice where applicable.

## Dio Client

The Dio singleton is in `lib/core/network/dio_client.dart`, exposed as
`dioProvider`. It includes:

- Base URL from `String.fromEnvironment('API_BASE_URL')`
- 15s connect/receive timeouts
- `LogInterceptor` in debug mode only
- Auth token injection via interceptor

## Creating a Feature API Service

Use Retrofit to generate type-safe clients:

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'example_api.g.dart';

@RestApi()
abstract class ExampleApi {
  factory ExampleApi(Dio dio) = _ExampleApi;

  @GET('/examples')
  Future<List<ExampleDto>> getExamples();

  @POST('/examples')
  Future<ExampleDto> createExample(@Body() CreateExampleRequest request);
}
```

Expose it as a Riverpod provider in the feature slice:

```dart
final exampleApiProvider = Provider<ExampleApi>((ref) {
  return ExampleApi(ref.watch(dioProvider));
});
```

Run code generation after creating/modifying API services:

```sh
dart run build_runner build --delete-conflicting-outputs
```

## Rules

- **DO** use Retrofit for all API service definitions.
- **DO** place API services in `lib/features/<feature>/data/`.
- **DO NOT** use `Dio` directly in presentation or domain layers.
- **DO NOT** create multiple Dio instances — use interceptors for customization.
