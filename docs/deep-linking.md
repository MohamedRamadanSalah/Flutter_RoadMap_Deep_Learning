# Deep Linking

## Overview

The app uses **App Links** (Android) and **Universal Links** (iOS) for deep
linking. Custom URL schemes (`hayyacom://`) MUST NOT be used in production —
they are insecure and not verifiable.

`go_router` handles route matching. `app_links` listens for incoming links.

## How It Works

```
User taps link → OS verifies domain ownership → App opens → go_router matches route
```

If the app is not installed, the link opens in the browser (where you can
show a "Get the app" page).

## Android App Links

### 1. Configure AndroidManifest.xml

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<activity android:name=".MainActivity" ...>
  <intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
      android:scheme="https"
      android:host="hayyacom.com"
      android:pathPrefix="/app" />
  </intent-filter>
</activity>
```

### 2. Host assetlinks.json

Serve at `https://hayyacom.com/.well-known/assetlinks.json`:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.hayyacom.mobile",
      "sha256_cert_fingerprints": [
        "<SHA-256 of your signing key>"
      ]
    }
  }
]
```

Get SHA-256:
```sh
keytool -list -v -keystore <keystore-path> -alias <alias>
```

### 3. Verify

```sh
adb shell am start -a android.intent.action.VIEW \
  -d "https://hayyacom.com/app/orders/abc-123" \
  com.hayyacom.mobile
```

## iOS Universal Links

### 1. Configure Associated Domains

In Xcode: Runner → Signing & Capabilities → Associated Domains:

```
applinks:hayyacom.com
```

Or in `ios/Runner/Runner.entitlements`:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:hayyacom.com</string>
</array>
```

### 2. Host apple-app-site-association

Serve at `https://hayyacom.com/.well-known/apple-app-site-association`
(no file extension, `Content-Type: application/json`):

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appIDs": ["<TEAM_ID>.com.hayyacom.mobile"],
        "components": [
          { "/": "/app/*" }
        ]
      }
    ]
  }
}
```

### 3. Verify

```sh
# Check Apple's CDN cache
curl -v "https://app-site-association.cdn-apple.com/a/v1/hayyacom.com"
```

Or use Apple's [Search Validation Tool](https://search.developer.apple.com/appsearch-validation-tool/).

## GoRouter Integration

### Route Matching

Deep links match against GoRouter's route tree naturally:

```dart
// lib/features/orders/presentation/routes.dart
final orderRoutes = <RouteBase>[
  GoRoute(
    path: '/app/orders',
    name: 'orders',
    builder: (context, state) => const OrderListScreen(),
    routes: [
      GoRoute(
        path: ':orderId',
        name: 'order-detail',
        builder: (context, state) => OrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
    ],
  ),
];
```

Link `https://hayyacom.com/app/orders/abc-123` resolves to
`OrderDetailScreen(orderId: 'abc-123')`.

### Listening for Links

`app_links` automatically handles both initial link (app launched from link)
and stream links (app already running):

```dart
// lib/core/router/deep_link_handler.dart
import 'package:app_links/app_links.dart';

@riverpod
class DeepLinkHandler extends _$DeepLinkHandler {
  @override
  void build() {
    final appLinks = AppLinks();
    final router = ref.watch(routerProvider);

    // Handle link when app is already running
    appLinks.uriLinkStream.listen((uri) {
      router.go(uri.path);
    });

    // Handle initial link (app launched from link)
    appLinks.getInitialLink().then((uri) {
      if (uri != null) router.go(uri.path);
    });
  }
}
```

## URL Structure

Define a consistent URL scheme:

| URL Pattern | Screen |
|-------------|--------|
| `https://hayyacom.com/app/orders` | Order list |
| `https://hayyacom.com/app/orders/:id` | Order detail |
| `https://hayyacom.com/app/invite/:code` | Invitation acceptance |
| `https://hayyacom.com/app/profile` | User profile |

All deep-linkable routes use the `/app/` prefix to distinguish from
website-only pages.

## Testing Deep Links

### Android

```sh
# Test via adb
adb shell am start -a android.intent.action.VIEW \
  -d "https://hayyacom.com/app/orders/abc-123"

# Verify App Links status
adb shell pm get-app-links com.hayyacom.mobile
```

### iOS

```sh
# Open URL in simulator
xcrun simctl openurl booted "https://hayyacom.com/app/orders/abc-123"
```

### Checklist

- [ ] `assetlinks.json` is served with correct SHA-256 fingerprints
- [ ] `apple-app-site-association` is served with correct Team ID
- [ ] Links open the app (not the browser) on both platforms
- [ ] Auth guard redirects to login if user is not authenticated
- [ ] After login, user is redirected to the originally requested deep link
- [ ] Invalid deep link paths show 404 / fallback screen

## Rules

- **DO** use `https://` scheme only — verified App Links / Universal Links.
- **DO** prefix all deep-linkable routes with `/app/`.
- **DO** host verification files at `/.well-known/` on the production domain.
- **DO** test deep links on both platforms before merge.
- **DO NOT** use custom URL schemes (`hayyacom://`) in production.
- **DO NOT** hardcode deep link URLs in app code — derive from route definitions.
