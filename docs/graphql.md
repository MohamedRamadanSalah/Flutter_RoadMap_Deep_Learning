# GraphQL

## Overview

The app uses GraphQL for **read operations** (queries). Write operations
use REST via Dio + Retrofit. The backend is .NET 8 with HotChocolate
(code-first GraphQL), so enum values are **PascalCase**, not
SCREAMING_SNAKE_CASE.

### Stack

| Concern | Package |
|---------|---------|
| Client | `graphql` (v5.2.3) |
| Codegen | `graphql_codegen` (v3.0.1, dev) |
| Dio bridge | `gql_dio_link` (v2.0.0) |

No `graphql_flutter` (forces widget hooks), no `ferry` (forces
`built_value`).

## Architecture

```
lib/
├── schema.graphql                          # Full backend schema
├── schema.graphql.dart                     # Generated enums / scalars
├── core/
│   └── network/
│       ├── dio_client.dart                 # Shared Dio instance
│       ├── graphql_client_provider.dart    # GraphQL client (uses Dio)
│       └── graphql_client_provider.g.dart  # Generated Riverpod
└── features/
    └── <feature>/
        └── data/
            ├── graphql/
            │   ├── <operation>.graphql       # Operation file
            │   └── <operation>.graphql.dart  # Generated DTOs
            └── data_sources/
                └── <feature>_remote_data_source.dart
```

**Key rule:** `.graphql` operation files live inside the feature's
`data/graphql/` directory. The schema lives at the project root
(`lib/schema.graphql`).

## Client Setup

`graphqlClientProvider` is a `keepAlive` Riverpod provider that bridges
the `graphql` library to the existing Dio instance via `DioLink`. All
Dio interceptors (auth, logging, timeouts) apply automatically to
GraphQL requests.

```dart
// lib/core/network/graphql_client_provider.dart
@Riverpod(keepAlive: true)
GraphQLClient graphqlClient(Ref ref) {
  return GraphQLClient(
    link: DioLink('/graphql', client: ref.read(dioProvider)),
    cache: GraphQLCache(store: InMemoryStore()),
  );
}
```

- Path `/graphql` is appended to `AppConfig.baseUrl`.
- In-memory cache (cleared on app restart). Use `FetchPolicy.networkOnly`
  when stale data is unacceptable.
- No separate Dio instance — the shared one carries auth headers, logging,
  and timeouts.

## Codegen Configuration

`build.yaml` at the project root:

```yaml
targets:
  $default:
    builders:
      graphql_codegen:
        options:
          clients:
            - graphql
          schema: lib/schema.graphql
```

Generated files are committed (`*.graphql.dart`).

## Schema Management

The schema is downloaded from the backend's HotChocolate introspection
endpoint and committed to version control:

```sh
npx get-graphql-schema http://localhost:5214/graphql > lib/schema.graphql
```

Re-download whenever the backend schema changes, then regenerate:

```sh
dart run build_runner build --delete-conflicting-outputs
```

### HotChocolate Conventions

- Enum values are **PascalCase** (`MobileApp`, `FileStorage`), not
  `MOBILE_APP` or `FILE_STORAGE`.
- Custom scalars: `UUID`, `DateTime`.
- Generated Dart enums are prefixed with `Enum$`
  (e.g. `Enum$ConfigurationCategory.MobileApp`).
- Dart keyword conflicts are prefixed with `$`
  (e.g. `Enum$ConfigurationValueType.$String`).
- Every generated enum includes a `$unknown` fallback for forward
  compatibility.

## Adding a New Query

### 1. Write the operation file

Create a `.graphql` file in the feature's `data/graphql/` directory.
Name it after the operation (snake_case file, PascalCase operation):

```graphql
# lib/features/events/data/graphql/get_events.graphql
query GetEvents($status: EventStatus!) {
  events(status: $status) {
    id
    title
    startDate
  }
}
```

Select only the fields you need — no `*` equivalent.

### 2. Run codegen

```sh
dart run build_runner build --delete-conflicting-outputs
```

This generates a sibling `.graphql.dart` file containing:
- `Variables$Query$GetEvents` — typed variables class
- `Query$GetEvents` — typed result class
- `Query$GetEvents$events` — typed item class
- `Options$Query$GetEvents` — query options (fetch policy, etc.)
- `documentNodeQueryGetEvents` — the AST `DocumentNode`
- Extension on `GraphQLClient` with `.query$GetEvents()` method

### 3. Create the data source

```dart
// lib/features/events/data/data_sources/events_remote_data_source.dart
import 'package:graphql/client.dart';

import '../graphql/get_events.graphql.dart';

class EventsRemoteDataSource {
  EventsRemoteDataSource(this._client);

  final GraphQLClient _client;

  Future<Query$GetEvents> fetchEvents(Enum$EventStatus status) async {
    final result = await _client.query$GetEvents(
      Options$Query$GetEvents(
        variables: Variables$Query$GetEvents(status: status),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );

    if (result.hasException) {
      throw result.exception!;
    }

    if (result.parsedData == null) {
      throw const FormatException('Null response from events query');
    }

    return result.parsedData!;
  }
}
```

### 4. Map to domain model in the repository

```dart
final result = await _remoteDataSource.fetchEvents(Enum$EventStatus.Active);

final events = [
  for (final item in result.events)
    Event(id: item.id, title: item.title, startDate: item.startDate),
];
```

Generated DTOs stay in `data/`. Domain models are Freezed classes in
`domain/models/`. Never expose generated GraphQL types to presentation.

### 5. Wire up providers

```dart
// lib/features/events/providers.dart
final eventsRemoteDataSourceProvider =
    Provider<EventsRemoteDataSource>((ref) {
  return EventsRemoteDataSource(ref.read(graphqlClientProvider));
});
```

## Testing GraphQL Data Sources

Use a `FakeGraphQLClient` that extends `Fake` and overrides `query()`:

```dart
class FakeGraphQLClient extends Fake implements GraphQLClient {
  QueryResult<Query$GetEvents>? nextResult;
  Exception? nextException;

  @override
  Future<QueryResult<T>> query<T>(QueryOptions<T> options) async {
    if (nextException != null) throw nextException!;
    return nextResult! as QueryResult<T>;
  }
}
```

Build success/error results with the generated types:

```dart
QueryResult<Query$GetEvents> _successResult(
  List<Query$GetEvents$events> items,
) {
  return QueryResult(
    data: Query$GetEvents(events: items).toJson(),
    options: QueryOptions(
      document: documentNodeQueryGetEvents,
      parserFn: (data) => Query$GetEvents.fromJson(data),
    ),
    source: QueryResultSource.network,
  );
}

QueryResult<Query$GetEvents> _errorResult(String message) {
  return QueryResult(
    data: null,
    options: QueryOptions(
      document: documentNodeQueryGetEvents,
      parserFn: (data) => Query$GetEvents.fromJson(data),
    ),
    source: QueryResultSource.network,
    exception: OperationException(
      graphqlErrors: [GraphQLError(message: message)],
    ),
  );
}
```

Test all paths: success, GraphQL error (`hasException`), network error
(client throws), and timeout.

## Rules

- **DO** use GraphQL for read operations and REST for writes.
- **DO** place `.graphql` files in `<feature>/data/graphql/`.
- **DO** select only the fields you need in the operation.
- **DO** check `result.hasException` and `result.parsedData` after every
  query.
- **DO** map generated DTOs to Freezed domain models in the repository.
- **DO** commit generated `*.graphql.dart` files.
- **DO** re-download the schema (`npx get-graphql-schema ...`) when the
  backend changes.
- **DO** use `FakeGraphQLClient` for testing — never mock the
  `GraphQLClient` class.
- **DO NOT** expose generated GraphQL types (`Query$*`, `Variables$*`)
  outside of `data/`.
- **DO NOT** use `graphql_flutter`, `ferry`, or other GraphQL packages.
- **DO NOT** create a second `Dio` instance — GraphQL shares the
  existing one via `DioLink`.
- **DO NOT** assume SCREAMING_SNAKE_CASE enums — HotChocolate uses
  PascalCase.
