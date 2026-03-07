# Advanced Concepts — Extracted from Project Docs

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

---

## C10. Internationalization — Slang

**Source:** `docs/i18n.md`

- `slang` for type-safe, compile-time checked translations
- YAML source files in `assets/i18n/`
- `t.key.subkey` — no raw string lookups
- Context-based (`context.t`) for reactive locale changes
- Adding new locales: create YAML → run `dart run slang`

**Why it matters:** Type-safe i18n catches missing translations at compile time instead of runtime.

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

---

## C13. QR Code Scanning

**Source:** `docs/qr-scanning.md`

- `mobile_scanner` v7.x (ML Kit on Android, Apple Vision on iOS)
- Scan window (region of interest) for guided UX
- Camera controls (torch, facing switch)
- Stop-after-first-result pattern
- Error handling for camera permissions and failures

**Why it matters:** Physical-digital bridging (tickets, check-ins, invitations) is a core mobile capability.

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

---

## C16. Environment Configuration

**Source:** `docs/environment-config.md`

- `--dart-define` / `--dart-define-from-file` for compile-time config
- No `.env` files, no runtime config loading
- JSON config files per environment (`dev.json`, `staging.json`, `prod.json`)
- `AppConfig` provider exposing `baseUrl`, `environment`

**Why it matters:** Compile-time config prevents accidental production requests during development.

---

## C17. CI/CD Pipeline

**Source:** `done/ci-cd.md`

- GitHub Actions: analyze → test → build (Android on Linux, iOS on macOS)
- Fastlane: Match for certificates, `build_app`, Firebase App Distribution
- Shorebird for OTA Dart patches (bypass app store review)
- Caching: pub, Gradle, CocoaPods (key-based invalidation)
- Secrets management via GitHub repository secrets

**Why it matters:** Automated pipelines catch regressions and eliminate manual build errors.

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

---

## C20. Native Splash + SVG Icons

**Sources:** `docs/native-splash.md`, `docs/svg-icons.md`

- `flutter_native_splash` for branded splash screen
- Android 12+ splash screen adaptation
- SVG → `.vec` compile-time transformation via `vector_graphics_compiler`
- `SvgPicture` with precompiled assets for zero runtime parsing cost

**Why it matters:** First impression (splash) and icon crispness at every resolution.

---

## C21. Phased Retry (Backend Pattern)

**Source:** `docs/phased-retry.md`

- Hangfire background jobs with phased retry mechanism
- Configuration-driven retry policies
- Monitoring and alerting for failed jobs

**Why it matters:** Understanding backend retry semantics helps design resilient client-side error handling and UX expectations.
