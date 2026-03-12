# Posts Feature Implementation Plan

## Overview

Implement a complete posts feature using Riverpod for state management, following vertical slices architecture pattern similar to the existing event feature. The feature will fetch posts from `https://jsonplaceholder.typicode.com/posts`.

---

## Architecture Overview

### Vertical Slices Structure

```
lib/features/posts/
├── data/                      # Data layer (infrastructure)
│   ├── dto/                   # Data Transfer Objects
│   │   ├── post_dto.dart      # DTO with Freezed
│   │   ├── post_dto.freezed.dart
│   │   └── post_dto.g.dart
│   └── repositories/          # Repository implementations
│       └── post_repository_impl.dart
├── domain/                    # Domain layer (business logic)
│   └── repositories/          # Repository interfaces
│       └── post_repository.dart
├── application/               # Application layer (controllers/providers)
│   ├── post_controller.dart   # Main controller with Riverpod
│   └── post_controller.g.dart # Generated
├── presentation/              # Presentation layer (UI)
│   ├── screens/
│   │   ├── post_list_screen.dart
│   │   └── post_detail_screen.dart
│   └── widgets/
│       ├── post_list_tile.dart
│       └── post_loading_shimmer.dart
└── providers.dart             # Provider definitions
```

---

## Current State vs Required Changes

### Already Exists ✅

- `lib/features/posts/data/dto/post_dto.dart` - DTO with Freezed
- `lib/features/posts/data/dto/post_dto.freezed.dart` - Generated
- `lib/features/posts/data/dto/post_dto.g.dart` - Generated
- `lib/features/posts/data/repository/post_repository.dart` - Basic implementation
- `lib/features/posts/application/post_controller.dart` - Basic providers
- `lib/features/posts/presentation/post_screen.dart` - Empty file

### Needs to Be Created/Modified 🔧

---

## Detailed Implementation Steps

### Step 1: Enhance Domain Layer

#### Create `lib/features/posts/domain/repositories/post_repository.dart`

```dart
/// Abstract contract for the Post data source
abstract class PostRepository {
  /// Fetch all posts
  Future<List<PostDto>> getPosts();

  /// Fetch a single post by ID
  Future<PostDto> getPostById(int id);
}
```

### Step 2: Update Data Layer

#### Update `lib/features/posts/data/repository/post_repository.dart` (rename to post_repository_impl.dart)

- Implement the `PostRepository` interface
- Use Dio to fetch from `https://jsonplaceholder.typicode.com/posts`
- Add proper error handling

#### Update `lib/features/posts/data/dto/post_dto.dart`

- Add `userId` field (from API response)
- Add `toEntity()` method to convert DTO to domain entity (optional, if we want separate domain model)

### Step 3: Update Application Layer

#### Update `lib/features/posts/application/post_controller.dart`

Replace with a complete controller pattern similar to event feature:

```dart
// Providers to export
// - dioProvider (reuse from core or create new)
// - postRepositoryProvider
// - postListControllerProvider (AsyncNotifier for list with pagination)
// - postDetailControllerProvider (for single post)
```

**Key Components:**

- Use `@riverpod` annotation with `AsyncNotifier` for state management
- Implement `build()` for initial fetch
- Implement `loadMore()` for pagination
- Implement `refresh()` for pull-to-refresh
- Use `AsyncValue.guard()` for safe error handling

### Step 4: Create Presentation Layer

#### Create `lib/features/posts/presentation/screens/post_list_screen.dart`

- Scaffold with AppBar
- Use `ref.watch()` on `postListControllerProvider`
- Handle loading, error, and data states with `AsyncValue.when()`
- Display posts in `ListView.builder`
- Add pull-to-refresh with `RefreshIndicator`
- Add error handling with snackbar using `ref.listen()`
- Add "Load More" button for pagination

#### Create `lib/features/posts/presentation/screens/post_detail_screen.dart`

- Display single post details
- Show title, body, userId
- Add back navigation

#### Create Widgets (optional, for better organization)

- `lib/features/posts/presentation/widgets/post_list_tile.dart`
- `lib/features/posts/presentation/widgets/post_loading_shimmer.dart`

### Step 5: Create Providers File

#### Create `lib/features/posts/providers.dart`

```dart
// Infrastructure providers
@Riverpod(keepAlive: true)
PostRepository postRepository(Ref ref);

// Derived providers
@riverpod
List<Post> upcomingPosts(Ref ref); // Example if filtering needed
```

### Step 6: Update Main Entry Point

#### Update `lib/main.dart`

- Import the post list screen
- Add it to MaterialApp (as home or route)
- Wrap with `ProviderScope`

---

## API Reference

### Endpoint: GET /posts

Returns array of posts:

```json
[
  {
    "userId": 1,
    "id": 1,
    "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
    "body": "..."
  }
]
```

### Endpoint: GET /posts/{id}

Returns single post:

```json
{
  "userId": 1,
  "id": 1,
  "title": "sunt aut facere repellat provident occaecati excepturi optio reprehenderit",
  "body": "..."
}
```

---

## Dependencies (Already in pubspec.yaml)

- `flutter_riverpod: ^2.6.1`
- `riverpod_annotation: ^2.6.1`
- `freezed_annotation: ^2.4.4`
- `json_annotation: ^4.9.0`
- `dio: ^5.4.3`
- `build_runner` (dev)
- `riverpod_generator` (dev)
- `freezed` (dev)
- `json_serializable` (dev)

---

## Implementation Priority Order

1. **Domain Layer**: Create repository interface
2. **Data Layer**: Implement repository, update DTO
3. **Application Layer**: Create controller with Riverpod
4. **Presentation Layer**: Create screens and widgets
5. **Integration**: Update main.dart

---

## Code Generation Commands

After creating/updating files with annotations, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Pattern Reference: Event Feature

The implementation should follow the same patterns used in:

- [`lib/features/event/domain/repositories/event_repository.dart`](lib/features/event/domain/repositories/event_repository.dart)
- [`lib/features/event/providers.dart`](lib/features/event/providers.dart)
- [`lib/features/event/presentation/controllers/event_list_controller.dart`](lib/features/event/presentation/controllers/event_list_controller.dart)
- [`lib/features/event/presentation/screens/event_list_screen.dart`](lib/features/event/presentation/screens/event_list_screen.dart)

Key patterns to replicate:

- Abstract repository interface in domain layer
- Concrete implementation in data layer
- `@riverpod` annotated controllers using `AsyncNotifier`
- UI screens using `ref.watch()` and `AsyncValue.when()`
- Error handling with `ref.listen()` for snackbars
- Pull-to-refresh with `invalidateSelf()`
- Pagination with load more pattern
