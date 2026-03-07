# Native Splash Screen

## Overview

The native splash screen is the first visual shown during cold start, before the
Flutter engine initializes. It is managed by `flutter_native_splash` (dev
dependency) which generates platform-specific resources for Android (pre-12 and
12+) and iOS. The Flutter-level splash screen (`SplashScreen` widget) takes over
once the engine draws its first frame.

**Package**: [`flutter_native_splash`](https://pub.dev/packages/flutter_native_splash)
(dev dependency only — zero runtime cost, nothing shipped in the app binary)

## Why a Dedicated Package?

Android 12+ introduced a new `SplashScreen` API that always displays an app icon
with a circular mask (160 dp visible within 240 dp). Without explicit
configuration, the system shows the default Flutter launcher icon. Manual
`values-v31/styles.xml` setup requires converting the logo to an Android Vector
Drawable with precise sizing for the circular mask — error-prone and hard to
maintain. `flutter_native_splash` handles all density buckets, the Android 12
circular mask, dark mode variants, and iOS in a single config file.

## Architecture

```
flutter_native_splash.yaml          # Config (colors, image paths, platforms)

assets/splash/
├── logo.png                        # White logo on transparent (500×519 px)
└── logo_android12.png              # White logo centered on 1152×1152 transparent canvas

Generated outputs (DO NOT edit manually):
  android/app/src/main/res/
  ├── drawable-{mdpi..xxxhdpi}/
  │   ├── splash.png                # Pre-12 logo at each density
  │   ├── android12splash.png       # Android 12+ logo at each density
  │   └── background.png            # Solid color background
  ├── drawable-night-{mdpi..xxxhdpi}/
  │   ├── splash.png                # Dark mode variants
  │   ├── android12splash.png
  │   └── background.png
  ├── drawable/launch_background.xml
  ├── drawable-night/launch_background.xml
  ├── drawable-v21/launch_background.xml
  ├── drawable-night-v21/launch_background.xml
  ├── values-v31/styles.xml         # Android 12+ SplashScreen API theme
  ├── values-night-v31/styles.xml   # Android 12+ dark mode theme
  ├── values/styles.xml             # Pre-12 launch theme (updated)
  └── values-night/styles.xml       # Pre-12 dark launch theme (updated)

  ios/Runner/
  ├── Assets.xcassets/
  │   ├── LaunchImage.imageset/     # Logo at 1x, 2x, 3x + dark variants
  │   └── LaunchBackground.imageset/ # Solid color backgrounds
  └── Base.lproj/LaunchScreen.storyboard  # Updated with image views
```

## Configuration

All settings live in `flutter_native_splash.yaml` at the project root:

```yaml
flutter_native_splash:
  # Light mode
  color: "#881A2C"                      # AppPalette.primary500
  image: assets/splash/logo.png

  # Dark mode
  color_dark: "#1A1A1A"                 # AppPalette.neutral900
  image_dark: assets/splash/logo.png

  # Android 12+ (separate API — circular icon mask)
  android_12:
    color: "#881A2C"
    image: assets/splash/logo_android12.png   # 1152×1152, logo within 768 px circle
    color_dark: "#1A1A1A"
    image_dark: assets/splash/logo_android12.png

  # Platform flags
  android: true
  ios: true
  web: false
```

### Color Reference

| Mode  | Background | Source |
|-------|-----------|--------|
| Light | `#881A2C` | `AppPalette.primary500` (brand crimson) |
| Dark  | `#1A1A1A` | `AppPalette.neutral900` |

## Image Assets

### Source Images

Both PNGs are generated from the Figma logo SVG (`assets/svg/logo.svg`) using
`rsvg-convert` + Python Pillow. The logo is white on transparent background.

| File | Dimensions | Purpose |
|------|-----------|---------|
| `assets/splash/logo.png` | 500 × 519 px | Pre-Android 12 + iOS (centered on background) |
| `assets/splash/logo_android12.png` | 1152 × 1152 px | Android 12+ (logo centered, fits within 768 px circle mask) |

### Android 12+ Icon Sizing

Android 12's splash screen masks the icon to a circle:
- Icon canvas: **240 dp** (1152 px at xxxhdpi)
- Visible circle: **160 dp** (768 px at xxxhdpi)
- Logo content must fit inside the 768 px circle or it gets clipped

### Regenerating PNGs from SVG

If the logo SVG changes, regenerate the splash PNGs:

```sh
# Requires: brew install librsvg, pip3 install Pillow

# Regular splash logo (4.6x scale)
rsvg-convert -w 500 -h 519 assets/svg/logo.svg -o assets/splash/logo.png

# Android 12 icon (centered on 1152×1152 transparent canvas)
rsvg-convert -w 500 -h 519 assets/svg/logo.svg -o /tmp/logo_large.png
python3 -c "
from PIL import Image
logo = Image.open('/tmp/logo_large.png').convert('RGBA')
canvas = Image.new('RGBA', (1152, 1152), (0, 0, 0, 0))
canvas.paste(logo, ((1152 - logo.width) // 2, (1152 - logo.height) // 2), logo)
canvas.save('assets/splash/logo_android12.png')
"
```

Then regenerate the native resources:

```sh
dart run flutter_native_splash:create --path=flutter_native_splash.yaml
```

## Commands

```sh
# Generate / regenerate native splash resources
dart run flutter_native_splash:create --path=flutter_native_splash.yaml

# Remove all generated splash resources (revert to defaults)
dart run flutter_native_splash:remove --path=flutter_native_splash.yaml
```

## How It Works at Runtime

### Cold Start Sequence

1. **Native splash** (OS-level, before Flutter engine):
   - **Android < 12**: `LaunchTheme` → `launch_background.xml` (crimson +
     centered logo bitmap)
   - **Android 12+**: `SplashScreen` API → crimson background + logo in circular
     mask (from `values-v31/styles.xml`)
   - **iOS**: `LaunchScreen.storyboard` → crimson background + centered
     `LaunchImage`
2. **Flutter engine starts** — native splash removed automatically when first
   frame draws
3. **Flutter `SplashScreen` widget** — same crimson background + SVG logo,
   visible for 2.5 s, then navigates to `/onboarding`

### Why Two Splash Screens?

The native splash covers the gap while the Flutter engine boots (~1–2 s on cold
start). The Flutter splash screen handles the timed delay and navigation logic.
Using matching colors and logo ensures a seamless visual transition — the user
perceives one continuous splash.

## Rules

- **DO** run the generator after any change to `flutter_native_splash.yaml` or
  the source PNGs.
- **DO** commit the generated files — they are needed for builds without running
  the generator.
- **DO** keep `logo.png` and `logo_android12.png` as white-on-transparent PNGs.
- **DO** keep the native splash colors in sync with `AppPalette.primary500`
  (light) and `AppPalette.neutral900` (dark).
- **DO NOT** edit the generated files under `android/app/src/main/res/` or
  `ios/Runner/Assets.xcassets/` manually — they will be overwritten.
- **DO NOT** change splash colors in the YAML without also updating
  `android/app/src/main/res/values/colors.xml` and `values-night/colors.xml`
  (used by `launch_background.xml`).
- **DO NOT** use `flutter_native_splash` for anything beyond the native splash —
  the Flutter-level splash screen is a regular widget in
  `lib/features/splash/`.
