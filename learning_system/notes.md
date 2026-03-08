## Freezed Entities — Engineering Insights

- Immutability prevents accidental mutation, which is a major source of bugs in stateful apps. Entities should never change after creation.
- Freezed automates equality, copyWith, and union types, reducing boilerplate and human error.
- Always run `build_runner` after changing Freezed entities; otherwise, generated code will be out of sync and cause runtime errors or missing features.
- For fields with fixed possible values (like ticket status), use Dart enums for type safety and maintainability. Example:
  ```dart
  enum TicketStatus { purchased, used, cancelled }
  ```
- Entities should be pure data—no business logic, no side effects.
- Place entities in domain folders for clean architecture separation.
- Common mistakes: forgetting part directives, not running build_runner, using mutable fields, mixing domain and DTO logic.
- Pattern matching (when/map) on Freezed unions enables readable, maintainable state handling.
- Use copyWith for safe state updates in Riverpod, Bloc, etc.
- Prefer explicit types and required fields for clarity and safety.
