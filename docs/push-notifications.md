# Push Notifications

## Overview

Push notifications use Firebase Cloud Messaging (FCM) for delivery and
`flutter_local_notifications` for foreground display and rich content.
Both are wrapped in a single `NotificationService` in `lib/core/notifications/`.

## Architecture

```
lib/core/notifications/
├── notification_service.dart     # Unified service (FCM + local)
└── notification_channels.dart    # Android channel definitions
```

## Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com).
2. Create a project (or use existing).
3. Add Android app with package name `com.hayyacom.mobile`.
4. Add iOS app with bundle ID `com.hayyacom.mobile`.
5. Download `google-services.json` → `android/app/`.
6. Download `GoogleService-Info.plist` → `ios/Runner/`.

### 2. Android Configuration

`google-services.json` is auto-detected by the Firebase Gradle plugin.
No additional code changes needed — the plugin is already in the project.

### 3. iOS Configuration

1. Enable Push Notifications capability in Xcode:
   - Open `ios/Runner.xcworkspace`.
   - Runner → Signing & Capabilities → + Capability → Push Notifications.
2. Enable Background Modes → Remote notifications.
3. Upload APNs key to Firebase Console:
   - Apple Developer → Keys → Create key with APNs.
   - Firebase Console → Project Settings → Cloud Messaging → Upload APNs key.

## Notification Channels (Android)

Android 8+ requires notification channels:

```dart
// lib/core/notifications/notification_channels.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract final class NotificationChannels {
  static const general = AndroidNotificationChannel(
    'general',
    'General',
    description: 'General notifications',
    importance: Importance.defaultImportance,
  );

  static const orders = AndroidNotificationChannel(
    'orders',
    'Orders',
    description: 'Order status updates',
    importance: Importance.high,
  );

  static List<AndroidNotificationChannel> get all => [general, orders];
}
```

Create channels on init:

```dart
Future<void> _createChannels() async {
  final plugin = _localNotifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  if (plugin != null) {
    for (final channel in NotificationChannels.all) {
      await plugin.createNotificationChannel(channel);
    }
  }
}
```

## NotificationService Implementation

```dart
// lib/core/notifications/notification_service.dart
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final _messageController = StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onMessageReceived => _messageController.stream;

  Future<void> init() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );
    await _local.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android channels
    await _createChannels();

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((message) {
      _messageController.add(message);
      _showLocalNotification(message);
    });

    // Background → foreground tap handler
    FirebaseMessaging.onMessageOpenedApp.listen(_messageController.add);

    // App opened from terminated state via notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _messageController.add(initialMessage);
    }
  }

  Future<NotificationSettings> requestPermission() {
    return _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> getToken() => _fcm.getToken();

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          NotificationChannels.general.id,
          NotificationChannels.general.name,
          channelDescription: NotificationChannels.general.description,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['route'],
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Navigate based on payload
    final route = response.payload;
    if (route != null) {
      // Use GoRouter to navigate — this is wired via the provider
    }
  }

  void dispose() {
    _messageController.close();
  }
}
```

## Permission Flow

### iOS

iOS requires explicit permission. Request **after** onboarding, not on first launch:

```dart
// In the appropriate screen/controller:
final settings = await ref.read(notificationServiceProvider).requestPermission();
if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  final token = await ref.read(notificationServiceProvider).getToken();
  // Send token to backend
}
```

### Android

Android 13+ (API 33) requires `POST_NOTIFICATIONS` permission. For API 24–32,
notifications work without runtime permission.

The `firebase_messaging` plugin handles the permission request automatically.
You can also request it explicitly via the same `requestPermission()` method.

## FCM Token Management

Send the FCM token to the backend on:
1. First login.
2. Token refresh (subscribe to `FirebaseMessaging.instance.onTokenRefresh`).

```dart
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  // Send to backend
  ref.read(authRepositoryProvider).updateFcmToken(newToken);
});
```

## Message Types

| Type | Behavior |
|------|----------|
| **Notification message** | FCM auto-displays when app is backgrounded; `onMessage` fires in foreground |
| **Data message** | Never auto-displayed; always delivered to `onMessage` handler |
| **Notification + Data** | Hybrid — notification auto-displays in background, data accessible via `message.data` |

Use **data-only messages** when you need full control over display format.

## Background Message Handler

For processing messages when the app is killed:

```dart
// Must be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  // Process message (e.g., update badge count)
  // Do NOT access UI or providers here
}

// Register in main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  // ...
}
```

## Rules

- **DO** wrap FCM + local notifications in the single `NotificationService`.
- **DO** create Android notification channels on init.
- **DO** request permission **after** onboarding, not on cold start.
- **DO** handle all three message entry points (foreground, background, terminated).
- **DO** send FCM token to backend on login and token refresh.
- **DO NOT** use the `NotificationService` directly from presentation — go through a provider.
- **DO NOT** ignore the background message handler — messages arrive when the app is killed.
- **DO NOT** access Riverpod providers in the background handler (no `ref` available).
