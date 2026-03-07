# Environment Configuration

## Overview

The app uses Dart's `String.fromEnvironment` for compile-time configuration.
No `.env` files, no runtime config loading. Different environments (dev,
staging, production) are handled via build-time flags.

## How It Works

Dart `--dart-define` passes key-value pairs at build time:

```sh
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.hayyacom.com \
  --dart-define=ENVIRONMENT=production
```

These are accessed in code via:

```dart
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api-dev.hayyacom.com',
);

const environment = String.fromEnvironment(
  'ENVIRONMENT',
  defaultValue: 'development',
);
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `API_BASE_URL` | Backend API base URL | `https://api-dev.hayyacom.com` |
| `ENVIRONMENT` | Current environment name | `development` |

## Environment Configuration File

For convenience, use `--dart-define-from-file` with a JSON file:

```
config/
├── dev.json
├── staging.json
└── prod.json
```

```json
// config/dev.json
{
  "API_BASE_URL": "https://api-dev.hayyacom.com",
  "ENVIRONMENT": "development"
}
```

```json
// config/staging.json
{
  "API_BASE_URL": "https://api-staging.hayyacom.com",
  "ENVIRONMENT": "staging"
}
```

```json
// config/prod.json
{
  "API_BASE_URL": "https://api.hayyacom.com",
  "ENVIRONMENT": "production"
}
```

### Usage

```sh
# Development (default)
flutter run

# Staging
flutter run --dart-define-from-file=config/staging.json

# Production
flutter build apk --release --dart-define-from-file=config/prod.json
```

## App Config Provider

Expose environment config via Riverpod:

```dart
// lib/core/di/app_config.dart
class AppConfig {
  const AppConfig._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-dev.hayyacom.com',
  );

  static const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
}
```

Used in `dio_client.dart`:

```dart
final dio = Dio(BaseOptions(
  baseUrl: AppConfig.baseUrl,
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 15),
));
```

## Firebase Configuration

Firebase uses separate `google-services.json` / `GoogleService-Info.plist`
per environment. Use **Firebase project aliases** or separate projects:

| Environment | Firebase Project |
|-------------|----------------|
| Development | `hayyacom-dev` |
| Staging | `hayyacom-staging` |
| Production | `hayyacom-prod` |

For Android, place configs in build-type directories:
```
android/app/src/
├── debug/google-services.json       # Dev
├── staging/google-services.json     # Staging (requires build flavor)
└── release/google-services.json     # Production
```

For iOS, use Xcode build configurations or a script phase to copy
the correct `GoogleService-Info.plist`.

## CI/CD Integration

Pass environment variables via GitHub Actions secrets:

```yaml
# .github/workflows/ci.yml
- name: Build APK (staging)
  run: flutter build apk --release --dart-define-from-file=config/staging.json

- name: Build APK (production)
  run: flutter build apk --release --dart-define-from-file=config/prod.json
```

## Secrets Management

- **Config files** (`config/*.json`) can be committed — they contain URLs, not secrets.
- **API keys, signing keys, tokens** go in **GitHub Actions Secrets** only.
- **Never** commit Firebase service account keys, APNs keys, or signing keystores.
- **Never** use `--dart-define` for secrets that should not be in the binary
  (they can be extracted from the compiled app).

For truly sensitive runtime secrets, fetch them from the backend after
authentication.

## Debug Utilities

Enable debug tools only in development:

```dart
if (AppConfig.isDevelopment) {
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
}
```

## Rules

- **DO** use `--dart-define-from-file` for environment-specific builds.
- **DO** set sensible development defaults in `String.fromEnvironment`.
- **DO** use `AppConfig` for accessing environment values — no scattered `fromEnvironment` calls.
- **DO** commit config JSON files (they contain URLs, not secrets).
- **DO NOT** use `.env` files or `flutter_dotenv` — compile-time defines are simpler and tree-shakeable.
- **DO NOT** commit API keys, signing keys, or service account files.
- **DO NOT** rely on `--dart-define` for secrets — values are embedded in the binary.
