# Deep Learning Roadmap

---

## How to Use This Roadmap

Each phase builds on the previous one. Complete all concepts in a phase before moving to the next. The **project** column shows which milestone of the capstone project exercises that concept.

---

## The Big Picture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    YOUR FLUTTER MASTERY JOURNEY                      │
│                                                                      │
│  ┌─────────┐   ┌──────────┐   ┌──────────┐   ┌──────────────────┐  │
│  │ Phase 1  │──▶│ Phase 2  │──▶│ Phase 3  │──▶│    Phase 4       │  │
│  │Foundation│   │  State   │   │Networking│   │ Authentication   │  │
│  │ Week 1-2 │   │ Week 3-4 │   │ Week 5-7 │   │    Week 8        │  │
│  └─────────┘   └──────────┘   └──────────┘   └────────┬─────────┘  │
│                                                        │             │
│                                           ┌────────────┴──────┐     │
│                                           │                   │     │
│                                      ┌────▼─────┐    ┌───────▼──┐  │
│                                      │ Phase 5  │    │ Phase 6  │  │
│                                      │UI Polish │    │ Platform │  │
│                                      │ Week 9-10│    │Week 11-12│  │
│                                      └────┬─────┘    └───────┬──┘  │
│                                           │                  │      │
│                                           └────────┬─────────┘      │
│                                                    │                │
│                                              ┌─────▼──────┐        │
│                                              │  Phase 7   │        │
│                                              │  Testing   │        │
│                                              │ Week 13-14 │        │
│                                              └─────┬──────┘        │
│                                                    │                │
│                                              ┌─────▼──────┐        │
│                                              │  Phase 8   │        │
│                                              │Performance │        │
│                                              │  & CI/CD   │        │
│                                              │ Week 15-16 │        │
│                                              └────────────┘        │
│                                                    ║                │
│                                                    ║                │
│                                              ╔═════╩══════╗        │
│                                              ║ PRODUCTION ║        │
│                                              ║   READY    ║        │
│                                              ╚════════════╝        │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Skill Level Progression

```
Level  ──────────────────────────────────────────────────────▶

        Phase 1-2             Phase 3-4             Phase 5-8
       ┌──────────┐         ┌──────────┐         ┌──────────┐
       │          │         │          │         │          │
       │  JUNIOR  │────────▶│   MID    │────────▶│  SENIOR  │
       │          │         │          │         │          │
       └──────────┘         └──────────┘         └──────────┘

       • Freezed            • Dio + Retrofit      • M3 Theming
       • build_runner        • Error pipeline      • Deep links
       • Riverpod basics     • Auth lifecycle       • Push notifications
       • Project structure   • Drift + DAOs         • CI/CD pipeline
       • JSON serialization  • GraphQL              • 80% test coverage
                             • Token refresh        • Performance tuning
```

---

## Phase 1: Foundation Layer (Weeks 1–2)

> Goal: Master the tools everything else is built on.

| #   | Concept                                                                 | Source Doc                                 | Project Milestone |
| --- | ----------------------------------------------------------------------- | ------------------------------------------ | ----------------- |
| 1.1 | Dart sealed classes & pattern matching                                  | `state-management.md`, `error-handling.md` | M1                |
| 1.2 | Freezed: immutable data classes, unions, `copyWith`                     | `code-generation.md`                       | M1                |
| 1.3 | `build_runner` engine: how generators work, `part` directives, commands | `code-generation.md`                       | M1                |
| 1.4 | `json_serializable`: `fromJson` / `toJson`                              | `code-generation.md`                       | M1                |
| 1.5 | Project structure: feature slices, barrel files, layer responsibilities | `project-structure.md`                     | M1                |

### Deliverable

- Create 3 Freezed entity classes with JSON serialization
- Set up the project scaffold with 2 empty feature slices
- Run `build_runner` successfully with all generators

```
Phase 1 Output:

  you write        build_runner       you get
  ─────────        ───────────        ───────
  ┌──────────┐     ┌──────────┐     ┌──────────────┐
  │ @freezed │────▶│ analyze  │────▶│ .freezed.dart │
  │ @JsonSer │     │ generate │     │    .g.dart    │
  │ @riverpod│     │  emit    │     │    .g.dart    │
  └──────────┘     └──────────┘     └──────────────┘
       │                                   │
       └──── your code compiles with ──────┘
```

---

## Phase 2: State Management Mastery (Weeks 3–4)

> Goal: Own every Riverpod pattern used in production.

| #   | Concept                                                                  | Source Doc             | Project Milestone |
| --- | ------------------------------------------------------------------------ | ---------------------- | ----------------- |
| 2.1 | Provider types: `Provider`, `FutureProvider`, `@riverpod` function/class | `state-management.md`  | M2                |
| 2.2 | `AsyncNotifier` controller pattern (one per screen)                      | `state-management.md`  | M2                |
| 2.3 | `ref.watch` vs `ref.read` vs `ref.listen`                                | `state-management.md`  | M2                |
| 2.4 | Family providers (parameterized)                                         | `state-management.md`  | M2                |
| 2.5 | Derived providers, `select()` for rebuild optimization                   | `state-management.md`  | M2                |
| 2.6 | Feature-scoped DI wiring (`providers.dart`)                              | `project-structure.md` | M2                |
| 2.7 | `riverpod_generator` codegen deep dive                                   | `code-generation.md`   | M2                |

### Deliverable

- Build a feature with full provider graph: API service → repository → controller → screen
- Demonstrate `select()` optimization with DevTools rebuild tracking

```
Phase 2 — Riverpod Provider Graph:

  ┌─────────────────────────────────────────────────────────┐
  │                    Widget Tree                           │
  │                                                          │
  │   ref.watch(controllerProvider)                          │
  │         │                                                │
  │         │  ┌──────────────────────────────────────────┐  │
  │         └─▶│  orderListControllerProvider             │  │
  │            │  (AsyncNotifier — one per screen)        │  │
  │            │                                          │  │
  │            │  ref.watch(repositoryProvider)            │  │
  │            └────────────┬─────────────────────────────┘  │
  │                         │                                │
  │            ┌────────────▼─────────────────────────────┐  │
  │            │  orderRepositoryProvider                  │  │
  │            │  (abstract type — dependency inversion)   │  │
  │            │                                          │  │
  │            │  ref.watch(apiProvider)                    │  │
  │            │  ref.watch(daoProvider)                    │  │
  │            └──────┬──────────────┬────────────────────┘  │
  │                   │              │                        │
  │         ┌─────────▼──┐   ┌──────▼──────┐                │
  │         │ apiService │   │  orderDao   │                │
  │         │ (Retrofit) │   │  (Drift)    │                │
  │         └─────────┬──┘   └──────┬──────┘                │
  │                   │              │                        │
  │              ┌────▼────┐   ┌────▼────┐                   │
  │              │   Dio   │   │ SQLite  │                   │
  │              └─────────┘   └─────────┘                   │
  └─────────────────────────────────────────────────────────┘

  ref.watch  → reactive (rebuilds UI on change)
  ref.read   → one-shot (callbacks, event handlers)
  ref.listen → side effects (snackbars, navigation)
  select()   → watch only a subset (minimize rebuilds)
```

---

## Phase 3: Networking & Data Layer (Weeks 5–7)

> Goal: Build a complete remote + local data pipeline.

| #   | Concept                                                      | Source Doc                      | Project Milestone |
| --- | ------------------------------------------------------------ | ------------------------------- | ----------------- |
| 3.1 | Dio client: singleton, base URL, timeouts, interceptor chain | `networking.md`                 | M3                |
| 3.2 | Retrofit: `@RestApi()`, type-safe API services               | `networking.md`                 | M3                |
| 3.3 | `AppException` sealed class + `ErrorInterceptor`             | `error-handling.md`             | M3                |
| 3.4 | Auth interceptor: token injection, 401 handling              | `authentication.md`             | M3                |
| 3.5 | Repository pattern: remote-first with local fallback         | `database.md`                   | M3                |
| 3.6 | Drift: table definitions, DAOs, queries, streams             | `database.md`, `drift_tutor.md` | M4                |
| 3.7 | Drift migrations: version bumps, incremental steps           | `database.md`                   | M4                |
| 3.8 | GraphQL client: `gql_dio_link`, codegen, queries             | `graphql.md`                    | M5                |

### Deliverable

- Complete networking layer with error interceptor
- Retrofit API service + Drift DAO for one feature
- Repository implementation with cache fallback on network error

```
Phase 3 — The Data Pipeline:

  ┌──────────────┐
  │   Server     │
  │   (REST +    │
  │   GraphQL)   │
  └──────┬───────┘
         │  HTTP
         ▼
  ┌──────────────────────────────────────────────────┐
  │                    Dio Client                      │
  │                                                    │
  │  Request flow:                                     │
  │  ┌──────────┐   ┌──────────┐   ┌──────────────┐  │
  │  │  Error   │──▶│   Auth   │──▶│    Log       │  │
  │  │Interceptor│   │Interceptor│   │ Interceptor  │  │
  │  └──────────┘   └──────────┘   └──────────────┘  │
  │       │               │                            │
  │       │          Injects Bearer token              │
  │       │                                            │
  │       ▼                                            │
  │  Maps DioException → AppException                  │
  │  ┌──────────────────────────────┐                  │
  │  │     AppException (sealed)    │                  │
  │  │  ├─ NetworkException         │                  │
  │  │  ├─ ServerException(code)    │                  │
  │  │  ├─ UnauthorizedException    │◀── triggers      │
  │  │  ├─ ValidationException      │    token refresh  │
  │  │  └─ UnknownException         │    or logout      │
  │  └──────────────────────────────┘                  │
  └──────────────────────────────────────────────────┘
         │
         ▼
  ┌──────────────────────────────────────────────────┐
  │              Repository (data layer)               │
  │                                                    │
  │  try {                                             │
  │    remote ──▶ cache locally ──▶ return entities    │
  │  } catch (NetworkException) {                      │
  │    return cached data from Drift  ◀── offline      │
  │  }                                    fallback     │
  └──────────────────────────────────────────────────┘
         │
         ▼
  ┌──────────────────┐
  │   Controller     │
  │  AsyncValue:     │
  │  ┌──────┐        │
  │  │ data │ ✅     │
  │  ├──────┤        │
  │  │loading│ ⏳    │
  │  ├──────┤        │
  │  │error │ ❌     │
  │  └──────┘        │
  └──────────────────┘
```

---

## Phase 4: Authentication System (Week 8)

> Goal: Implement the full auth lifecycle.

| #   | Concept                                                              | Source Doc          | Project Milestone |
| --- | -------------------------------------------------------------------- | ------------------- | ----------------- |
| 4.1 | `AuthState` sealed class (authenticated / unauthenticated / loading) | `authentication.md` | M3                |
| 4.2 | `AuthController` Riverpod notifier + derived providers               | `authentication.md` | M3                |
| 4.3 | `QueuedInterceptor` for token refresh (serialize concurrent 401s)    | `authentication.md` | M3                |
| 4.4 | GoRouter auth guard with automatic redirect                          | `authentication.md` | M3                |
| 4.5 | Token persistence via `SharedPreferences`                            | `authentication.md` | M3                |

### Deliverable

- Full login → authenticated → token refresh → logout → redirect cycle
- Simulate 401 → refresh → retry flow

```
Phase 4 — Auth Lifecycle:

  ┌─────────┐                    ┌─────────────┐
  │  User   │                    │  GoRouter   │
  │  opens  │                    │  Auth Guard │
  │   app   │                    └──────┬──────┘
  └────┬────┘                           │
       │                                │
       ▼                                ▼
  ┌─────────────────────────────────────────────────┐
  │              AuthController (Riverpod)           │
  │                                                  │
  │  AuthState (sealed class):                       │
  │                                                  │
  │  ┌────────────────┐                              │
  │  │ Unauthenticated│─── app start / logout        │
  │  └───────┬────────┘                              │
  │          │ login()                               │
  │          ▼                                       │
  │  ┌────────────────┐                              │
  │  │    Loading     │─── verifying OTP...          │
  │  └───────┬────────┘                              │
  │          │ success                               │
  │          ▼                                       │
  │  ┌────────────────┐                              │
  │  │ Authenticated  │─── user + tokens stored      │
  │  │  {user, access,│                              │
  │  │   refresh}     │                              │
  │  └───────┬────────┘                              │
  │          │                                       │
  └──────────┼───────────────────────────────────────┘
             │
             ▼
  ┌──────────────────────────────────────────────────┐
  │           Token Refresh Flow (401)                │
  │                                                   │
  │  Request fails 401                                │
  │       │                                           │
  │       ▼                                           │
  │  ┌───────────────────┐                            │
  │  │ QueuedInterceptor │ ◀── serializes multiple    │
  │  │  _tryRefresh()    │     concurrent 401s        │
  │  └────────┬──────────┘                            │
  │           │                                       │
  │     ┌─────┴──────┐                                │
  │     │            │                                │
  │     ▼            ▼                                │
  │  Success       Failure                            │
  │  ┌────────┐   ┌────────────┐                      │
  │  │ Retry  │   │  logout()  │                      │
  │  │original│   │  redirect  │                      │
  │  │request │   │  to login  │                      │
  │  └────────┘   └────────────┘                      │
  └──────────────────────────────────────────────────┘
```

---

## Phase 5: UI Polish & Theming (Weeks 9–10)

> Goal: Production-quality visual layer.

| #   | Concept                                                          | Source Doc             | Project Milestone |
| --- | ---------------------------------------------------------------- | ---------------------- | ----------------- |
| 5.1 | M3 `ColorScheme.fromSeed()` + brand overrides                    | `theming.md`           | M6                |
| 5.2 | `ThemeExtension<AppColors>` for custom semantic tokens           | `theming.md`           | M6                |
| 5.3 | Dark mode: separate light/dark extensions, persistent preference | `theming.md`           | M6                |
| 5.4 | `AppSpacing.of(context)` elastic spacing                         | `responsive-sizing.md` | M6                |
| 5.5 | Breakpoint-driven layout adaptation                              | `responsive-sizing.md` | M6                |
| 5.6 | Slang i18n: type-safe translations, adding locales               | `i18n.md`              | M6                |
| 5.7 | SVG → `.vec` pre-compilation                                     | `svg-icons.md`         | M6                |
| 5.8 | Native splash screen (Android 12+ adaptive)                      | `native-splash.md`     | M6                |

### Deliverable

- Complete theme with light/dark, custom semantic colors
- One screen rendered responsively on phone + tablet
- Two locales with full coverage

```
Phase 5 — Theming & Responsive Architecture:

  ┌─────────────────────────────────────────────────────────┐
  │                Material 3 Theme System                    │
  │                                                           │
  │   Seed Color (#AB2138)                                    │
  │        │                                                  │
  │        ▼                                                  │
  │   ColorScheme.fromSeed()                                  │
  │        │                                                  │
  │        ├── primary, onPrimary, primaryContainer           │
  │        ├── secondary, tertiary (auto-generated)           │
  │        ├── surface, onSurface, surfaceContainer           │
  │        └── error, onError                                 │
  │                    │                                      │
  │                    ▼                                      │
  │   .copyWith()  ◀── Brand overrides from Figma            │
  │                                                           │
  │   ┌──────────────────────────────────────────┐            │
  │   │  ThemeExtension<AppColors>               │            │
  │   │  (custom tokens M3 doesn't have)         │            │
  │   │                                          │            │
  │   │  success  ■ #388E3C  ←→  ■ #91D495      │            │
  │   │  warning  ■ #E6B800  ←→  ■ #FFE066      │            │
  │   │  info     ■ #4A6EA5  ←→  ■ #95ADD0      │            │
  │   │           LIGHT          DARK            │            │
  │   └──────────────────────────────────────────┘            │
  └─────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────┐
  │              Responsive Spacing System                    │
  │                                                           │
  │  Reference width: 375 lp (iPhone SE)                      │
  │                                                           │
  │  Phone (375w)     Tablet (768w)     Desktop (1200w)       │
  │  factor = 1.0     factor = 1.25     factor = 1.35         │
  │                                                           │
  │  ┌──────────┐     ┌────────────┐    ┌──────────────┐     │
  │  │ ┌──────┐ │     │ ┌───┐┌───┐│    │┌──┐┌──┐┌──┐ │     │
  │  │ │ Card │ │     │ │   ││   ││    ││  ││  ││  │ │     │
  │  │ ├──────┤ │     │ ├───┤├───┤│    │├──┤├──┤├──┤ │     │
  │  │ │ Card │ │     │ │   ││   ││    ││  ││  ││  │ │     │
  │  │ ├──────┤ │     │ ├───┤├───┤│    │├──┤├──┤├──┤ │     │
  │  │ │ Card │ │     │ │   ││   ││    ││  ││  ││  │ │     │
  │  │ └──────┘ │     │ └───┘└───┘│    │└──┘└──┘└──┘ │     │
  │  └──────────┘     └────────────┘    └──────────────┘     │
  │   1 column          2 columns         3 columns          │
  └─────────────────────────────────────────────────────────┘
```

---

## Phase 6: Platform Features (Weeks 11–12)

> Goal: Native integration that users expect.

| #   | Concept                                                     | Source Doc              | Project Milestone |
| --- | ----------------------------------------------------------- | ----------------------- | ----------------- |
| 6.1 | Deep linking: App Links (Android), Universal Links (iOS)    | `deep-linking.md`       | M7                |
| 6.2 | Push notifications: FCM setup, channels, permission flow    | `push-notifications.md` | M7                |
| 6.3 | Foreground/background/terminated notification handling      | `push-notifications.md` | M7                |
| 6.4 | QR scanning: `mobile_scanner`, scan window, camera controls | `qr-scanning.md`        | M7                |
| 6.5 | Adaptive widgets (dialogs, pickers, switches)               | `platform-specific.md`  | M7                |
| 6.6 | Remote configuration: fetch, cache, typed getters           | `remote-config.md`      | M5                |
| 6.7 | Environment config: `--dart-define-from-file`               | `environment-config.md` | M5                |

### Deliverable

- Deep link opens specific screen with correct parameters
- Push notification received in foreground, tapped → navigated to correct screen
- QR scan → process result → navigate

```
Phase 6 — Platform Integration Map:

  ┌──────────────────────────────────────────────────────────────┐
  │                                                              │
  │  ╔══════════════╗   ╔══════════════╗   ╔════════════════╗   │
  │  ║  Deep Links  ║   ║    Push      ║   ║  QR Scanner   ║   │
  │  ╚══════╤═══════╝   ╚══════╤═══════╝   ╚═══════╤═══════╝   │
  │         │                   │                    │           │
  │         ▼                   ▼                    ▼           │
  │  ┌─────────────┐   ┌──────────────┐   ┌──────────────────┐ │
  │  │ User taps   │   │ FCM delivers │   │ Camera detects   │ │
  │  │ shared URL  │   │ notification │   │ QR barcode       │ │
  │  └──────┬──────┘   └──────┬───────┘   └────────┬─────────┘ │
  │         │                  │                     │           │
  │         ▼                  ▼                     ▼           │
  │  ┌─────────────┐   ┌──────────────┐   ┌──────────────────┐ │
  │  │ OS verifies │   │   App State? │   │ Extract value    │ │
  │  │ domain:     │   │              │   │ Stop scanning    │ │
  │  │ assetlinks  │   │ Foreground:  │   └────────┬─────────┘ │
  │  │ apple-app-  │   │  show local  │            │           │
  │  │ site-assoc. │   │              │            │           │
  │  └──────┬──────┘   │ Background:  │            │           │
  │         │           │  system tray │            │           │
  │         │           │              │            │           │
  │         │           │ Terminated:  │            │           │
  │         │           │  getInitial  │            │           │
  │         │           └──────┬───────┘            │           │
  │         │                  │                     │           │
  │         └──────────┬───────┴─────────────────────┘           │
  │                    │                                         │
  │                    ▼                                         │
  │         ┌────────────────────┐                               │
  │         │     GoRouter       │                               │
  │         │  route matching    │                               │
  │         │                    │                               │
  │         │ /app/events/:id ──▶ EventDetailScreen              │
  │         │ /app/tickets/:id ─▶ TicketDetailScreen             │
  │         └────────────────────┘                               │
  └──────────────────────────────────────────────────────────────┘
```

---

## Phase 7: Testing & Quality (Weeks 13–14)

> Goal: Ship with confidence.

| #   | Concept                                              | Source Doc    | Project Milestone |
| --- | ---------------------------------------------------- | ------------- | ----------------- |
| 7.1 | Unit tests: entities, repositories with `mocktail`   | `testing.md`  | M8                |
| 7.2 | Controller tests: `ProviderContainer` with overrides | `testing.md`  | M8                |
| 7.3 | Widget tests: `testApp()` wrapper, `pumpAndSettle`   | `testing.md`  | M8                |
| 7.4 | Integration tests: full feature flows                | `testing.md`  | M8                |
| 7.5 | Drift in-memory database testing                     | `database.md` | M8                |
| 7.6 | 80% coverage per feature slice                       | `testing.md`  | M8                |

### Deliverable

- 80%+ coverage on two feature slices
- Widget test for every screen
- One end-to-end integration test

```
Phase 7 — Testing Pyramid:

                        ╱╲
                       ╱  ╲
                      ╱    ╲
                     ╱ Integ╲          1 per major feature
                    ╱ ration ╲         Full flows: login → browse → buy
                   ╱──────────╲
                  ╱            ╲
                 ╱    Widget    ╲       Every screen: data + loading + error
                ╱    Tests      ╲      pumpWidget → pumpAndSettle → find.*
               ╱────────────────╲
              ╱                  ╲
             ╱     Unit Tests     ╲    Entities, repos, controllers, DAOs
            ╱   (fastest, most)    ╲   ProviderContainer + mocktail
           ╱────────────────────────╲
          ╱                          ╲
         ╱      80%+ line coverage    ╲
        ╱──────────────────────────────╲

  Test Tool Kit:
  ┌───────────────┐  ┌───────────────┐  ┌──────────────────┐
  │   mocktail    │  │ ProviderScope │  │   Drift          │
  │               │  │   overrides   │  │   in-memory DB   │
  │ Mock classes  │  │               │  │                  │
  │ when().then() │  │ testApp()     │  │ NativeDatabase   │
  │ verify()      │  │ wrapper       │  │   .memory()      │
  └───────────────┘  └───────────────┘  └──────────────────┘
```

---

## Phase 8: Performance & CI/CD (Weeks 15–16)

> Goal: Production readiness.

| #   | Concept                                                          | Source Doc       | Project Milestone |
| --- | ---------------------------------------------------------------- | ---------------- | ----------------- |
| 8.1 | Performance profiling: DevTools, frame budget monitoring         | `performance.md` | M9                |
| 8.2 | `const` constructors, widget splitting, `RepaintBoundary`        | `performance.md` | M9                |
| 8.3 | List performance: `ListView.builder`, `itemExtent`               | `performance.md` | M9                |
| 8.4 | Image caching: `cached_network_image`, size-appropriate requests | `performance.md` | M9                |
| 8.5 | GitHub Actions CI: analyze → test → build                        | `ci-cd.md`       | M9                |
| 8.6 | Fastlane: Match, Firebase App Distribution                       | `ci-cd.md`       | M9                |
| 8.7 | Shorebird OTA patching                                           | `ci-cd.md`       | M9                |

### Deliverable

- All frames under 16ms budget on mid-range device
- CI pipeline passing on every push
- Beta distributed via Firebase App Distribution

```
Phase 8 — CI/CD Pipeline:

   Developer pushes code
          │
          ▼
  ┌───────────────────────────────────────────────────────┐
  │              GitHub Actions CI                          │
  │                                                         │
  │  ┌──────────┐   ┌──────────┐   ┌────────────────────┐ │
  │  │  dart     │──▶│ flutter  │──▶│   flutter build    │ │
  │  │  format   │   │  test    │   │   apk --release    │ │
  │  │  --check  │   │ --cover  │   │   ios --no-codesign│ │
  │  └──────────┘   └──────────┘   └─────────┬──────────┘ │
  │                                           │            │
  └───────────────────────────────────────────┼────────────┘
                                              │
                       ┌──────────────────────┼───────────────┐
                       │                      │               │
                       ▼                      ▼               ▼
               ┌──────────────┐     ┌──────────────┐  ┌────────────┐
               │   Fastlane   │     │   Fastlane   │  │  Shorebird │
               │   Android    │     │     iOS      │  │  OTA Patch │
               │              │     │              │  │            │
               │ Firebase App │     │  Match certs │  │ Dart-only  │
               │ Distribution │     │  App Store / │  │ patches    │
               │              │     │  Firebase    │  │ skip store │
               └──────────────┘     └──────────────┘  └────────────┘
                       │                    │                │
                       └────────────┬───────┘                │
                                    ▼                        ▼
                            ┌──────────────┐        ┌──────────────┐
                            │   Testers    │        │  Production  │
                            │  get beta    │        │  users get   │
                            │  instantly   │        │  hot patch   │
                            └──────────────┘        └──────────────┘

  Performance Budgets:
  ┌────────────────┬───────────────────────────────────┐
  │ Frame time     │  < 16ms  ████████░░  (60fps)      │
  │ Cold start     │  < 3s    ███░░░░░░░               │
  │ APK size       │  < 30MB  ██████░░░░               │
  │ Memory         │  < 200MB █████████░               │
  │ Crash-free     │  99.5%   ██████████               │
  └────────────────┴───────────────────────────────────┘
```

---

## Visual Dependency Graph

```
Phase 1: Foundation
    │
    ▼
Phase 2: State Management ──────────────┐
    │                                    │
    ▼                                    │
Phase 3: Networking & Data ◄─────────────┤
    │                                    │
    ▼                                    │
Phase 4: Authentication                  │
    │                                    │
    ├───────────────┐                    │
    ▼               ▼                    │
Phase 5: UI     Phase 6: Platform ◄──────┘
    │               │
    └───────┬───────┘
            ▼
    Phase 7: Testing
            │
            ▼
    Phase 8: Performance & CI/CD
```

---

## Week-by-Week Calendar

```
Week   1   2   3   4   5   6   7   8   9  10  11  12  13  14  15  16
     ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
  P1 │███│███│   │   │   │   │   │   │   │   │   │   │   │   │   │   │
     ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
  P2 │   │   │███│███│   │   │   │   │   │   │   │   │   │   │   │   │
     ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
  P3 │   │   │   │   │███│███│███│   │   │   │   │   │   │   │   │   │
     ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
  P4 │   │   │   │   │   │   │   │███│   │   │   │   │   │   │   │   │
     ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
  P5 │   │   │   │   │   │   │   │   │███│███│   │   │   │   │   │   │
     ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
  P6 │   │   │   │   │   │   │   │   │   │   │███│███│   │   │   │   │
     ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
  P7 │   │   │   │   │   │   │   │   │   │   │   │   │███│███│   │   │
     ├───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
  P8 │   │   │   │   │   │   │   │   │   │   │   │   │   │   │███│███│
     └───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘

  P = Phase    ███ = Active learning + building
```
