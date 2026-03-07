# SVG Icons

## Overview

All SVG assets are pre-compiled to `.vec` binary format at build time using
`vector_graphics_compiler`. This eliminates runtime SVG parsing and improves
render performance.

## Adding an SVG

1. Place the `.svg` file in `assets/svg/`.
2. Run `flutter pub get` (the asset transformer is declared in `pubspec.yaml`).
3. The compiler runs automatically during `flutter build` and `flutter run`.

## Using in Code

```dart
import 'package:flutter_svg/flutter_svg.dart';

// Flutter automatically serves the compiled .vec at runtime
SvgPicture.asset('assets/svg/icon_name.svg');

// With sizing
SvgPicture.asset(
  'assets/svg/icon_name.svg',
  width: 24,
  height: 24,
);

// With color override (uses theme color)
SvgPicture.asset(
  'assets/svg/icon_name.svg',
  colorFilter: ColorFilter.mode(
    Theme.of(context).colorScheme.primary,
    BlendMode.srcIn,
  ),
);
```

## Rules

- **DO** use `SvgPicture.asset()` for all local SVG assets.
- **DO** place all SVGs in `assets/svg/` — the transformer only scans this directory.
- **DO NOT** use `SvgPicture.string()` or `SvgPicture.network()` for static assets.
- **DO NOT** reference `.vec` files directly — Flutter resolves them automatically
  from the `.svg` path.

## Testing the Compiler

To verify an SVG compiles correctly without a full build:

```sh
dart run vector_graphics_compiler --input assets/svg/file.svg --output /tmp/test.vec
```

## Supported SVG Features

The compiler supports standard SVG elements (paths, shapes, gradients, transforms).
Embedded raster images via `<image xlink:href="data:image/png;base64,..."/>` are
supported but should be avoided — use raster assets in `assets/images/` instead
for better control over resolution variants.
