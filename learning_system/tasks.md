# Capstone Project: EventHub — Event Management & Ticketing App

---

## Project Overview

**EventHub** is a production-grade event management and ticketing platform. Organizers create events, manage guest lists, and scan tickets. Attendees browse events, purchase tickets, receive push notifications, and check in via QR codes.

This single project exercises **all 21 advanced concepts** from the docs.

```
╔══════════════════════════════════════════════════════════════════╗
║                        EventHub App                              ║
║                                                                  ║
║   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   ║
║   │  Browse  │  │  Buy     │  │  Scan    │  │  Get Push   │   ║
║   │  Events  │  │  Tickets │  │  QR Code │  │  Reminders  │   ║
║   └──────────┘  └──────────┘  └──────────┘  └──────────────┘   ║
║                                                                  ║
║   👤 Attendee                   👤 Organizer                     ║
║   • Browse & search events      • Manage guest lists             ║
║   • Purchase tickets             • Scan tickets at door           ║
║   • Receive reminders            • View check-in stats            ║
║   • Show QR ticket               • Share event links              ║
║                                                                  ║
║   Concepts Used: ALL 21                                          ║
╚══════════════════════════════════════════════════════════════════╝
```

### Why This Project?

| Requirement                           | Concepts Exercised                                  |
| ------------------------------------- | --------------------------------------------------- |
| User authentication (OTP-based)       | Auth sealed state, token refresh, router guard      |
| Event listing with filters/search     | Riverpod AsyncNotifier, family providers, select()  |
| Event detail with real-time updates   | GraphQL queries, derived providers                  |
| Ticket purchase flow                  | REST API (Retrofit), form validation errors (422)   |
| Offline event browsing                | Drift database, DAO pattern, cache fallback         |
| QR ticket scanning                    | mobile_scanner, camera controls                     |
| Push notification for event reminders | FCM, local notifications, channels                  |
| Deep link to event from shared URL    | App Links, Universal Links, GoRouter                |
| Multi-language support (EN/AR)        | Slang i18n, RTL layout                              |
| Dark mode + brand theming             | M3 seed theming, ThemeExtension, theme persistence  |
| Responsive phone/tablet layout        | AppSpacing, breakpoints                             |
| Feature flags (disable ticket sales)  | Remote config, typed getters                        |
| Environment management                | dart-define-from-file                               |
| CI/CD pipeline                        | GitHub Actions, Fastlane, Firebase App Distribution |
| 80% test coverage                     | Unit, widget, integration tests                     |

---

## Architecture Proposal

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────────┐  │
│  │  Events   │ │ Tickets  │ │ Scanner  │ │   Profile     │  │
│  │  Screen   │ │  Screen  │ │  Screen  │ │   Screen      │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬────────┘  │
│       │             │            │               │           │
│  ┌────┴─────┐ ┌────┴─────┐ ┌────┴─────┐ ┌──────┴────────┐  │
│  │ EventList │ │ Ticket   │ │ Scanner  │ │   Profile     │  │
│  │Controller│ │Controller│ │Controller│ │  Controller    │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬────────┘  │
└───────┼─────────────┼────────────┼──────────────┼────────────┘
        │             │            │              │
┌───────┼─────────────┼────────────┼──────────────┼────────────┐
│       │         Domain           │              │            │
│  ┌────┴─────┐ ┌────┴─────┐ ┌────┴─────┐ ┌──────┴────────┐  │
│  │  Event   │ │  Ticket  │ │  CheckIn │ │    User       │  │
│  │Repository│ │Repository│ │Repository│ │  Repository   │  │
│  │(abstract)│ │(abstract)│ │(abstract)│ │  (abstract)   │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └──────┬────────┘  │
└───────┼─────────────┼────────────┼──────────────┼────────────┘
        │             │            │              │
┌───────┼─────────────┼────────────┼──────────────┼────────────┐
│       │           Data           │              │            │
│  ┌────┴──────────────┴───────────┴──────────────┴─────────┐  │
│  │                                                         │  │
│  │  ┌─────────────┐    ┌─────────────┐    ┌────────────┐  │  │
│  │  │  Retrofit    │    │   GraphQL   │    │   Drift    │  │  │
│  │  │  API Service │    │   Queries   │    │   DAOs     │  │  │
│  │  └──────┬──────┘    └──────┬──────┘    └─────┬──────┘  │  │
│  │         │                  │                  │         │  │
│  │         └────────┬─────────┘                  │         │  │
│  │                  │                            │         │  │
│  │            ┌─────┴──────┐                     │         │  │
│  │            │    Dio     │                     │         │  │
│  │            │ (+ interceptors)                 │         │  │
│  │            └────────────┘                     │         │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
        │
┌───────┴──────────────────────────────────────────────────────┐
│                          Core                                 │
│  ┌──────┐ ┌────────┐ ┌───────┐ ┌──────┐ ┌────────┐ ┌──────┐│
│  │ Auth │ │Network │ │  DB   │ │Theme │ │  i18n  │ │Router││
│  └──────┘ └────────┘ └───────┘ └──────┘ └────────┘ └──────┘│
│  ┌───────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ │
│  │Notifications│ │RemoteConfig│ │  Storage   │ │   Utils   │ │
│  └───────────┘ └────────────┘ └────────────┘ └────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

### Feature Slices

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── auth/                    # AuthState, AuthController, token providers
│   ├── database/                # AppDatabase, table defs, migrations
│   ├── di/                      # App-wide providers (AppConfig, DB)
│   ├── router/                  # GoRouter, auth guard, route composition
│   ├── network/                 # Dio client, interceptors, GraphQL client
│   ├── notifications/           # NotificationService, channels
│   ├── remote_config/           # Config fetch, typed getters, caching
│   ├── storage/                 # SharedPreferences wrapper
│   ├── theme/                   # AppTheme, AppColors, AppSpacing
│   ├── i18n/                    # Slang-generated translations
│   └── utils/                   # Logger, constants
├── features/
│   ├── auth/                    # Login, OTP, auth API
│   ├── events/                  # Event list, detail, search, filters
│   ├── tickets/                 # Ticket purchase, my tickets, ticket detail
│   ├── scanner/                 # QR scanning, check-in validation
│   ├── profile/                 # User profile, settings, theme toggle
│   └── notifications/           # Notification inbox, preferences
├── shared/
│   ├── widgets/                 # PrimaryButton, ErrorView, LoadingIndicator
│   ├── models/                  # Cross-feature value objects
│   └── extensions/              # toUserMessage(), date formatting
├── assets/
│   ├── svg/                     # SVG icons (compiled to .vec)
│   ├── i18n/                    # en.i18n.yaml, ar.i18n.yaml
│   └── images/
└── config/
    ├── dev.json
    ├── staging.json
    └── prod.json
```

### Data Flow Per Feature

```
                    ┌─────────────────┐
                    │    Screen        │  ref.watch(controllerProvider)
                    │ (ConsumerWidget) │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │   Controller     │  AsyncNotifier via @riverpod
                    │ (AsyncNotifier)  │  ref.watch(repositoryProvider)
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │   Repository     │  Abstract interface (domain)
                    │ (Implementation) │  Concrete impl (data)
                    └───┬─────────┬───┘
                        │         │
               ┌────────┴──┐  ┌──┴────────┐
               │ API Service│  │   DAO     │
               │ (Retrofit) │  │  (Drift)  │
               └────────────┘  └───────────┘
```

### Technology Stack Summary

| Layer              | Technology                                            |
| ------------------ | ----------------------------------------------------- |
| State Management   | Riverpod 3.x + `@riverpod` codegen                    |
| Navigation         | GoRouter                                              |
| REST Networking    | Dio + Retrofit                                        |
| GraphQL            | `graphql` + `gql_dio_link` + `graphql_codegen`        |
| Local Database     | Drift (SQLite)                                        |
| Data Classes       | Freezed + `json_serializable`                         |
| Auth               | Sealed state + `QueuedInterceptor` + GoRouter guard   |
| Theming            | M3 `ColorScheme.fromSeed()` + `ThemeExtension`        |
| Spacing            | Custom `AppSpacing` (elastic)                         |
| i18n               | Slang                                                 |
| Push Notifications | Firebase Messaging + Local Notifications              |
| Deep Linking       | App Links / Universal Links                           |
| QR Scanning        | `mobile_scanner`                                      |
| Remote Config      | Custom backend + SharedPreferences cache              |
| SVG                | `vector_graphics` (compiled assets)                   |
| Testing            | `flutter_test` + `mocktail`                           |
| CI/CD              | GitHub Actions + Fastlane + Firebase App Distribution |
| OTA Updates        | Shorebird                                             |

---

## Screens (Approximate)

| Feature       | Screen                 | Key Interactions                                       |
| ------------- | ---------------------- | ------------------------------------------------------ |
| Auth          | Login Screen           | Phone input → request OTP                              |
| Auth          | OTP Screen             | Verify OTP → receive tokens → redirect home            |
| Events        | Event List Screen      | Pull-to-refresh, filter chips, search, infinite scroll |
| Events        | Event Detail Screen    | GraphQL query, share deep link, buy ticket CTA         |
| Tickets       | Purchase Flow          | REST POST, form validation errors, success state       |
| Tickets       | My Tickets Screen      | List of purchased tickets, ticket status badge         |
| Tickets       | Ticket Detail Screen   | QR code display, event info, cancel option             |
| Scanner       | QR Scanner Screen      | Camera view, scan window, torch toggle                 |
| Scanner       | Check-In Result Screen | Valid/invalid/already-used states                      |
| Profile       | Profile Screen         | User info, theme toggle, language selector, logout     |
| Notifications | Notification Inbox     | Push history list, mark as read, tap → deep link       |

---

## API Surface (Mock)

### REST Endpoints (Retrofit)

```
POST   /auth/login              → { phone, otp } → { accessToken, refreshToken, user }
POST   /auth/refresh            → { refreshToken } → { accessToken, refreshToken }
GET    /events                  → query params: status, search, page, pageSize
POST   /tickets/purchase        → { eventId, quantity } → Ticket
GET    /tickets/mine            → List<Ticket>
POST   /scanner/checkin         → { ticketId } → CheckInResult
GET    /profile                 → User
PUT    /profile                 → { name, ... } → User
POST   /notifications/register  → { fcmToken }
GET    /configurations          → List<ConfigurationSetting>
```

### GraphQL Queries

```graphql
query GetEventDetail($id: UUID!) {
  event(id: $id) {
    id
    title
    description
    startDate
    endDate
    venue {
      name
      address
      latitude
      longitude
    }
    ticketTypes {
      id
      name
      price
      available
    }
    organizer {
      name
      avatarUrl
    }
  }
}

query GetEvents(
  $status: EventStatus!
  $search: String
  $first: Int
  $after: String
) {
  events(status: $status, search: $search, first: $first, after: $after) {
    nodes {
      id
      title
      coverImageUrl
      startDate
      venue {
        name
      }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

---

## Milestones

```
Milestone Timeline:

  M1        M2        M3          M4       M5        M6       M7        M8       M9
  Scaffold  State     Network     DB       GraphQL   UI       Platform  Testing  CI/CD
  │         │         & Auth      │        & Config  Polish   Features  │        │
  ▼         ▼         ▼           ▼        ▼         ▼        ▼         ▼        ▼
  ┌───┐    ┌───┐    ┌───────┐   ┌───┐   ┌───┐    ┌───┐    ┌───┐    ┌───┐    ┌───┐
  │ 1 │───▶│ 2 │───▶│ 3     │──▶│ 4 │──▶│ 5 │───▶│ 6 │───▶│ 7 │───▶│ 8 │───▶│ 9 │
  │   │    │   │    │       │   │   │   │   │    │   │    │   │    │   │    │   │
  └───┘    └───┘    └───────┘   └───┘   └───┘    └───┘    └───┘    └───┘    └───┘
  Wk 1-2   Wk 3-4   Wk 5-8     Wk 9-10 Wk 11-12 Wk 13-14 Wk 15-16 Wk 17-18 Wk 19-20

  ════ Foundation ════  ════ Data ════  ════ Polish ════  ════ Quality ════
```

### M1: Project Scaffold & Foundation (Week 1–2)

**Concepts:** C2, C3, C16

- [x] Initialize Flutter project with proper directory structure
- [x] Configure `pubspec.yaml` with all dependencies
- [x] Set up `build.yaml` for all generators
- [x] Create Freezed entities: `Event`, `Ticket`, `User`, `CheckInResult`
- [x] Create DTOs with `@JsonSerializable` and `toEntity()` methods
- [ ] Set up barrel files for each feature
- [ ] Configure environment JSON files (`dev.json`, `staging.json`, `prod.json`)
- [ ] Run `build_runner` — all generators pass
- [ ] Verify project compiles with `flutter analyze`

**Exit Criteria:** Project scaffold matches `project-structure.md` conventions. All entities and DTOs generate correctly.

```
M1 — What You Build:

  lib/
  ├── main.dart ─────────────── entry point
  ├── app.dart ──────────────── MaterialApp.router
  ├── core/ ─────────────────── shared infrastructure
  │   ├── auth/                 (empty — ready for M3)
  │   ├── database/             (empty — ready for M4)
  │   ├── network/              (empty — ready for M3)
  │   └── theme/                (empty — ready for M6)
  ├── features/
  │   ├── events/
  │   │   ├── events.dart ───── barrel file
  │   │   ├── providers.dart
  │   │   ├── domain/
  │   │   │   └── entities/
  │   │   │       ├── event.dart ◀── @freezed
  │   │   │       └── event.freezed.dart ◀── generated
  │   │   └── data/
  │   │       └── models/
  │   │           ├── event_dto.dart ◀── @freezed + @JsonSerializable
  │   │           ├── event_dto.freezed.dart
  │   │           └── event_dto.g.dart ◀── fromJson/toJson
  │   └── tickets/
  │       └── (same structure)
  └── config/
      ├── dev.json ──────────── {"API_BASE_URL": "https://api-dev..."}
      ├── staging.json
      └── prod.json
```

---

### M2: State Management Layer (Week 3–4)

**Concepts:** C1, C3

- [ ] Create `dioProvider` (singleton, `keepAlive`)
- [ ] Wire feature provider graphs: API → Repository → Controller
- [ ] Implement `EventListController` (AsyncNotifier) with pagination
- [ ] Implement `EventDetailController` with family provider (`build(String eventId)`)
- [ ] Create derived provider: `upcomingEventsProvider` (filtered)
- [ ] Demonstrate `select()` optimization on event count
- [ ] Wire `ref.listen` for showing error snackbars
- [ ] Implement `ref.invalidateSelf()` for pull-to-refresh

**Exit Criteria:** Full Riverpod provider graph for events feature. Loading → Data → Error states all handled.

```
M2 — Screen State Machine:

  ┌─────────────────────────────────────────────┐
  │            EventListScreen                    │
  │                                               │
  │   orderAsync.when(                            │
  │     loading: ()  ──▶ ⏳ Spinner               │
  │     data: (list) ──▶ 📋 ListView.builder      │
  │     error: (e)   ──▶ ❌ ErrorView + Retry     │
  │   )                                           │
  │                                               │
  │   Pull-to-refresh ──▶ ref.invalidateSelf()    │
  │   Error snackbar  ──▶ ref.listen(...)         │
  │   Item count only ──▶ ref.watch(.select())    │
  └─────────────────────────────────────────────┘

  Provider Wiring in providers.dart:

  eventApiServiceProvider ──▶ EventApiService(dio)
          │
          ▼
  eventRepositoryProvider ──▶ EventRepositoryImpl(api, dao)
          │
          ▼
  eventListControllerProvider ──▶ AsyncNotifier<List<Event>>
          │
          ▼
  upcomingEventsProvider ──▶ filtered derived provider
```

---

### M3: Networking & Authentication (Week 5–8)

**Concepts:** C4, C5, C6

- [ ] Build Dio client with interceptor chain: Error → Auth → Log
- [ ] Implement `AppException` sealed class (all 5 variants)
- [ ] Implement `ErrorInterceptor` with exhaustive `DioException` mapping
- [ ] Build Retrofit API services: `AuthApi`, `EventApi`, `TicketApi`, `ScannerApi`
- [ ] Implement `AuthState` sealed class
- [ ] Build `AuthController` with `login()` / `logout()`
- [ ] Implement `QueuedInterceptor` for token refresh
- [ ] Set up GoRouter with auth guard redirect
- [ ] Build login screen → OTP screen → redirect to home
- [ ] Implement `toUserMessage()` extension for error display
- [ ] Token persistence via SharedPreferences

**Exit Criteria:** Full auth lifecycle works. 401 → refresh → retry or logout works. Error snackbars show localized messages.

```
M3 — Full Network + Auth Architecture:

  ┌─────────────────────────────────────────────────────────────┐
  │                   Dio Interceptor Chain                       │
  │                                                               │
  │   Request ──▶ ErrorInterceptor ──▶ AuthInterceptor ──▶ Log   │
  │                     │                    │                    │
  │                     │              Injects:                   │
  │                     │              Authorization:             │
  │                     │              Bearer <token>             │
  │                     ▼                    │                    │
  │              DioException?               │                    │
  │              ┌───────────┐               │                    │
  │              │ timeout   │──▶ NetworkException                │
  │              │ 401       │──▶ UnauthorizedException ──┐      │
  │              │ 422       │──▶ ValidationException     │      │
  │              │ 4xx       │──▶ ServerException         │      │
  │              │ 5xx       │──▶ ServerException         │      │
  │              │ other     │──▶ UnknownException        │      │
  │              └───────────┘                            │      │
  │                                                       │      │
  │              ┌────────────────────────────────────────┘      │
  │              │  QueuedInterceptor                            │
  │              │                                               │
  │              │    401 ──▶ try refresh token                  │
  │              │              │                                │
  │              │         ┌────┴────┐                           │
  │              │         │         │                           │
  │              │      Success   Failure                        │
  │              │      retry     logout()                       │
  │              │      request   ──▶ Unauthenticated            │
  │              │                    ──▶ GoRouter redirect      │
  │              │                        to /auth/login         │
  │              └───────────────────────────────────────────────│
  └─────────────────────────────────────────────────────────────┘

  Auth Screen Flow:

  ┌────────────┐     ┌────────────┐     ┌────────────┐
  │   Login    │────▶│    OTP     │────▶│   Home     │
  │   Screen   │     │   Screen   │     │  (Events)  │
  │            │     │            │     │            │
  │ Enter phone│     │ Enter code │     │ Redirected │
  │ POST /login│     │ Verify OTP │     │  by guard  │
  └────────────┘     └────────────┘     └────────────┘
```

---

### M4: Local Database (Week 9–10)

**Concepts:** C7

- [ ] Define Drift tables: `Events`, `Tickets`, `CachedUsers`
- [ ] Create `AppDatabase` in `core/database/`
- [ ] Build feature DAOs: `EventDao`, `TicketDao`
- [ ] Implement `watch()` streams for reactive UI updates
- [ ] Update repository implementations: remote-first with cache fallback
- [ ] Implement schema migration (add a column, test the upgrade path)
- [ ] Test with in-memory database

**Exit Criteria:** App works offline (shows cached data). Migration tested. Reactive streams update UI when cache changes.

```
M4 — Drift Database Architecture:

  ┌─────────────────────────────────────────────────────────────┐
  │                     core/database/                           │
  │                                                              │
  │   AppDatabase  (single instance, exposed via provider)       │
  │   ├── Tables: Events, Tickets, CachedUsers                  │
  │   ├── schemaVersion: 2                                      │
  │   └── migration:                                             │
  │       ├── v1 → v2: add 'priority' column                    │
  │       └── v2 → v3: create Notifications table               │
  └──────────────────────┬──────────────────────────────────────┘
                         │
              ┌──────────┴───────────┐
              │                      │
  ┌───────────▼──────────┐  ┌───────▼────────────┐
  │      EventDao        │  │     TicketDao      │
  │  (DatabaseAccessor)  │  │  (DatabaseAccessor)│
  │                      │  │                    │
  │  getAllEvents()       │  │  getMyTickets()    │
  │  watchAllEvents() ◀──stream  getByEventId()  │
  │  getByRemoteId()     │  │  insertTicket()    │
  │  insertEvent()       │  │  deleteTicket()    │
  │  deleteByRemoteId()  │  │                    │
  └──────────────────────┘  └────────────────────┘

  Repository Offline Strategy:

  ┌─────────┐    try     ┌─────────┐   cache    ┌─────────┐
  │ Screen  │──────────▶│  API    │──────────▶│  Drift  │
  │         │            │ Service │            │   DAO   │
  └─────────┘            └────┬────┘            └────┬────┘
                              │                      │
                         ┌────┴────┐                 │
                         │ Network │                 │
                         │  Error? │                 │
                         └────┬────┘                 │
                              │ yes                  │
                              └──────── read ───────▶│
                                       cache         │
```

---

### M5: GraphQL & Remote Config (Week 11–12)

**Concepts:** C4 (GraphQL), C14, C16

- [ ] Set up GraphQL client provider with DioLink
- [ ] Download/create schema file
- [ ] Write `GetEventDetail.graphql` and `GetEvents.graphql`
- [ ] Run codegen — typed query/variable/result classes generated
- [ ] Build `EventRemoteDataSource` using generated GraphQL extensions
- [ ] Implement remote config: fetch → cache → typed getters
- [ ] Add feature flag: `isTicketSalesEnabled` controlling purchase CTA visibility
- [ ] Load config during splash, available synchronously to all features
- [ ] Set up `AppConfig` provider with `--dart-define-from-file`

**Exit Criteria:** Event detail loads via GraphQL. Feature flag hides/shows purchase button. Environment switching works.

```
M5 — Dual Protocol + Config Architecture:

  ┌─────────────────────────────────────────────────────────────┐
  │                    Two Data Protocols                         │
  │                                                              │
  │    REST (writes)              GraphQL (reads)                │
  │    ┌─────────────┐           ┌──────────────────┐           │
  │    │  POST /buy  │           │ query GetEvent   │           │
  │    │  PUT /user  │           │ query GetEvents  │           │
  │    │  POST /scan │           │                  │           │
  │    └──────┬──────┘           └────────┬─────────┘           │
  │           │                           │                     │
  │           │      Shared Dio           │                     │
  │           │    ┌──────────┐           │                     │
  │           └───▶│   Dio    │◀──────────┘                     │
  │                │ + Auth   │   (via DioLink)                 │
  │                │ + Error  │                                  │
  │                │ + Log    │                                  │
  │                └──────────┘                                  │
  └─────────────────────────────────────────────────────────────┘

  Remote Config Flow:

  App Launch
      │
      ▼
  ┌──────────────┐   fetch    ┌──────────────┐
  │    Splash    │──────────▶│   Backend    │
  │    Screen    │            │ /config      │
  └──────┬───────┘            └──────┬───────┘
         │                           │
         │      ┌────────────────────┘
         │      │ response
         │      ▼
         │   ┌──────────────────────┐
         │   │  SharedPreferences   │  ◀── cache locally
         │   │  (offline fallback)  │
         │   └──────────┬───────────┘
         │              │
         ▼              ▼
  ┌─────────────────────────────────┐
  │   appConfigurationProvider      │
  │   (keepAlive, loaded once)      │
  │                                  │
  │   config.isEventsEnabled ──▶ 🟢 │
  │   config.isTicketSalesEnabled ▶ 🔴 (hidden)
  │   config.maxUploadSizeBytes     │
  └─────────────────────────────────┘
```

---

### M6: UI Polish — Theming, i18n, Responsive (Week 13–14)

**Concepts:** C8, C9, C10, C20

- [ ] Build `AppTheme` with `ColorScheme.fromSeed()` + brand overrides
- [ ] Create `ThemeExtension<AppColors>` with success/warning/info tokens
- [ ] Implement `ThemeModeNotifier` with SharedPreferences persistence
- [ ] Build `AppSpacing` elastic spacing utility
- [ ] Apply responsive layout to event list: single-column phone, two-column tablet
- [ ] Set up Slang with `en.i18n.yaml` and `ar.i18n.yaml`
- [ ] Replace all hardcoded strings with `t.key.subkey`
- [ ] Configure SVG → `.vec` compilation
- [ ] Set up `flutter_native_splash`
- [ ] Review: zero `Colors.*` references in widget files
- [ ] Review: zero hardcoded font sizes

**Exit Criteria:** Light/dark mode toggle works. Arabic locale works. Tablet layout adapts. All icons are SVG-compiled.

```
M6 — UI Architecture:

  ┌─────────────────────────────────────────────────────────────┐
  │                   Theme System                                │
  │                                                               │
  │   AppTheme.light ◀──┐    ┌──▶ AppTheme.dark                  │
  │                      │    │                                   │
  │              ThemeModeNotifier                                │
  │              (persisted to SharedPrefs)                       │
  │              ┌────────────────────────┐                       │
  │              │  system │ light │ dark │                       │
  │              └────────────────────────┘                       │
  │                                                               │
  │   Widget Access:                                              │
  │   ├── colorScheme.primary     (M3 role)                       │
  │   ├── colorScheme.surface     (M3 role)                       │
  │   ├── context.appColors.success (ThemeExtension)              │
  │   └── textTheme.headlineMedium (M3 type scale)               │
  │                                                               │
  │   FORBIDDEN:                                                  │
  │   ✗ Colors.red                                                │
  │   ✗ TextStyle(fontSize: 24)                                   │
  │   ✗ AppPalette.primary600  (in widgets)                       │
  └─────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────┐
  │                   i18n Pipeline                               │
  │                                                               │
  │   assets/i18n/en.i18n.yaml ──┐                                │
  │   assets/i18n/ar.i18n.yaml ──┤                                │
  │                               ▼                               │
  │                       dart run slang                           │
  │                               │                               │
  │                               ▼                               │
  │                    lib/core/i18n/strings.g.dart                │
  │                               │                               │
  │                               ▼                               │
  │                     t.events.title  ◀── type-safe!             │
  │                     t.errors.network                           │
  │                     context.t.auth.login ◀── reactive          │
  └─────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────┐
  │                SVG Build Pipeline                             │
  │                                                               │
  │   assets/svg/icon.svg                                         │
  │        │                                                      │
  │        ▼  (build-time via vector_graphics_compiler)           │
  │   assets/svg/icon.vec  ◀── binary, zero runtime parsing      │
  │        │                                                      │
  │        ▼                                                      │
  │   SvgPicture.asset('assets/svg/icon.svg')  ◀── in widget     │
  └─────────────────────────────────────────────────────────────┘
```

---

### M7: Platform Features (Week 15–16)

**Concepts:** C11, C12, C13, C19

- [ ] Configure Android App Links (`assetlinks.json`, intent-filter)
- [ ] Configure iOS Universal Links (`apple-app-site-association`, entitlements)
- [ ] Deep link `https://eventhub.com/app/events/{id}` opens Event Detail
- [ ] Handle initial link (app opened from terminated state)
- [ ] Set up FCM: `google-services.json`, APNs key
- [ ] Build `NotificationService` with channels (events, reminders)
- [ ] Foreground notification display via local notifications
- [ ] Tap notification → deep link → navigate to correct screen
- [ ] Build QR Scanner screen with scan window and torch toggle
- [ ] Process QR result → POST check-in → show valid/invalid result
- [ ] Add adaptive dialogs for confirm actions (cancel ticket, logout)

**Exit Criteria:** Share event link → tap → app opens to event detail. Push received in all app states. QR check-in works end-to-end.

```
M7 — Platform Integration Map:

  ┌─────────────────────────────────────────────────────────────────┐
  │                DEEP LINKING                                     │
  │                                                                 │
  │   ┌──────────────────────┐    ┌──────────────────────┐          │
  │   │ Android App Links    │    │ iOS Universal Links  │          │
  │   │ assetlinks.json      │    │ AASA file            │          │
  │   │ autoVerify=true      │    │ Associated Domains   │          │
  │   └──────────┬───────────┘    └──────────┬───────────┘          │
  │              └──────────┬───────────────┘                       │
  │                         ▼                                       │
  │                   app_links                                     │
  │                    package                                      │
  │                         │                                       │
  │             ┌───────────┴───────────┐                           │
  │             │   GoRouter resolves   │                           │
  │             │    /events/:id  ───▶ EventDetailScreen             │
  │             │    /tickets/:id ───▶ TicketDetailScreen            │
  │             └───────────────────────┘                           │
  └─────────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────────┐
  │             PUSH NOTIFICATIONS                                  │
  │                                                                 │
  │   ┌─────────────┐                                               │
  │   │ FCM Server  │                                               │
  │   └──────┬──────┘                                               │
  │          │  message payload                                     │
  │          ▼                                                      │
  │   ┌─────────────────────────────────────────┐                   │
  │   │      firebase_messaging                 │                   │
  │   │                                         │                   │
  │   │  ┌─────────┐ ┌────────────┐ ┌────────┐  │                   │
  │   │  │Foreground│ │ Background │ │Terminat│  │                   │
  │   │  │ onMsg    │ │ onBgMsg() │ │ getInit│  │                   │
  │   │  └────┬────┘ └─────┬──────┘ └───┬────┘  │                   │
  │   │       │            │            │       │                   │
  │   │       ▼            ▼            ▼       │                   │
  │   │  flutter_local_notifications            │                   │
  │   │       (show / handle tap)               │                   │
  │   └──────────────┬──────────────────────────┘                   │
  │                  │  route from payload                          │
  │                  ▼                                              │
  │            GoRouter.go(deepLink)                                │
  └─────────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────────┐
  │              QR CODE SCANNING                                   │
  │                                                                 │
  │   ┌─────────────────────┐                                       │
  │   │  mobile_scanner v7  │                                       │
  │   │  (ML Kit / Vision)  │                                       │
  │   └──────────┬──────────┘                                       │
  │              │                                                  │
  │              ▼                                                  │
  │   ┌──────────────────────┐      ┌──────────────────┐            │
  │   │  Scan Window (ROI)   │ ───▶ │ Parse QR Payload │            │
  │   │  [Guided Overlay]    │      │ {ticketId, code}  │           │
  │   └──────────────────────┘      └────────┬─────────┘            │
  │                                          │                     │
  │                                          ▼                     │
  │                               ┌────────────────────┐           │
  │                               │  POST /check-in    │           │
  │                               │  ─▶ Success ✓      │           │
  │                               │  ─▶ Already Used ✗  │          │
  │                               │  ─▶ Invalid ✗      │           │
  │                               └────────────────────┘           │
  └─────────────────────────────────────────────────────────────────┘
```

---

### M8: Testing (Week 17–18)

**Concepts:** C18

- [ ] Set up test helpers: `mocks.dart`, `fakes.dart`, `test_app.dart`
- [ ] Unit tests: all Freezed entities (equality, copyWith, serialization)
- [ ] Unit tests: repository implementations (API success, API failure → cache)
- [ ] Controller tests: `ProviderContainer` with mock repository overrides
- [ ] Widget tests: every screen (data, loading, error states)
- [ ] Drift tests: DAO operations with in-memory database
- [ ] Integration test: login → view events → purchase ticket → view my tickets
- [ ] Achieve 80%+ coverage on `events` and `tickets` features
- [ ] Run `flutter test --coverage` and verify

**Exit Criteria:** 80%+ coverage on two features. All widget tests pass. Integration test passes.

```
M8 — Testing Pyramid:

                          ╱╲
                         ╱  ╲
                        ╱ E2E╲
                       ╱──────╲        ← 1-2 integration tests
                      ╱ Integr.╲         (login → buy ticket → view)
                     ╱──────────╲
                    ╱   Widget   ╲      ← Every screen × 3 states
                   ╱──────────────╲       (data, loading, error)
                  ╱     Unit       ╲    ← Entities, repos, controllers
                 ╱──────────────────╲     (mock repos via overrides)
                ╱────────────────────╲

  Test Infrastructure:

  test/
  ├── helpers/
  │   ├── mocks.dart           ◀── @GenerateMocks([EventsRepository, ...])
  │   ├── fakes.dart           ◀── FakeEvent(), FakeTicket()
  │   └── test_app.dart        ◀── ProviderScope + overrides + MaterialApp
  │
  ├── features/
  │   ├── events/
  │   │   ├── data/
  │   │   │   └── events_repo_test.dart    ← mock API, verify fallback
  │   │   ├── domain/
  │   │   │   └── event_entity_test.dart   ← equality, copyWith, JSON
  │   │   ├── presentation/
  │   │   │   ├── events_controller_test.dart ← ProviderContainer
  │   │   │   └── events_screen_test.dart    ← pump + verify widgets
  │   │   └── drift/
  │   │       └── events_dao_test.dart     ← in-memory DB
  │   └── tickets/
  │       └── ...  (mirror events)
  │
  └── integration/
      └── purchase_flow_test.dart          ← full login → purchase → view

  Test Pattern per Layer:
  ┌───────────────────────────────────────────────────────────────┐
  │  UNIT (Repository)                                           │
  │  ┌──────────────┐   mock success   ┌─────────────────┐       │
  │  │ MockApiService│ ───────────────▶ │ verify entities │       │
  │  │              │   mock failure   │ verify fallback │       │
  │  └──────────────┘ ───────────────▶ │ to cached data  │       │
  │                                    └─────────────────┘       │
  ├───────────────────────────────────────────────────────────────┤
  │  CONTROLLER (AsyncNotifier)                                  │
  │  ┌──────────────────────┐   ┌──────────────────────────┐     │
  │  │ ProviderContainer     │   │ verify AsyncValue states │     │
  │  │ + repository override │──▶│ loading → data / error   │     │
  │  └──────────────────────┘   └──────────────────────────┘     │
  ├───────────────────────────────────────────────────────────────┤
  │  WIDGET (Screen)                                             │
  │  ┌─────────────┐    ┌──────────────────────────────────┐     │
  │  │ testApp()    │    │ pumpWidget → find text/buttons   │     │
  │  │ wrapper with │───▶│ verify loading spinner shown     │     │
  │  │ mock provider│    │ verify error message displayed   │     │
  │  └─────────────┘    └──────────────────────────────────┘     │
  └───────────────────────────────────────────────────────────────┘
```

---

### M9: Performance & CI/CD (Week 19–20)

**Concepts:** C15, C17

- [ ] Audit all lists for `ListView.builder` usage
- [ ] Add `const` constructors where missing
- [ ] Add `itemExtent` to uniform-height lists
- [ ] Replace `Image.network` with `CachedNetworkImage`
- [ ] Profile with DevTools: all frames under 16ms
- [ ] Measure cold start: under 3s on mid-range device
- [ ] Set up GitHub Actions CI workflow: analyze → test → build
- [ ] Configure Fastlane for iOS (Match + Firebase App Distribution)
- [ ] Configure Fastlane for Android (Firebase App Distribution)
- [ ] Set up Shorebird: `shorebird init`, `shorebird release`
- [ ] Test OTA patch: `shorebird patch android`
- [ ] Add caching to CI (pub, Gradle, CocoaPods)

**Exit Criteria:** CI green on every push. Beta distributed to testers. OTA patch delivered successfully.

```
M9 — CI/CD Pipeline & Performance Budgets:

  ┌─────────────────────────────────────────────────────────────────┐
  │                GitHub Actions Workflow                          │
  │                                                                 │
  │   git push ───▶ ┌─────────┐   ┌──────────┐   ┌─────────────┐  │
  │                 │ Analyze │──▶│   Test   │──▶│    Build    │  │
  │                 │ dart    │   │ flutter  │   │ APK / IPA   │  │
  │                 │ analyze │   │ test     │   │             │  │
  │                 └─────────┘   └──────────┘   └──────┬──────┘  │
  │                                                      │         │
  │                               ┌──────────────────────┘         │
  │                               ▼                                │
  │                 ┌───────────────────────────┐                   │
  │                 │   Fastlane Distribution    │                  │
  │                 │                           │                   │
  │                 │  Android ──▶ Firebase AD   │                  │
  │                 │  iOS ──────▶ Firebase AD   │                  │
  │                 │   (Match certificates)     │                  │
  │                 └──────────────┬────────────┘                   │
  │                                │                               │
  │                                ▼                               │
  │                 ┌───────────────────────────┐                   │
  │                 │   Shorebird OTA Patch     │                   │
  │                 │                           │                   │
  │                 │  shorebird release ──▶ v1  │                  │
  │                 │  fix bug ──▶ shorebird     │                  │
  │                 │        patch android       │                  │
  │                 │  users get patch silently  │                  │
  │                 └───────────────────────────┘                   │
  └─────────────────────────────────────────────────────────────────┘

  Cache Strategy (speeds up CI by ~60%):
  ┌────────────────────────────────────────────────────┐
  │  Cache Key Format: runner.os + hashFiles(lock)     │
  │                                                    │
  │  ┌────────────┐  ┌────────────┐  ┌──────────────┐  │
  │  │ Pub Cache  │  │  Gradle    │  │  CocoaPods   │  │
  │  │ ~/.pub-cach│  │ ~/.gradle/ │  │ ~/Library/   │  │
  │  │ pubspec.lo │  │ build.grad │  │ Caches/Cocoa │  │
  │  └────────────┘  └────────────┘  └──────────────┘  │
  └────────────────────────────────────────────────────┘

  Performance Budgets:
  ┌─────────────────────────────────────────────────┐
  │  Metric             │  Budget    │  Tool        │
  │─────────────────────┼────────────┼──────────────│
  │  Frame render       │  < 16ms    │  DevTools    │
  │  Cold start         │  < 3s      │  Stopwatch   │
  │  APK size           │  < 25MB    │  --analyze   │
  │  Widget rebuilds    │  minimal   │  select()    │
  │  List scrolling     │  60fps     │  builder+ext │
  │  Image loading      │  cached    │  CachedImg   │
  │  SVG rendering      │  precomp   │  .vec files  │
  └─────────────────────────────────────────────────┘
```

---

## Spec-First Workflow

For every feature, follow this sequence **before writing any code**:

```
Spec-First Workflow — Visual Pipeline:

  ┌─────┐    ┌─────────┐    ┌──────────┐    ┌───────────┐
  │STEP │    │  STEP   │    │  STEP    │    │  STEP     │
  │  1  │───▶│    2    │───▶│    3     │───▶│    4      │
  │SPEC │    │CONTRACT │    │ENTITIES  │    │  TESTS    │
  │     │    │         │    │ & DTOs   │    │  FIRST    │
  └─────┘    └─────────┘    └──────────┘    └─────┬─────┘
                                                   │
       ┌───────────────────────────────────────────┘
       │
       ▼
  ┌──────────┐    ┌───────────┐    ┌──────────────┐
  │  STEP    │    │  STEP     │    │    STEP      │
  │    5     │───▶│    6      │───▶│      7       │
  │IMPLEMENT │    │WIRE &     │    │  REVIEW      │
  │(inside→out)   │VERIFY     │    │  CHECKLIST   │
  └──────────┘    └───────────┘    └──────────────┘

  Time Flow:
  ─────────────────────────────────────────────────▶
  THINK          DEFINE         BUILD       VERIFY
  (spec+contract) (entities+tests) (impl)   (wire+review)
```

### Step 1: Spec (Document)

```
docs/specs/<feature>-spec.md
├── Problem statement
├── User stories (As a..., I want..., So that...)
├── Acceptance criteria (Given/When/Then)
├── API contract (request/response shapes)
├── Screen wireframes (ASCII or Figma link)
└── Edge cases & error states

  Example:
  ┌──────────────────────────────────────────────────────┐
  │  docs/specs/events-spec.md                           │
  │                                                      │
  │  ## Problem                                          │
  │  Users need to discover and browse upcoming events.  │
  │                                                      │
  │  ## User Story                                       │
  │  As a user, I want to see a list of events           │
  │  so that I can find ones I'm interested in.          │
  │                                                      │
  │  ## Acceptance Criteria                              │
  │  Given I am on the Events screen                     │
  │  When events load successfully                       │
  │  Then I see a scrollable list with title, date, loc  │
  │                                                      │
  │  ## API Contract                                     │
  │  GET /api/events → { data: Event[], total: int }     │
  │                                                      │
  │  ## Wireframe                                        │
  │  ┌─────────────────────┐                             │
  │  │ ◀  Events           │                             │
  │  │─────────────────────│                             │
  │  │ 🔍 Search...        │                             │
  │  │─────────────────────│                             │
  │  │ ┌─────────────────┐ │                             │
  │  │ │ Flutter Conf '25│ │                             │
  │  │ │ Jun 15 • Cairo  │ │                             │
  │  │ └─────────────────┘ │                             │
  │  │ ┌─────────────────┐ │                             │
  │  │ │ Dart Meetup     │ │                             │
  │  │ │ Jun 22 • Alex   │ │                             │
  │  │ └─────────────────┘ │                             │
  │  └─────────────────────┘                             │
  └──────────────────────────────────────────────────────┘
```

### Step 2: Contract (Interfaces)

```dart
// domain/repositories/<feature>_repository.dart
abstract class FeatureRepository {
  Future<List<Entity>> getAll();
  Future<Entity> getById(String id);
  Future<void> create(CreateRequest request);
}

// Dependency direction:
//
//   ┌──────────────┐        ┌──────────────────┐
//   │ Presentation │ ─uses─▶│ Domain           │
//   │ (Controller) │        │ (Abstract Repo)  │
//   └──────────────┘        └────────▲─────────┘
//                                    │ implements
//                           ┌────────┴─────────┐
//                           │ Data             │
//                           │ (RepoImpl+API)   │
//                           └──────────────────┘
```

### Step 3: Entities & DTOs

```dart
// domain/entities/entity.dart     → Freezed, no JSON
// data/models/entity_dto.dart     → Freezed + JSON, toEntity()

// Conversion flow:
//
//   API JSON ──fromJson──▶ EventDto ──toEntity()──▶ Event (domain)
//                               │
//                               ▼
//                          EventsCompanion ──▶ Drift DB (local cache)
```

### Step 4: Tests First

```dart
// Write failing tests for repository, controller, and screen
// They define expected behavior before implementation exists

// Red → Green → Refactor:
//
//   ┌─────────┐     ┌─────────┐     ┌───────────┐
//   │  RED    │────▶│  GREEN  │────▶│ REFACTOR  │
//   │ Write   │     │ Make it │     │ Clean up  │
//   │ failing │     │ pass    │     │ keep green│
//   │ test    │     │         │     │           │
//   └─────────┘     └─────────┘     └───────────┘
```

### Step 5: Implementation (Inside-Out)

```
1. Data layer: API service (Retrofit) → DAO (Drift) → Repository impl
2. State layer: Controller (AsyncNotifier)
3. UI layer: Screen (ConsumerWidget)

  Build Direction (inside → out):

  ┌──────────────────────────────────────────────────────────┐
  │                                                          │
  │                    ③ UI Layer                             │
  │           ┌──────────────────────────┐                   │
  │           │  ConsumerWidget Screen   │                   │
  │           │  ref.watch(controller)   │                   │
  │           └────────────┬─────────────┘                   │
  │                        │ watches                         │
  │                        ▼                                 │
  │                 ② State Layer                            │
  │           ┌──────────────────────────┐                   │
  │           │  AsyncNotifier           │                   │
  │           │  AsyncValue.guard(...)   │                   │
  │           └────────────┬─────────────┘                   │
  │                        │ calls                           │
  │                        ▼                                 │
  │              ① Data Layer  (BUILD FIRST)                 │
  │   ┌──────────────┬───────────────┬───────────────┐       │
  │   │ Retrofit API │   Drift DAO   │  Repository   │       │
  │   │ (network)    │   (cache)     │  (orchestrate)│       │
  │   └──────────────┴───────────────┴───────────────┘       │
  │                                                          │
  └──────────────────────────────────────────────────────────┘
```

### Step 6: Wire & Verify

```
1. Add providers to feature's providers.dart
2. Add routes to feature's routes.dart
3. Run build_runner
4. Run tests
5. Manual smoke test
6. Check coverage: flutter test --coverage

  Wiring Checklist Flow:

  providers.dart ──▶ routes.dart ──▶ build_runner ──▶ tests
       │                 │                │              │
       ▼                 ▼                ▼              ▼
  Export repo +     Add GoRoute      Generate .g.dart   All pass?
  controller         + screen        + .freezed.dart       │
  providers           path                              ┌──┴──┐
                                                        │ YES │ → smoke test ✓
                                                        │ NO  │ → fix & rerun
                                                        └─────┘
```

### Step 7: Review Checklist

```
  ┌─────────────────────────────────────────────────────────────┐
  │                    REVIEW CHECKLIST                         │
  │                                                             │
  │  ── i18n ──────────────────────────────────────────────     │
  │  □ No hardcoded strings (all through t.key)                 │
  │  □ New strings added to all locale YAML files               │
  │                                                             │
  │  ── Theming ───────────────────────────────────────────     │
  │  □ No hardcoded colors (all through colorScheme/appColors)  │
  │                                                             │
  │  ── Architecture ──────────────────────────────────────     │
  │  □ No direct Dio usage in presentation/domain               │
  │  □ Repository exposed as abstract type                      │
  │  □ Controller uses AsyncValue.guard()                       │
  │  □ Error states handled in .when()                          │
  │                                                             │
  │  ── Performance ───────────────────────────────────────     │
  │  □ const constructors where possible                        │
  │  □ select() used for expensive watches                      │
  │                                                             │
  │  ── Testing ───────────────────────────────────────────     │
  │  □ Tests cover success, error, loading, and edge cases      │
  │                                                             │
  │  ALL CHECKED? ───▶ ✅ MERGE-READY                          │
  └─────────────────────────────────────────────────────────────┘
```

---

## Concept Coverage Matrix

| Concept                                   | Milestone(s)                  |
| ----------------------------------------- | ----------------------------- |
| C1. State Management (Riverpod)           | M2, M3, M4, M5                |
| C2. Clean Architecture (Feature Slices)   | M1, M2, M3, M4, M5            |
| C3. Code Generation                       | M1, M2, M3, M4, M5, M6        |
| C4. Networking (Dio + Retrofit + GraphQL) | M3, M5                        |
| C5. Error Handling                        | M3                            |
| C6. Authentication                        | M3                            |
| C7. Local Database (Drift)                | M4                            |
| C8. Theming (M3)                          | M6                            |
| C9. Responsive Design                     | M6                            |
| C10. Internationalization (Slang)         | M6                            |
| C11. Deep Linking                         | M7                            |
| C12. Push Notifications                   | M7                            |
| C13. QR Scanning                          | M7                            |
| C14. Remote Config                        | M5                            |
| C15. Performance                          | M9                            |
| C16. Environment Config                   | M1, M5                        |
| C17. CI/CD                                | M9                            |
| C18. Testing                              | M8                            |
| C19. Platform-Specific                    | M7                            |
| C20. Splash + SVG                         | M6                            |
| C21. Phased Retry (Backend)               | M3 (error handling awareness) |

**Every concept from the docs is exercised at least once.**
