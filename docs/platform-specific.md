# Platform-Specific Code

## Overview

The app must deliver a platform-appropriate experience on both iOS and
Android. Platform-specific code is isolated behind abstractions so the
rest of the codebase stays platform-agnostic.

## Deployment Targets

| Platform | Minimum |
|----------|---------|
| iOS | 14.0 |
| Android | API 24 (Nougat) |

## Adaptive Widgets

Use adaptive widgets where iOS and Android conventions diverge:

```dart
// Adaptive dialog
import 'dart:io';

Future<bool?> showAdaptiveConfirmDialog(BuildContext context) {
  return showAdaptiveDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text(t.common.confirm),
      content: Text(t.orders.deleteConfirmation),
      actions: [
        adaptiveAction(
          context: context,
          onPressed: () => Navigator.pop(context, false),
          child: Text(t.common.cancel),
        ),
        adaptiveAction(
          context: context,
          onPressed: () => Navigator.pop(context, true),
          child: Text(t.common.delete),
        ),
      ],
    ),
  );
}

Widget adaptiveAction({
  required BuildContext context,
  required VoidCallback onPressed,
  required Widget child,
}) {
  if (Platform.isIOS) {
    return CupertinoDialogAction(onPressed: onPressed, child: child);
  }
  return TextButton(onPressed: onPressed, child: child);
}
```

### When to Use Adaptive Widgets

| Component | Use adaptive? | Why |
|-----------|--------------|-----|
| Dialogs / alerts | Yes | iOS expects `CupertinoAlertDialog` |
| Date/time pickers | Yes | iOS expects bottom-sheet spinner |
| Action sheets | Yes | iOS expects `CupertinoActionSheet` |
| Switches | Yes | `Switch.adaptive` uses Cupertino on iOS |
| Navigation (tabs, drawer) | No | Use Material 3 — Hayyacom has a unified design |
| Buttons | No | Use Material 3 design system |
| Text fields | No | Use Material 3 design system |

## Platform-Specific Code Isolation

When logic differs by platform, isolate it:

### Pattern 1: Conditional at the Boundary

For simple checks (1-2 lines):

```dart
if (Platform.isIOS) {
  await _requestTrackingPermission();
}
```

### Pattern 2: Separate Implementation Files

For complex divergence, split into platform files:

```
lib/core/services/
├── haptic_service.dart            # Abstract interface
├── haptic_service_ios.dart        # iOS implementation
└── haptic_service_android.dart    # Android implementation
```

```dart
// haptic_service.dart
abstract class HapticService {
  factory HapticService() {
    if (Platform.isIOS) return HapticServiceIos();
    return HapticServiceAndroid();
  }

  void lightImpact();
  void mediumImpact();
}
```

### Pattern 3: Platform Channels (Last Resort)

Only for native APIs with no Flutter plugin. Use `MethodChannel`:

```dart
class NativeService {
  static const _channel = MethodChannel('com.hayyacom.mobile/native');

  Future<String> getPlatformData() async {
    return await _channel.invokeMethod('getPlatformData');
  }
}
```

Prefer existing Flutter plugins over custom platform channels.

## Permissions

### Android

Permissions are declared in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
```

Runtime permissions are requested via the relevant Flutter plugin
(e.g., `mobile_scanner` handles camera permission internally).

### iOS

Permissions require usage descriptions in `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed to scan QR codes</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is needed to upload images</string>
```

### Permission Request Flow

1. Check if permission is granted.
2. If not, show a **pre-permission dialog** explaining why (improves grant rate).
3. Request the system permission.
4. If denied, show a message with a "Settings" button to open app settings.

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestCameraPermission(BuildContext context) async {
  final status = await Permission.camera.status;
  if (status.isGranted) return true;

  // Show rationale first
  final proceed = await showAdaptiveConfirmDialog(context);
  if (proceed != true) return false;

  final result = await Permission.camera.request();
  if (result.isPermanentlyDenied) {
    await openAppSettings();
  }
  return result.isGranted;
}
```

> **Note**: `permission_handler` is not in the approved package list.
> If needed, add it to the constitution via PR. Otherwise, rely on
> plugin-level permission handling (e.g., `mobile_scanner` auto-requests
> camera permission).

## Platform Testing Checklist

Before any PR is merged, verify on **both** platforms:

- [ ] Push notifications display correctly
- [ ] Deep links open the correct screen
- [ ] Permission dialogs show appropriate messages
- [ ] Adaptive widgets render platform-appropriate UI
- [ ] Back button / swipe-back works as expected
- [ ] Keyboard dismisses properly
- [ ] Status bar and safe area are respected
- [ ] App handles interruptions (phone call, split-screen)

## Rules

- **DO** use `AlertDialog.adaptive`, `Switch.adaptive`, and similar adaptive APIs.
- **DO** isolate platform-specific code behind abstractions.
- **DO** test on both iOS and Android before merge.
- **DO** add `Info.plist` usage descriptions for every iOS permission.
- **DO NOT** scatter `Platform.isIOS` checks throughout feature code — push to boundaries.
- **DO NOT** use custom URL schemes for deep links — use App Links / Universal Links.
- **DO NOT** use platform channels when a Flutter plugin exists.
