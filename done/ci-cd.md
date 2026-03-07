# CI/CD Pipeline

## Overview

GitHub Actions for CI, Fastlane for build automation, Firebase App Distribution
for beta delivery, Shorebird for OTA Dart patches.

## Pipeline Summary

```
PR checks (Linux):
  flutter analyze → flutter test → dart format --set-exit-if-changed .

Staging build (Linux + macOS):
  Fastlane build → Firebase App Distribution upload

Production release (Linux + macOS):
  Fastlane build → Google Play / App Store Connect upload
  shorebird release (enables future patches)

Hotfix (Dart-only):
  shorebird patch android → shorebird patch ios
```

## GitHub Actions

CI config: `.github/workflows/ci.yml`

### Jobs

| Job | Runner | Trigger | Steps |
|-----|--------|---------|-------|
| `analyze-and-test` | ubuntu-latest | Push to main, PRs | format, analyze, test |
| `build-android` | ubuntu-latest | After analyze-and-test | flutter build apk --release |
| `build-ios` | macos-latest | After analyze-and-test | flutter build ios --release --no-codesign |

### Required Secrets

Configure in **GitHub → Settings → Secrets and Variables → Actions**:

| Secret | Purpose |
|--------|---------|
| `FIREBASE_ANDROID_APP_ID` | Firebase App Distribution Android app ID |
| `FIREBASE_IOS_APP_ID` | Firebase App Distribution iOS app ID |
| `FIREBASE_TOKEN` | Firebase CLI auth token (`firebase login:ci`) |
| `MATCH_GIT_URL` | Private repo URL for Fastlane Match certificates |
| `MATCH_PASSWORD` | Encryption password for Match certificates |
| `APPLE_CONNECT_API_KEY` | App Store Connect API key (JSON) |
| `SHOREBIRD_TOKEN` | Shorebird CLI auth token |

### Caching

The CI caches:
- **Pub** dependencies (`~/.pub-cache`)
- **Gradle** caches + wrapper (`~/.gradle/`)
- **CocoaPods** (`ios/Pods/`)

Cache keys are based on lock file hashes for automatic invalidation.

## Fastlane

### iOS (`ios/fastlane/Fastfile`)

```ruby
default_platform(:ios)

platform :ios do
  desc 'Build and upload beta to Firebase App Distribution'
  lane :beta do
    # Match manages certificates + profiles
    match(type: 'adhoc', readonly: true)

    build_app(
      workspace: 'Runner.xcworkspace',
      scheme: 'Runner',
      export_method: 'ad-hoc',
    )

    firebase_app_distribution(
      app: ENV['FIREBASE_IOS_APP_ID'],
      groups: 'internal-testers',
    )
  end

  desc 'Build and upload to App Store Connect'
  lane :release do
    match(type: 'appstore', readonly: true)

    build_app(
      workspace: 'Runner.xcworkspace',
      scheme: 'Runner',
      export_method: 'app-store',
    )

    upload_to_app_store(skip_metadata: true, skip_screenshots: true)
  end
end
```

### Android (`android/fastlane/Fastfile`)

```ruby
default_platform(:android)

platform :android do
  desc 'Build and upload beta to Firebase App Distribution'
  lane :beta do
    gradle(task: 'assemble', build_type: 'Release', project_dir: '.')

    firebase_app_distribution(
      app: ENV['FIREBASE_ANDROID_APP_ID'],
      groups: 'internal-testers',
      android_artifact_type: 'APK',
    )
  end

  desc 'Build and upload to Google Play'
  lane :release do
    gradle(task: 'bundle', build_type: 'Release', project_dir: '.')

    upload_to_play_store(
      track: 'internal',
      aab: '../build/app/outputs/bundle/release/app-release.aab',
    )
  end
end
```

### Fastlane Match (iOS Signing)

Match stores certificates in a **private Git repo**:

```sh
# First-time setup (run locally, not on CI)
fastlane match init
fastlane match adhoc     # For beta builds
fastlane match appstore  # For production builds
```

CI uses `readonly: true` to prevent accidental certificate regeneration.

### Gemfile

Both `Gemfile` and `Gemfile.lock` must be committed:

```ruby
source "https://rubygems.org"
gem "fastlane"
gem "fastlane-plugin-firebase_app_distribution"
```

```sh
bundle install           # Install gems
bundle exec fastlane ios beta    # Run lane
```

## Firebase App Distribution

### Setup

1. Install plugin: `fastlane add_plugin firebase_app_distribution`
2. Generate Firebase CLI token: `firebase login:ci`
3. Add token as `FIREBASE_TOKEN` secret in GitHub Actions.
4. Create tester group `internal-testers` in Firebase Console.

### Manual Upload

```sh
cd ios && bundle exec fastlane beta
cd android && bundle exec fastlane beta
```

## Shorebird (OTA Updates)

### What Can Be Patched

| Change | Patchable? |
|--------|-----------|
| Dart code changes | Yes |
| New/modified assets | No — full release required |
| Native code changes | No — full release required |
| Plugin version bumps | No — full release required |
| pubspec.yaml changes | Depends — Dart-only deps yes, native deps no |

### Workflow

```sh
# 1. Create a release (stores baseline)
shorebird release android
shorebird release ios

# 2. Later, push a Dart-only patch
shorebird patch android
shorebird patch ios
```

### Configuration

`shorebird.yaml` at project root:

```yaml
app_id: <your-shorebird-app-id>
```

Get app ID: `shorebird init`

### Release vs Patch Decision Tree

1. Does the change touch `android/`, `ios/`, or native plugins? → **Full release**
2. Does the change modify assets (images, SVGs, fonts)? → **Full release**
3. Is it Dart-only? → **Shorebird patch**

## Build Verification

Constitution requires both platforms to build on every PR:

```yaml
# CI must include:
- flutter build apk --release    # Android
- flutter build ios --release --no-codesign  # iOS
```

Both must succeed before merge.

## Rules

- **DO** use Linux runners for analysis, testing, and Android builds.
- **DO** use macOS runners only for iOS builds.
- **DO** use Fastlane Match with `readonly: true` on CI.
- **DO** commit both `Gemfile` and `Gemfile.lock`.
- **DO** use `shorebird release` (not `flutter build`) for production artifacts.
- **DO NOT** store signing keys or tokens in the repo — use GitHub Secrets.
- **DO NOT** regenerate Match certificates on CI.
- **DO NOT** skip CI checks — all must pass before merge.
