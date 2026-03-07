# Remote Configuration

## Overview

The app fetches configuration from the backend at startup and caches it
locally. This allows the team to toggle features, set limits, and update
contact info without a new release.

Configuration is loaded during splash via `appConfigurationProvider`
(a `FutureProvider<AppConfiguration>` with `keepAlive`), so by the time
any feature screen runs the values are already available synchronously.

## Architecture

```
lib/core/remote_config/
├── data/
│   ├── data_sources/
│   │   └── remote_config_remote_data_source.dart   # GraphQL fetch
│   ├── graphql/
│   │   ├── get_all_configurations.graphql           # Query definition
│   │   └── get_all_configurations.graphql.dart      # Generated DTO
│   └── repositories/
│       └── remote_config_repository_impl.dart       # Cache + fetch
├── domain/
│   ├── config_keys.dart                             # Key constants
│   ├── defaults.dart                                # Offline fallback values
│   ├── models/
│   │   └── app_configuration.dart                   # Model + typed getters
│   └── repositories/
│       └── remote_config_repository.dart            # Abstract interface
├── providers.dart                                   # Riverpod wiring
└── remote_config.dart                               # Barrel export
```

## Key Concepts

### ConfigKeys

All backend key strings live in a single file
(`lib/core/remote_config/domain/config_keys.dart`):

```dart
abstract final class ConfigKeys {
  static const minVersion = 'MobileApp:MinVersion';
  static const supportEmail = 'MobileApp:SupportEmail';
  static const featureEventsEnabled = 'MobileApp:FeatureEventsEnabled';
  static const featureGuestsEnabled = 'MobileApp:FeatureGuestsEnabled';
  static const maxUploadSizeBytes = 'MobileApp:MaxUploadSizeBytes';
}
```

Keys must match the backend `ConfigurationSetting.Key` values exactly
(the backend uses `Category:SettingName` format).

### Typed Getters

The `AppConfigurationGetters` extension on `AppConfiguration` exposes
every config value as a typed, IDE-discoverable getter:

```dart
extension AppConfigurationGetters on AppConfiguration {
  String get minVersion => getString(ConfigKeys.minVersion);
  String get supportEmail => getString(ConfigKeys.supportEmail);
  bool get isEventsEnabled => getBool(ConfigKeys.featureEventsEnabled, defaultValue: true);
  bool get isGuestsEnabled => getBool(ConfigKeys.featureGuestsEnabled, defaultValue: true);
  int get maxUploadSizeBytes => getInt(ConfigKeys.maxUploadSizeBytes, defaultValue: 10485760);
}
```

### Default Values

`kDefaultConfiguration` in `defaults.dart` provides offline-first fallback
values for first launch when no cache exists and the backend is unreachable.
It uses `ConfigKeys.*` constants — never raw strings.

## Reading Config Values in Features

After splash completes, `appConfigurationProvider` is resolved and cached.
Use one of these patterns depending on context:

### In an async provider or controller

```dart
final config = await ref.read(appConfigurationProvider.future);
if (config.isEventsEnabled) {
  // feature is on
}
```

### Synchronously (splash guarantees the value is loaded)

```dart
final config = ref.read(appConfigurationProvider).requireValue;
final email = config.supportEmail;
```

### In a widget (reactive)

```dart
final configAsync = ref.watch(appConfigurationProvider);
return configAsync.when(
  data: (config) => Text(config.supportEmail),
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

## Adding a New Config Key

Follow these steps whenever a new configuration setting is added on the
backend:

1. **Add the constant** to `ConfigKeys` in
   `lib/core/remote_config/domain/config_keys.dart`.

2. **Add the default value** to `kDefaultConfiguration` in
   `lib/core/remote_config/domain/defaults.dart`, using the
   `ConfigKeys.*` constant as the map key.

3. **Add a typed getter** to the `AppConfigurationGetters` extension in
   `lib/core/remote_config/domain/models/app_configuration.dart`.
   Pick the right type (`getString`, `getBool`, `getInt`, `getDouble`)
   and provide a sensible `defaultValue`.

4. **Add tests** for the new getter in
   `test/core/remote_config/domain/models/app_configuration_test.dart`.

5. **Use the typed getter** in feature code — never pass raw key strings
   to `getString`/`getBool`/`getInt`/`getDouble` outside of the extension.

## Storage

Cached configuration is stored in SharedPreferences as a single JSON
string. Drift is intentionally not used — the data is a flat key-value
map with no relational needs.

## Rules

- **DO** use `ConfigKeys.*` constants for all key references.
- **DO** use typed getters (`config.isEventsEnabled`) in feature code.
- **DO** add a default value in `kDefaultConfiguration` for every key.
- **DO** add tests for every new typed getter.
- **DO NOT** use raw key strings (`'MobileApp:...'`) outside of `ConfigKeys`.
- **DO NOT** call `getString`/`getBool`/`getInt`/`getDouble` directly in
  feature code — add a typed getter to the extension instead.
- **DO NOT** store config in Drift — SharedPreferences is the chosen store.
