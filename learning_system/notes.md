# Flutter Study Notes: DTO & DTO Mapping

---

## What is a DTO?

A **DTO (Data Transfer Object)** is a simple class used to transfer data between different parts of a system, especially between your app and external sources like APIs or databases.

- **DTOs** represent the shape of data as received from or sent to an API.
- They are often different from your app's core business models (entities).

---

## Why Use DTOs?

- APIs often return data with extra fields, different naming, or formats that don't match your app's needs.
- DTOs help keep your domain models clean and focused on business logic.
- They make serialization/deserialization easy and reliable.
- They allow you to adapt to backend changes without breaking your app's core logic.

---

## DTO vs Entity

| Aspect        | DTO (Data Layer)      | Entity (Domain Layer)     |
| ------------- | --------------------- | ------------------------- |
| Purpose       | API/data transfer     | Business logic/model      |
| Mutability    | Usually immutable     | Always immutable          |
| Serialization | Yes (fromJson/toJson) | Sometimes (rarely needed) |
| Extra Fields  | May have extra fields | Only core fields          |
| Mapping       | toEntity()            | -                         |

---

## Professional Mermaid Diagrams: DTO & Mapping

### API → DTO → Entity → UI Flow

```mermaid
flowchart LR
    API[API Server] --> DTO[Event DTO]
    DTO --> Entity[Event Entity]
    Entity --> UI[Flutter UI]

    classDef api fill:#ffcc99,stroke:#333
    classDef dto fill:#99ccff,stroke:#333
    classDef entity fill:#99ff99,stroke:#333
    classDef ui fill:#d5a6ff,stroke:#333

    class API api
    class DTO dto
    class Entity entity
    class UI ui
```

### Clean Architecture Data Flow

```mermaid
flowchart LR
    API[API Server]:::api --> DataLayer[DTO Layer]:::dto
    DataLayer --> DomainLayer[Domain Entity Layer]:::entity
    DomainLayer --> UILayer[UI Layer]:::ui

    classDef api fill:#ffcc99,stroke:#333
    classDef dto fill:#99ccff,stroke:#333
    classDef entity fill:#99ff99,stroke:#333
    classDef ui fill:#d5a6ff,stroke:#333

    class API api
    class DataLayer dto
    class DomainLayer entity
    class UILayer ui
```

### DTO to Entity Mapping Sequence

```mermaid
sequenceDiagram
    participant API as API Server
    participant DTO as Event DTO
    participant Entity as Event Entity
    participant UI as Flutter UI

    API->>DTO: fromJson()
    DTO->>Entity: toEntity()
    Entity->>UI: Use in widgets

    %% Styling not supported in sequence diagrams, but labels are clear
```

### Class Diagram: DTO vs Entity

```mermaid
classDiagram
    class EventDto {
        +String id
        +String title
        +DateTime startDate
        +DateTime endDate
        +String venue
        +fromJson()
        +toJson()
        +toEntity()
    }
    class Event {
        +String id
        +String title
        +DateTime startDate
        +DateTime endDate
        +String venue
    }
    EventDto : toEntity() --> Event

    classDef dto fill:#99ccff,stroke:#333
    classDef entity fill:#99ff99,stroke:#333
    class EventDto dto
    class Event entity
```

---

## Real Flutter Example: DTO & Mapping

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'event.dart'; // domain entity

part 'event_dto.freezed.dart';
part 'event_dto.g.dart';

@freezed
class EventDto with _$EventDto {
  const factory EventDto({
    required String id,
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    required String venue,
  }) = _EventDto;

  factory EventDto.fromJson(Map<String, dynamic> json) => _$EventDtoFromJson(json);

  // Mapping: Convert DTO to domain entity
  Event toEntity() => Event(
    id: id,
    title: title,
    startDate: startDate,
    endDate: endDate,
    venue: venue,
  );
}
```

---

## Common Mistakes

- Mixing DTOs and entities (leads to messy code)
- Not handling nulls or missing fields from API
- Forgetting to run build_runner for code generation
- Adding business logic to DTOs (should be pure data)
- Not separating data and domain layers

---

## Barrel Files — Deep Dive

### What is a Barrel File?

A barrel file is a Dart file that exports all public APIs for a feature. It acts as the single entry point for importing feature code elsewhere.

### Why Use Barrel Files?

- Simplifies imports: `import 'features/events/events.dart';` instead of many individual files
- Enforces modularity: Only public APIs are exposed
- Makes refactoring easier: Change internal structure without breaking consumers
- Prevents leaking internal details: Only export what should be public

### Real-World Example

```dart
// features/events/events.dart
export 'domain/entities/event.dart';
export 'data/models/event_dto.dart';
export 'providers.dart';
export 'presentation/screens/event_list_screen.dart';
export 'presentation/controllers/event_list_controller.dart';
```

### Best Practices

- Only export files that are part of the public API
- Do not export internal helpers or private files
- Use one barrel file per feature
- Keep barrel files updated as features evolve

### Common Mistakes

- Exporting everything (including private/internal files)
- Not using barrel files, leading to messy imports
- Forgetting to update barrel files after refactoring
- Using barrel files for unrelated features (breaks modularity)

### Performance & Maintainability

- Barrel files do not impact runtime performance, but greatly improve code maintainability and readability
- They make onboarding new developers easier

---

## Barrel Files — Visual Explanation & Example

### Mermaid Diagram: Feature Barrel File Structure

```mermaid
flowchart TD
    subgraph EventsFeature[Events Feature]
        Entity[Event Entity]:::entity
        DTO[Event DTO]:::dto
        Providers[Providers]:::api
        Controller[EventListController]:::api
        Screen[EventListScreen]:::ui
    end
    Barrel[events.dart Barrel File]:::barrel
    Barrel --> Entity
    Barrel --> DTO
    Barrel --> Providers
    Barrel --> Controller
    Barrel --> Screen
    AppRoot[App Root]:::app
    AppRoot --> Barrel

    classDef entity fill:#99ff99,stroke:#333
    classDef dto fill:#99ccff,stroke:#333
    classDef api fill:#ffcc99,stroke:#333
    classDef ui fill:#d5a6ff,stroke:#333
    classDef barrel fill:#b3e6ff,stroke:#333,stroke-width:2px
    classDef app fill:#e6b3ff,stroke:#333
```

---

### Example: Barrel File for Tickets Feature

```dart
// lib/features/tickets/tickets.dart

export 'domain/entities/ticket.dart';
export 'data/models/ticket_dto.dart';
export 'providers.dart';
export 'presentation/screens/ticket_list_screen.dart';
export 'presentation/controllers/ticket_list_controller.dart';
```

---

### How Barrel Files Simplify Imports

```mermaid
flowchart LR
    TicketsBarrel[tickets.dart Barrel File]:::barrel --> TicketEntity[Ticket Entity]:::entity
    TicketsBarrel --> TicketDTO[Ticket DTO]:::dto
    TicketsBarrel --> TicketProviders[Providers]:::api
    TicketsBarrel --> TicketController[TicketListController]:::api
    TicketsBarrel --> TicketScreen[TicketListScreen]:::ui
    FeatureConsumer[Other Feature or App Root]:::app --> TicketsBarrel

    classDef entity fill:#99ff99,stroke:#333
    classDef dto fill:#99ccff,stroke:#333
    classDef api fill:#ffcc99,stroke:#333
    classDef ui fill:#d5a6ff,stroke:#333
    classDef barrel fill:#b3e6ff,stroke:#333,stroke-width:2px
    classDef app fill:#e6b3ff,stroke:#333
```

---

## Environment Management in Flutter (flutter_dotenv)

### Overview

Managing multiple environments (dev, staging, prod) is essential for scalable Flutter apps. The flutter_dotenv package allows you to load environment variables from .env files at runtime, enabling easy switching and secure configuration.

### Visual Diagram: Environment Loading Pipeline

```mermaid
graph TD
    A[App Startup] --> B[Load .env file]
    B --> C[flutter_dotenv parses variables]
    C --> D[Inject into app config/providers]
    D --> E[Feature modules use env values]
    style B fill:#e3f2fd,stroke:#2196f3
    style C fill:#fffde7,stroke:#ffeb3b
    style D fill:#e8f5e9,stroke:#43a047
    style E fill:#f3e5f5,stroke:#8e24aa
```

---

### Step-by-Step Example

#### 1. Create .env Files

- `.env.dev`:
  ```env
  API_BASE_URL=https://api-dev.eventhub.com
  IS_TICKET_SALES_ENABLED=true
  MAX_UPLOAD_SIZE_BYTES=10485760
  ```
- `.env.staging`:
  ```env
  API_BASE_URL=https://api-staging.eventhub.com
  IS_TICKET_SALES_ENABLED=true
  MAX_UPLOAD_SIZE_BYTES=10485760
  ```
- `.env.prod`:
  ```env
  API_BASE_URL=https://api.eventhub.com
  IS_TICKET_SALES_ENABLED=false
  MAX_UPLOAD_SIZE_BYTES=5242880
  ```

#### 2. Add flutter_dotenv Dependency

```yaml
# pubspec.yaml
# ...existing code...
flutter_dotenv: ^5.1.0
# ...existing code...
```

#### 3. Load Environment in main.dart

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env.dev"); // Change to .env.staging or .env.prod as needed
  runApp(MyApp());
}
```

#### 4. Access Variables Anywhere

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

final apiBaseUrl = dotenv.env['API_BASE_URL'];
final isTicketSalesEnabled = dotenv.env['IS_TICKET_SALES_ENABLED'] == 'true';
final maxUploadSize = int.parse(dotenv.env['MAX_UPLOAD_SIZE_BYTES'] ?? '5242880');
```

---

### Best Practices

- Never commit production secrets to version control.
- Use .env files for API endpoints, feature flags, and limits.
- Switch environment files using build scripts or CI/CD.
- Validate required keys at startup.

---

### Checklist

- [x] .env files created for each environment
- [x] flutter_dotenv added to pubspec.yaml
- [x] main.dart loads correct .env file
- [x] Providers/services use env variables

---

### Common Mistakes

- Forgetting to load the .env file before runApp()
- Using incorrect file names (case-sensitive)
- Not parsing string values to bool/int

---

### Advanced: CI/CD Integration

- Use build scripts to select .env file per build:
  - `flutter build apk --dart-define=ENV=prod`
  - In main.dart, load file based on ENV

---

## Summary

- **DTOs** are for data transfer and serialization.
- **Entities** are for business logic and core modeling.
- **Mapping** keeps your architecture clean and maintainable.
- Use `@JsonSerializable` and Freezed for robust, immutable DTOs.
- Always separate DTOs and entities for scalable Flutter apps.
