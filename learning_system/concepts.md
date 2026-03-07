# Advanced Concepts — Extracted from Project Docs

```
Concept Map — How Everything Connects:

┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                ┌─────────────────────────┐                                    │
│                │   FOUNDATION LAYER       │                                    │
│                │   C1  State Management   │────────┐                           │
│                │   C2  Clean Architecture │        │                           │
│                │   C3  Code Generation    │        │ powers                    │
│                └─────────────────────────┘        │                           │
│                         │                         ▼                           │
│   ┌─────────────────────┘       ┌────────────────────────────┐       │
│   │                               │ NETWORKING & DATA          │       │
│   │  ┌────────────────────┐     │ C4 Networking (Dio+GraphQL) │       │
│   │  │ UI & POLISH          │     │ C5 Error Handling          │       │
│   │  │ C8  Theming (M3)     │     │ C6 Authentication          │       │
│   │  │ C9  Responsive       │     │ C7 Local Database (Drift)  │       │
│   │  │ C10 i18n (Slang)     │     │ C14 Remote Config          │       │
│   │  │ C20 Splash + SVG     │     │ C21 Phased Retry           │       │
│   │  └────────────────────┘     └────────────────────────────┘       │
│   │                                                               │       │
│   │  ┌────────────────────┐     ┌────────────────────────────┐       │
│   │  │ PLATFORM FEATURES    │     │ QUALITY & DELIVERY         │       │
│   │  │ C11 Deep Linking     │     │ C15 Performance            │       │
│   │  │ C12 Push Notifs      │     │ C16 Environment Config     │       │
│   │  │ C13 QR Scanning      │     │ C17 CI/CD Pipeline         │       │
│   │  │ C19 Platform-Specific│     │ C18 Testing Strategy       │       │
│   │  └────────────────────┘     └────────────────────────────┘       │
│   │                                                                       │
│   └──────── All groups depend on Foundation Layer ───────────────────┘
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## C1. State Management (Riverpod 3.x)

**Source:** `docs/state-management.md`

- Riverpod as the **sole state + DI container** — no `get_it`, no service locators
- `@riverpod` codegen for all new providers (function-based & class-based)
- Provider taxonomy: `Provider`, `FutureProvider`, `AsyncNotifier`, family providers
- `ref.watch` (reactive), `ref.read` (one-shot), `ref.listen` (side-effects)
- `select()` for surgical rebuild optimization
- `AsyncValue.guard()` for safe error capture in controllers
- `ref.invalidateSelf()` / `ref.invalidate()` for re-fetching
- Provider scoping: feature-scoped DI wiring in `providers.dart`
- `keepAlive` for singletons (Dio, DB, GraphQL client)

**Why it matters:** Every layer of the app communicates through Riverpod. Mastering its reactive model is the foundation.

```
C1 — Riverpod Provider Taxonomy:

  ┌───────────────────────────────────────────────────────────┐
  │                Provider Types                               │
  │                                                             │
  │  ┌───────────────┐  sync value   "singleton-like"              │
  │  │   Provider    │  (Dio, DB client, config)                 │
  │  └───────────────┘                                              │
  │  ┌───────────────┐  async value  "fetch once"                  │
  │  │FutureProvider │  (remote config, initial load)             │
  │  └───────────────┘                                              │
  │  ┌───────────────┐  async + mutations "feature controller"    │
  │  │AsyncNotifier  │  (events list, ticket purchase)            │
  │  └───────────────┘                                              │
  └───────────────────────────────────────────────────────────┘

  Ref API:

    ref.watch(p)    ──▶  reactive rebuild on change
    ref.read(p)     ──▶  one-shot read (in callbacks)
    ref.listen(p)   ──▶  side-effects (snackbar, navigation)
    ref.invalidate() ─▶  force re-fetch
    select()        ──▶  surgical — rebuild only when sub-value changes
```

---

## C2. Clean Architecture — Feature-Slice Pattern

**Source:** `docs/project-structure.md`

- Vertical feature slices: `presentation/ → domain/ → data/`
- Domain layer: pure Dart entities (Freezed), abstract repository interfaces, optional use cases
- Data layer: Retrofit API services, Drift DAOs, DTOs with `toEntity()` conversion
- Presentation layer: `ConsumerWidget` screens, `AsyncNotifier` controllers
- Barrel files export only public API (entities, providers, routes)
- Dependency inversion: expose repositories as abstract types
- Dependency flow: `presentation → domain ← data` (domain knows nothing about data or UI)

**Why it matters:** Enforces separation of concerns at scale. Every feature is independently testable and replaceable.

```
C2 — Feature-Slice Architecture:

  lib/
  ├── core/                        ◀── shared across all features
  │   ├── auth/                    (auth state, interceptor, guard)
  │   ├── network/                 (Dio, interceptors, error mapping)
  │   └── data/                    (Drift DB, shared DAOs)
  │
  └── features/
      └── events/                  ◀── one vertical slice
          ├── presentation/        ┌───────────────────┐
          │   ├── screens/         │ ConsumerWidget    │
          │   └── controllers/     │ AsyncNotifier     │──┐
          │                        └───────────────────┘  │
          ├── domain/              ┌───────────────────┐  │ uses
          │   ├── entities/        │ Pure Dart (Freezed)│◀─┘
          │   └── repositories/    │ Abstract interface│
          │      (abstract)        └─────────▲─────────┘
          │                                  │ implements
          └── data/                ┌─────────┴─────────┐
              ├── models/          │ DTOs + toEntity() │
              ├── api/             │ Retrofit service  │
              └── repositories/    │ Concrete impl     │
                 (concrete)        └───────────────────┘

  Dependency Rule:  presentation ─▶ domain ◀─ data
                    (domain knows NOTHING about data or UI)
```

---

## C3. Code Generation Ecosystem

**Source:** `done/code-generation.md`

- `build_runner` as the central engine — incremental builds, phase ordering
- `riverpod_generator`: `@riverpod` → providers
- `freezed`: sealed classes, unions, `copyWith`, equality
- `json_serializable`: `fromJson` / `toJson` boilerplate
- `retrofit_generator`: type-safe Dio REST clients from abstract classes
- `drift_dev`: type-safe SQLite from table definitions
- `slang_build_runner`: type-safe i18n from YAML
- `part` / `part of` directives — how generators share `.g.dart` files
- `build.yaml` configuration for multi-generator coexistence

**Why it matters:** Dart lacks runtime reflection. Code generation is how you get zero-boilerplate serialization, providers, and DB layers while staying AOT-compiled.

```
C3 — Code Generation Pipeline:

  You write:                     build_runner generates:

  @riverpod                      ──▶  .g.dart  (providers)
  @freezed                       ──▶  .freezed.dart  (copyWith, ==, sealed)
  @JsonSerializable              ──▶  .g.dart  (fromJson / toJson)
  @RestApi()                     ──▶  .g.dart  (Dio REST client)
  @DriftDatabase / @DriftAccessor ─▶  .g.dart  (type-safe SQL)
  i18n YAML                      ──▶  strings.g.dart  (t.key.subkey)

  Command:  dart run build_runner build --delete-conflicting-outputs

  File Structure:
  ┌──────────────────┐     part directive     ┌──────────────────────┐
  │ event.dart     │ ──────part of──────▶ │ event.freezed.dart   │
  │ part '...';    │                     │ event.g.dart         │
  └──────────────────┘                     └──────────────────────┘
              (source)                       (generated ─ never edit!)
```

---

## C4. Networking — Dio + Retrofit + GraphQL

**Sources:** `docs/networking.md`, `docs/graphql.md`

- Single Dio instance with layered interceptors (error → auth → logging)
- Retrofit `@RestApi()` for REST endpoints (one per feature)
- GraphQL via `graphql` + `gql_dio_link` — shares Dio's interceptors
- `graphql_codegen` for typed queries, variables, and result classes
- HotChocolate conventions (PascalCase enums, `Enum$` prefix, `$unknown` fallback)
- Schema download + commit workflow
- Fetch policies (`networkOnly` vs cache)

**Why it matters:** Dual protocol (REST writes + GraphQL reads) with unified auth/error handling is a real-world production pattern.

```
C4 — Networking Architecture:

  ┌───────────────┐       ┌──────────────────┐
  │ REST Client   │       │ GraphQL Client   │
  │ (Retrofit)    │       │ (gql_dio_link)   │
  └──────┬────────┘       └───────┬──────────┘
         │                        │
         └────────┬───────────┘
                  │
                  ▼
  ┌─────────────────────────────────┐  ◀─ shared Dio instance
  │       Interceptor Stack            │
  │                                   │
  │  Request ──▶ [ErrorInterceptor]    │  maps DioException → AppException
  │          ──▶ [AuthInterceptor]     │  attaches token, handles 401 refresh
  │          ──▶ [LogInterceptor]      │  dev-only request/response logging
  │                                   │
  └─────────────────────────────────┘

  Dual Protocol Strategy:

  Reads  (lists, detail, search) ──▶ GraphQL  (ask for exactly what UI needs)
  Writes (create, update, delete) ─▶ REST     (simple, predictable mutations)
```

---

## C5. Error Handling — Typed Exception Pipeline

**Source:** `docs/error-handling.md`

- `AppException` sealed class via Freezed: `network`, `server`, `unauthorized`, `validation`, `unknown`
- `ErrorInterceptor` maps `DioException` → `AppException` at the Dio layer
- Repository layer: catch, fallback to cache, or rethrow
- Controller layer: `AsyncValue.guard()` wraps errors into `AsyncValue.error`
- Screen layer: `.when(data:, loading:, error:)` exhaustive rendering
- `toUserMessage()` extension maps exceptions → i18n strings
- Form validation errors (422) mapped to field-level errors

**Why it matters:** Typed errors flowing through the architecture mean no unhandled crashes and consistent UX.

```
C5 — Error Flow Through Architecture:

  Dio Layer             Repository           Controller            Screen
  ┌────────────┐    ┌────────────┐    ┌────────────┐    ┌────────────┐
  │DioException│    │ try/catch  │    │AsyncValue  │    │  .when()   │
  │            │───▶│ fallback   │───▶│  .guard()  │───▶│  data:     │
  │ timeout    │    │ to cache   │    │            │    │  loading:  │
  │ 404 / 500  │    │ or rethrow │    │ wraps into │    │  error:    │
  └──────┬─────┘    └────────────┘    │ .error()   │    └──────┬─────┘
         │          ErrorInterceptor    └────────────┘           │
         ▼              maps to:                              ▼
  ┌───────────────────────────┐               ┌────────────────────┐
  │ AppException (sealed)      │               │ toUserMessage()      │
  │ ├── .network()             │               │ maps to i18n string   │
  │ ├── .server(code, msg)     │               │ for user-friendly     │
  │ ├── .unauthorized()        │               │ display               │
  │ ├── .validation(errors)    │               └────────────────────┘
  │ └── .unknown(error)        │
  └───────────────────────────┘
```

---

## C6. Authentication — Sealed State + Token Refresh

**Source:** `done/authentication.md`

- Auth as a **core concern** (not a feature) — `lib/core/auth/`
- `AuthState` sealed class: `authenticated`, `unauthenticated`, `loading`
- `AuthController` (`@riverpod` notifier) with `login()` / `logout()`
- Derived convenience providers: `currentUserProvider`, `authTokenProvider`
- `QueuedInterceptor` for token refresh (serializes concurrent 401 retries)
- GoRouter auth guard with automatic redirect on state change
- Token persistence via `SharedPreferences` wrapper
- Auth feature slice for UI (login/OTP screens, auth repository)

**Why it matters:** Auth touches every feature. The sealed-state + interceptor + router-guard pattern is the gold standard.

```
C6 — Authentication Lifecycle:

  ┌───────────────┐     success      ┌─────────────────┐
  │ Unauthenticated │ ────────────▶ │  Authenticated  │
  │ (show login)    │              │  (show home)    │
  └───────┬───────┘              └────────┬────────┘
          ▲    login()                      │ logout()
          │                                 │
          └─────────────────────────────┘

  Token Refresh (QueuedInterceptor):

  Request A (401) ──┐
  Request B (401) ──┼──▶ Queue ──▶ Refresh Token ──▶ Retry All
  Request C (401) ──┘         (only 1 refresh call, others wait)

  GoRouter Auth Guard:

  ┌─────────────┐    authenticated?    ┌───────────────┐
  │ Any Route   │ ────NO─────────▶ │ Redirect to   │
  │ /events     │                 │ /login        │
  └─────────────┘                 └───────────────┘
       │ YES ──▶ proceed to route
```

---

## C7. Local Database — Drift

**Sources:** `docs/database.md`, `docs/drift_tutor.md`

- Drift for structured SQLite — compile-time SQL verification
- Single `AppDatabase` in `core/`, feature-scoped DAOs via `DatabaseAccessor`
- Table definitions with constraints (unique, references, nullable)
- `watch()` for reactive streams, `get()` for one-shot queries
- `InsertMode.insertOrReplace` for upsert from remote
- Schema migrations: bump version → add migration step → regenerate
- In-memory database for testing
- Repository pattern: remote-first with local cache fallback

**Why it matters:** Offline-first with proper migrations is what separates toy apps from production apps.

```
C7 — Drift Database Architecture:

  ┌─────────────────────────────────────────────────────┐
  │                AppDatabase (single instance)               │
  │                                                             │
  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
  │  │ EventsDao    │  │ TicketsDao   │  │ UsersDao     │  │
  │  │ (DatabaseAcc)│  │ (DatabaseAcc)│  │ (DatabaseAcc)│  │
  │  └─────┬────────┘  └─────┬────────┘  └─────┬────────┘  │
  │        │                │                │              │
  │        ▼                ▼                ▼              │
  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
  │  │ events table │  │tickets table │  │ users table  │  │
  │  └──────────────┘  └──────────────┘  └──────────────┘  │
  └─────────────────────────────────────────────────────┘

  Offline-First Strategy:

  API call ───▶ success? ──YES──▶ upsert to Drift ──▶ return entities
                  │
                  NO (network error)
                  │
                  ▼
           read from Drift cache ──▶ return cached entities
```

---

## C8. Theming — Material 3 Seed System

**Source:** `docs/theming.md`

- `ColorScheme.fromSeed()` + `.copyWith()` for brand overrides
- `ThemeExtension<AppColors>` for custom semantic tokens (success, warning, info)
- Zero hardcoded colors in widgets — always `colorScheme` or `context.appColors`
- `AppPalette` constants consumed only by theme builders
- Dark mode: separate light/dark `ThemeExtension` instances
- Riverpod `ThemeModeNotifier` persisted to `SharedPreferences`
- Component-level theme overrides (`ElevatedButtonThemeData`, etc.)
- `ThemeData` instances created once (`static final`), not in `build()`

**Why it matters:** M3 theming done right means pixel-perfect Figma fidelity with automatic light/dark support.

```
C8 — Material 3 Theming System:

  ┌───────────────────┐        ┌──────────────────────────┐
  │ Seed Color       │        │ colorScheme.fromSeed()   │
  │ (brand primary)  │ ────▶  │ auto-generates palette    │
  └───────────────────┘        └────────┬─────────────────┘
                                        │
               ┌─────────────────────┴─────────────────────┐
               │                                            │
               ▼                                            ▼
  ┌────────────────────┐             ┌────────────────────┐
  │ Light ThemeData   │             │ Dark ThemeData    │
  │ + AppColors.light │             │ + AppColors.dark  │
  └────────────────────┘             └────────────────────┘
   (ThemeExtension)                   (ThemeExtension)

  Widget Color Access:

  ✓ colorScheme.primary         (M3 built-in role)
  ✓ colorScheme.surface         (M3 built-in role)
  ✓ context.appColors.success   (custom ThemeExtension)
  ✗ Colors.red                  (NEVER hardcode)
  ✗ AppPalette.primary600       (NEVER in widgets)
```

---

## C9. Responsive Design — Elastic Spacing + Breakpoints

**Source:** `docs/responsive-sizing.md`

- Fixed M3 typography (never scale text proportionally)
- `AppSpacing.of(context)` — elastic spacing relative to 375lp reference width
- Scale factor clamped 0.85–1.35 for safety
- Named spacing scale: `xs` (4), `sm` (8), `md` (16), `lg` (24), `xl` (32), `xxl` (48)
- Breakpoint-driven layout adaptation (phone/tablet/desktop)
- No `flutter_screenutil` — explicit rationale against it
- `SafeArea` handling

**Why it matters:** Professional apps must feel proportional across 4" phones and 12" tablets without breaking accessibility.

```
C9 — Responsive Spacing Model:

  Reference: 375 logical pixels

  4" phone (320lp)          5.5" phone (375lp)        12" tablet (800lp)
  scale = 0.85              scale = 1.0               scale = 1.35
  ┌──────────────┐          ┌────────────────┐        ┌─────────────────────┐
  │  ┌────────┐  │          │  ┌──────────┐  │        │  ┌───────┐ ┌──────┐ │
  │  │ sm=7   │  │          │  │ sm=8     │  │        │  │ card  │ │ card │ │
  │  └────────┘  │          │  └──────────┘  │        │  └───────┘ └──────┘ │
  │  md=14 gap   │          │  md=16 gap     │        │  md=22 gap              │
  │  ┌────────┐  │          │  ┌──────────┐  │        │  ┌───────┐ ┌──────┐ │
  │  │ sm=7   │  │          │  │ sm=8     │  │        │  │ card  │ │ card │ │
  │  └────────┘  │          │  └──────────┘  │        │  └───────┘ └──────┘ │
  └──────────────┘          └────────────────┘        └─────────────────────┘
  single column                single column             two-column grid

  Text: NEVER scaled — always M3 textTheme (fixed sizes)
  Spacing: AppSpacing.of(context).md  → elastic
```

---

## C10. Internationalization — Slang

**Source:** `docs/i18n.md`

- `slang` for type-safe, compile-time checked translations
- YAML source files in `assets/i18n/`
- `t.key.subkey` — no raw string lookups
- Context-based (`context.t`) for reactive locale changes
- Adding new locales: create YAML → run `dart run slang`

**Why it matters:** Type-safe i18n catches missing translations at compile time instead of runtime.

```
C10 — Slang i18n Pipeline:

  assets/i18n/en.i18n.yaml    assets/i18n/ar.i18n.yaml
  ┌────────────────────┐    ┌────────────────────┐
  │ events:            │    │ events:            │
  │   title: Events    │    │   title: الفعاليات    │
  │   empty: No events │    │   empty: لا فعاليات  │
  └──────────┬─────────┘    └────────┬───────────┘
             │                       │
             └────────┬──────────┘
                      ▼
              dart run slang
                      │
                      ▼
        lib/core/i18n/strings.g.dart
                      │
                      ▼
             t.events.title    ◀── type-safe, compile-checked
             t.events.empty    ◀── missing key = compile error
             context.t.events.title  ◀── reactive locale switch
```

---

## C11. Deep Linking — App Links + Universal Links

**Source:** `docs/deep-linking.md`

- App Links (Android): `assetlinks.json`, `android:autoVerify`
- Universal Links (iOS): `apple-app-site-association`, Associated Domains
- No custom URL schemes in production (insecure)
- GoRouter route matching: deep links resolve to existing route tree
- `app_links` package for link listening
- Initial link handling (app opened from terminated state)

**Why it matters:** Deep linking is required for sharing, notifications, and marketing campaigns.

```
C11 — Deep Link Resolution:

  External Source (SMS, email, push)
       │
       ▼
  https://app.example.com/events/42
       │
       ├─── Android: assetlinks.json → autoVerify → opens app
       │
       ├─── iOS: AASA file → Associated Domains → opens app
       │
       ▼
  app_links package
       │
       ├─── getInitialLink()  (app was terminated)
       │
       ├─── uriLinkStream    (app was in background)
       │
       ▼
  GoRouter.go('/events/42')
       │
       ▼
  EventDetailScreen(id: '42')   ◀── same as in-app navigation!

  ⚠ NEVER use custom URL schemes (myapp://) in production
    → they are insecure and can be hijacked
```

---

## C12. Push Notifications — FCM + Local

**Source:** `docs/push-notifications.md`

- `firebase_messaging` + `flutter_local_notifications`
- Unified `NotificationService` in `core/notifications/`
- Android notification channels (required Android 8+)
- Permission request flow
- Foreground display via local notifications
- Background/terminated tap handling
- Token management + server registration
- Message routing to deep links

**Why it matters:** Push is the primary re-engagement channel. Correct foreground/background/terminated handling is complex.

```
C12 — Push Notification Handling:

  Backend Server
       │ send message
       ▼
  ┌────────────────┐
  │  FCM Service   │
  └─────┬──────────┘
        │
        ├───────────────────────┬────────────────────┐
        ▼                       ▼                    ▼
  ┌────────────┐   ┌──────────────┐   ┌────────────┐
  │ FOREGROUND │   │  BACKGROUND  │   │ TERMINATED │
  │ onMessage  │   │  onBgMessage  │   │ getInitial │
  │            │   │  (top-level) │   │ Message    │
  └────┬───────┘   └──────┬───────┘   └────┬───────┘
       │                  │                  │
       ▼                  ▼                  ▼
  flutter_local_notifications  (show / handle tap)
                  │
                  ▼
  extract route from payload ──▶ GoRouter.go(deepLink)
```

---

## C13. QR Code Scanning

**Source:** `docs/qr-scanning.md`

- `mobile_scanner` v7.x (ML Kit on Android, Apple Vision on iOS)
- Scan window (region of interest) for guided UX
- Camera controls (torch, facing switch)
- Stop-after-first-result pattern
- Error handling for camera permissions and failures

**Why it matters:** Physical-digital bridging (tickets, check-ins, invitations) is a core mobile capability.

```
C13 — QR Scanning Flow:

  ┌───────────────────────┐
  │  Camera Preview        │
  │  ┌───────────────┐    │
  │  │               │    │     mobile_scanner v7
  │  │  Scan Window  │    │     ML Kit (Android)
  │  │  (ROI overlay)│    │     Apple Vision (iOS)
  │  │               │    │
  │  └───────────────┘    │
  │  [🔦 Torch] [Switch 📷] │
  └────────┬──────────────┘
           │  first barcode detected
           ▼  (stop scanning)
  Parse payload ──▶ POST /check-in ──▶ Success ✓ / Failure ✗
```

---

## C14. Remote Configuration

**Source:** `docs/remote-config.md`

- Backend-fetched config (not Firebase Remote Config)
- `FutureProvider<AppConfiguration>` with `keepAlive`
- Loaded during splash → synchronously available to features
- `ConfigKeys` constants match backend schema
- Typed getters via extension (`isEventsEnabled`, `maxUploadSizeBytes`)
- `SharedPreferences` caching for offline-first
- Default fallback values for first launch

**Why it matters:** Feature flags and runtime config without app store releases.

```
C14 — Remote Config Flow:

  App Launch
       │
       ▼
  ┌───────────────────────────────────────────────────┐
  │ Splash Screen                                        │
  │                                                       │
  │  ① Try fetch from backend  ──▶ success?               │
  │                                   │                   │
  │        ┌─────────YES───────────┘                   │
  │        ▼                   NO ───┐                   │
  │  Save to SharedPrefs           │                   │
  │                               ▼                   │
  │                   ② Read from SharedPrefs (cached)   │
  │                               │                      │
  │                        ┌─────┴─────────────┐         │
  │                        │ still null?     │         │
  │                        │ ─▶ use defaults  │         │
  │                        └──────────────────┘         │
  └───────────────────────────────────────────────────┘
                      │
                      ▼
  FutureProvider<AppConfiguration>(keepAlive: true)
                      │
                      ▼
  Features read: config.isEventsEnabled, config.maxUploadSizeBytes
```

---

## C15. Performance Optimization

**Source:** `docs/performance.md`

- Frame budget: <16ms (60fps)
- `const` constructors everywhere
- `select()` for granular rebuilds
- Widget splitting for isolation
- `RepaintBoundary` (only when profiling confirms benefit)
- `cached_network_image` for remote images
- `ListView.builder` (never `ListView(children:)`)
- `itemExtent` for uniform-height lists
- SVG pre-compilation to `.vec`
- Isolates for heavy computation
- DevTools profiling workflow

**Why it matters:** Performance is a feature. Users leave janky apps.

```
C15 — Performance Optimization Checklist:

  ┌─────────────────────────────────────────────────────┐
  │               Build Phase                              │
  │                                                        │
  │  const constructors     → zero rebuild cost             │
  │  select() on providers   → surgical watches             │
  │  widget decomposition    → isolate rebuilds             │
  │  RepaintBoundary         → only when profiling proves   │
  └─────────────────────────────────────────────────────┘
  ┌─────────────────────────────────────────────────────┘
  │               Layout Phase                             │
  │                                                        │
  │  ListView.builder       → lazy, never ListView(children)│
  │  itemExtent             → skip layout for uniform items │
  │  CachedNetworkImage     → disk+memory cache             │
  │  SVG → .vec precompile  → zero runtime SVG parsing     │
  └─────────────────────────────────────────────────────┘
  ┌─────────────────────────────────────────────────────┘
  │               Async Phase                              │
  │                                                        │
  │  Isolates               → heavy JSON / image compute   │
  │  compute()              → simple off-main-thread work   │
  └─────────────────────────────────────────────────────┘

  Profiling:  DevTools Timeline → every frame < 16ms (60fps)
```

---

## C16. Environment Configuration

**Source:** `docs/environment-config.md`

- `--dart-define` / `--dart-define-from-file` for compile-time config
- No `.env` files, no runtime config loading
- JSON config files per environment (`dev.json`, `staging.json`, `prod.json`)
- `AppConfig` provider exposing `baseUrl`, `environment`

**Why it matters:** Compile-time config prevents accidental production requests during development.

```
C16 — Environment Config:

  Config Files:
  ┌──────────┐  ┌─────────────┐  ┌─────────┐
  │ dev.json │  │ staging.json│  │ prod.json│
  └────┬─────┘  └─────┬───────┘  └────┬────┘
       │              │              │
       └─────────────┬─────────────┘
                      ▼
         --dart-define-from-file=<env>.json
                      │
                      ▼
  ┌─────────────────────────────────────┐
  │  AppConfig provider                  │
  │  ├─ baseUrl   (https://api.dev...)    │
  │  ├─ environment (dev / staging / prod)│
  │  └─ apiKey    (compile-time baked in) │
  └─────────────────────────────────────┘

  ⚠ No .env files    ⚠ No runtime config loading
  ✓ Compile-time only ✓ Cannot accidentally mix environments
```

---

## C17. CI/CD Pipeline

**Source:** `done/ci-cd.md`

- GitHub Actions: analyze → test → build (Android on Linux, iOS on macOS)
- Fastlane: Match for certificates, `build_app`, Firebase App Distribution
- Shorebird for OTA Dart patches (bypass app store review)
- Caching: pub, Gradle, CocoaPods (key-based invalidation)
- Secrets management via GitHub repository secrets

**Why it matters:** Automated pipelines catch regressions and eliminate manual build errors.

```
C17 — CI/CD Pipeline:

  Developer pushes code
           │
           ▼
  ┌─────────────────────────────────────────────────┐
  │            GitHub Actions                              │
  │                                                         │
  │  Analyze ───▶ Test ───▶ Build APK/IPA ───▶ Fastlane     │
  │  (lint+     (unit+      (Linux for        (Firebase    │
  │   format)    widget)     Android,          App Distro) │
  │                          macOS for iOS)                │
  └─────────────────────────────────────────────────┘
                                     │
                                     ▼
                          ┌───────────────────────┐
                          │  Shorebird OTA          │
                          │  (patch without store)   │
                          └───────────────────────┘

  iOS Signing: Fastlane Match (shared certs via Git)
```

---

## C18. Testing — Multi-Layer Strategy

**Source:** `docs/testing.md`

- 80% line coverage per feature slice
- Unit tests: entities, repositories (with `mocktail`)
- Controller tests: `ProviderContainer` with overrides
- Widget tests: `testApp()` wrapper with `ProviderScope`
- Integration tests: full flows
- Test structure mirrors `lib/`
- Shared mocks, fakes, and test helpers

**Why it matters:** Tests are the safety net that lets you refactor and ship with confidence.

```
C18 — Testing Pyramid:

                           ╱╲
                          ╱  ╲
                         ╱E2E ╲           1-2 full-flow tests
                        ╱──────╲
                       ╱ Widget  ╲         every screen × 3 states
                      ╱──────────╲
                     ╱    Unit     ╲       entities + repos + controllers
                    ╱──────────────╲

  Per-Layer Strategy:

  │ Layer        │ What to test          │ Tool                    │
  ├──────────────┼───────────────────────┼─────────────────────────┤
  │ Entity       │ ==, copyWith, JSON    │ plain test              │
  │ Repository   │ API success/fail      │ mocktail                │
  │ Controller   │ AsyncValue states     │ ProviderContainer       │
  │ Screen       │ widget tree rendering  │ testApp() + pumpWidget  │
  │ Drift DAO    │ CRUD operations        │ in-memory database      │
  │ Integration  │ full user flow         │ integration_test        │

  Coverage Target:  80%+ per feature slice
```

---

## C19. Platform-Specific Code

**Source:** `docs/platform-specific.md`

- Adaptive widgets: dialogs, pickers, action sheets, switches
- Platform channels for native APIs
- `Platform.isIOS` / `Platform.isAndroid` for simple checks
- Separate implementation files for complex divergence
- Permissions handling per platform
- Testing checklist for both platforms

**Why it matters:** Users expect platform-native behavior for system-level interactions.

```
C19 — Platform Adaptation:

  ┌───────────────────────────────────────────────┐
  │     Shared UI (95% of the app)                    │
  │     ConsumerWidget, Material 3 widgets             │
  └──────────────────────┬────────────────────────┘
                         │ platform divergence
            ┌───────────┴────────────┐
            ▼                        ▼
  ┌───────────────┐    ┌──────────────────┐
  │   Android      │    │      iOS            │
  │               │    │                      │
  │ AlertDialog   │    │ CupertinoAlertDialog │
  │ DatePicker    │    │ CupertinoDatePicker  │
  │ Back button   │    │ Swipe-back gesture   │
  │ Notif channels│    │ Permission prompts   │
  └───────────────┘    └──────────────────┘

  Decision: Platform.isIOS ? showCupertinoDialog() : showDialog()
```

---

## C20. Native Splash + SVG Icons

**Sources:** `docs/native-splash.md`, `docs/svg-icons.md`

- `flutter_native_splash` for branded splash screen
- Android 12+ splash screen adaptation
- SVG → `.vec` compile-time transformation via `vector_graphics_compiler`
- `SvgPicture` with precompiled assets for zero runtime parsing cost

**Why it matters:** First impression (splash) and icon crispness at every resolution.

```
C20 — Splash + SVG Pipeline:

  SPLASH:
  ┌─────────────────────────────────────────────┐
  │  flutter_native_splash                            │
  │                                                   │
  │  pubspec.yaml config ──▶ generates native assets   │
  │                                                   │
  │  Android: drawable + styles.xml                    │
  │  iOS: LaunchScreen.storyboard                      │
  │  Android 12+: core splash API adaptation            │
  └─────────────────────────────────────────────┘

  SVG:
  icon.svg ── build-time ──▶ icon.vec ── runtime ──▶ SvgPicture
  (source)    (vector_graphics_compiler)              (zero parsing)
             ▲                              ▲
             binary format                  crisp at ANY resolution
```

---

## C21. Phased Retry (Backend Pattern)

**Source:** `docs/phased-retry.md`

- Hangfire background jobs with phased retry mechanism
- Configuration-driven retry policies
- Monitoring and alerting for failed jobs

**Why it matters:** Understanding backend retry semantics helps design resilient client-side error handling and UX expectations.

```
C21 — Phased Retry (Backend Awareness):

  Client Request ──▶ Server ──▶ Job Queue (Hangfire)
                              │
                              ▼
                    ┌─────────────────────────────┐
                    │  Attempt 1  ──▶ fail     │
                    │  wait 30s                │
                    │  Attempt 2  ──▶ fail     │
                    │  wait 5min                │
                    │  Attempt 3  ──▶ fail     │
                    │  wait 30min               │
                    │  Attempt 4  ──▶ success! │
                    └─────────────────────────────┘

  Client UX Implication:

  ─▶ Show "Processing..." → not instant
  ─▶ Poll or WebSocket for status updates
  ─▶ Don't let user retry immediately (backend already retrying)
  ─▶ Show clear error only after all retries exhausted
```
