# Theming — Dark / Light Mode

## Overview

Material 3 seed-based theming with **`ThemeExtension`** for custom semantic
tokens, a Riverpod-managed theme mode preference persisted to
`SharedPreferences`, and component-level theme overrides that resolve correctly
in both light and dark modes. No third-party theming packages.

## Design Principles

1. **Seed + brand overrides** — `ColorScheme.fromSeed()` generates all 40+ M3
   color roles from the brand seed. Primary and error families are overridden
   with exact Figma hex values via `.copyWith()`.
2. **Semantic tokens for custom colors** — Colors outside M3's palette (success,
   warning, info, shimmer) live in a `ThemeExtension<AppColors>` that
   automatically resolves per brightness.
3. **Zero hardcoded colors in widgets** — Every color reference goes through
   `colorScheme`, `textTheme`, or `AppColors`. Widgets never import color
   constants or use `Colors.*` directly.
4. **System default, user override** — Default to `ThemeMode.system`. Let the
   user pick system / light / dark and persist the choice.
5. **Theme objects are created once** — `ThemeData` instances are `static final`,
   not rebuilt inside `build()`.

## Architecture

```
lib/core/theme/
├── app_theme.dart           # ThemeData factory (light + dark)
├── app_colors.dart          # AppPalette constants + ThemeExtension<AppColors>
├── app_component_themes.dart # Component-level theme overrides
├── app_spacing.dart         # Elastic spacing (see responsive-sizing.md)
└── app_breakpoints.dart     # Breakpoint helpers (see responsive-sizing.md)

lib/core/providers/
└── theme_mode_provider.dart # @Riverpod notifier + SharedPreferences persistence
```

---

## 1. Figma Palette — `AppPalette`

All color constants live in `app_colors.dart` as `AppPalette`. These map 1:1
to the Figma "Colors" frame (node `11:6152`).

| Shade | Primary | Neutral | Success | Warning | Error | Info |
|-------|---------|---------|---------|---------|-------|------|
| 100 | `#FCE3E7` | `#FFFFFF` | `#DAF1DC` | `#FFF5CC` | `#F2D9DC` | `#DCE4EF` |
| 200 | `#EFA9B5` | `#E6E6E6` | `#B6E2B8` | `#FFEB99` | `#E6B2B8` | `#B9C8DF` |
| 300 | `#E67F90` | `#CCCCCC` | `#91D495` | `#FFE066` | `#D98C95` | `#95ADD0` |
| 400 | `#DE546B` | `#B3B3B3` | `#6DC571` | `#FFD633` | `#CD6571` | `#7291C0` |
| 500 | `#881A2C` | `#999999` | `#388E3C` | `#E6B800` | `#B23A48` | `#4A6EA5` |
| 600 | `#AB2138` | `#666666` | `#3A923E` | `#CCA300` | `#9A323E` | `#3F5E8D` |
| 700 | `#80192A` | `#4D4D4D` | `#2B6E2F` | `#997A00` | `#73262F` | `#2F476A` |
| 800 | `#56101C` | `#333333` | `#1D491F` | `#665200` | `#4D191F` | `#202F46` |
| 900 | `#2B080E` | `#1A1A1A` | `#0E2510` | `#332900` | `#260D10` | `#101823` |

Access in code: `AppPalette.primary600`, `AppPalette.success300`, etc.

**Widgets must NOT import `AppPalette` directly.** Use `colorScheme` or
`context.appColors` instead. `AppPalette` is consumed only by `AppTheme` and
`AppColors`.

---

## 2. Color Scheme — `ColorScheme.fromSeed()` + Brand Overrides

The seed color is **Primary/600 (`#AB2138`)**, the brand crimson. `fromSeed()`
generates all surface containers, secondary, and tertiary roles automatically.
Primary and error families are overridden with exact Figma values:

```dart
// lib/core/theme/app_theme.dart
static final _lightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFFAB2138), // Primary/600
  brightness: Brightness.light,
).copyWith(
  primary: AppPalette.primary600,       // #AB2138
  onPrimary: AppPalette.neutral100,     // #FFFFFF
  primaryContainer: AppPalette.primary100, // #FCE3E7
  onPrimaryContainer: AppPalette.primary900, // #2B080E
  error: AppPalette.error500,           // #B23A48
  onError: AppPalette.neutral100,       // #FFFFFF
  errorContainer: AppPalette.error100,  // #F2D9DC
  onErrorContainer: AppPalette.error900, // #260D10
);

static final _darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFFAB2138),
  brightness: Brightness.dark,
).copyWith(
  primary: AppPalette.primary300,       // #E67F90
  onPrimary: AppPalette.primary900,     // #2B080E
  primaryContainer: AppPalette.primary800, // #56101C
  onPrimaryContainer: AppPalette.primary100, // #FCE3E7
  error: AppPalette.error300,           // #D98C95
  onError: AppPalette.error900,         // #260D10
  errorContainer: AppPalette.error800,  // #4D191F
  onErrorContainer: AppPalette.error100, // #F2D9DC
);
```

### Key M3 Color Roles

Use these instead of raw colors:

| Need | Role |
|------|------|
| Primary accent | `colorScheme.primary` |
| Text on primary | `colorScheme.onPrimary` |
| Page background | `colorScheme.surface` |
| Text on background | `colorScheme.onSurface` |
| Card background | `colorScheme.surfaceContainerLow` |
| Elevated card | `colorScheme.surfaceContainer` |
| Highest emphasis surface | `colorScheme.surfaceContainerHighest` |
| Subtle borders | `colorScheme.outlineVariant` |
| Error states | `colorScheme.error` / `onError` |
| Disabled content | `colorScheme.onSurface` with 0.38 alpha |

### Deprecated Roles — Do Not Use

| Deprecated | Use instead |
|------------|-------------|
| `background` | `surface` |
| `onBackground` | `onSurface` |
| `surfaceVariant` | `surfaceContainerHighest` |

---

## 3. Custom Semantic Tokens — `ThemeExtension<AppColors>`

M3 does not have built-in roles for success, warning, or info. These live in a
`ThemeExtension` with separate light and dark instances, each referencing
`AppPalette` shades:

| Token | Light | Dark |
|-------|-------|------|
| `success` | Success/500 `#388E3C` | Success/300 `#91D495` |
| `onSuccess` | Neutral/100 `#FFFFFF` | Success/900 `#0E2510` |
| `successContainer` | Success/100 `#DAF1DC` | Success/800 `#1D491F` |
| `onSuccessContainer` | Success/900 `#0E2510` | Success/100 `#DAF1DC` |
| `warning` | Warning/500 `#E6B800` | Warning/300 `#FFE066` |
| `onWarning` | Warning/900 `#332900` | Warning/900 `#332900` |
| `warningContainer` | Warning/100 `#FFF5CC` | Warning/800 `#665200` |
| `onWarningContainer` | Warning/900 `#332900` | Warning/100 `#FFF5CC` |
| `info` | Info/500 `#4A6EA5` | Info/300 `#95ADD0` |
| `onInfo` | Neutral/100 `#FFFFFF` | Info/900 `#101823` |
| `infoContainer` | Info/100 `#DCE4EF` | Info/800 `#202F46` |
| `onInfoContainer` | Info/900 `#101823` | Info/100 `#DCE4EF` |
| `shimmerBase` | Neutral/200 `#E6E6E6` | Neutral/700 `#4D4D4D` |
| `shimmerHighlight` | Neutral/100 `#FFFFFF` | Neutral/600 `#666666` |

### Usage in Widgets

```dart
// Via the BuildContext extension
Icon(Icons.check_circle, color: context.appColors.success)
Container(color: context.appColors.warningContainer)
Text('Heads up', style: TextStyle(color: context.appColors.onWarningContainer))
```

### Adding New Tokens

1. Add the property to `AppColors` (field + constructor param).
2. Set values in `AppColors.light` and `AppColors.dark`.
3. Add it to `copyWith()` and `lerp()`.
4. Use via `context.appColors.newToken` in widgets.

---

## 4. Component Themes — `AppComponentThemes`

Component-level overrides live in `app_component_themes.dart`. Every method
accepts a `ColorScheme` so it resolves correctly in both modes.

Currently themed: AppBar, Card, ElevatedButton, OutlinedButton, TextButton,
InputDecoration, BottomNavigationBar, NavigationBar, Divider, Dialog,
BottomSheet, SnackBar, Chip.

```dart
// Example: adding a new component theme
static FloatingActionButtonThemeData fab(ColorScheme cs) {
  return FloatingActionButtonThemeData(
    backgroundColor: cs.primaryContainer,
    foregroundColor: cs.onPrimaryContainer,
  );
}
```

Then register it in `AppTheme._buildTheme()`:

```dart
floatingActionButtonTheme: AppComponentThemes.fab(cs),
```

**Rule**: Every component theme MUST accept `ColorScheme` — never hardcode
colors.

---

## 5. Theme Mode Provider — `ThemeModeNotifier`

Manages the user's preference and persists it with `SharedPreferences`:

```dart
// lib/core/providers/theme_mode_provider.dart
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _loadFromPrefs();
    return ThemeMode.system; // default until prefs load
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}
```

Generated provider name: **`themeModeProvider`**.

### Wiring to MaterialApp

```dart
// lib/app.dart
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // ...
    );
  }
}
```

### Theme Selection UI (Settings Screen)

```dart
class ThemeModeTile extends ConsumerWidget {
  const ThemeModeTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.auto_mode)),
        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode)),
        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode)),
      ],
      selected: {themeMode},
      onSelectionChanged: (selection) {
        ref
            .read(themeModeProvider.notifier)
            .setThemeMode(selection.first);
      },
    );
  }
}
```

---

## 6. How to Use in Widgets

### Accessing ColorScheme

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Cache lookups once per build
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final textTheme = theme.textTheme;

  return Container(
    color: cs.surface,
    child: Column(
      children: [
        Text('Title', style: textTheme.titleLarge),
        Icon(Icons.check, color: cs.primary),
        Divider(color: cs.outlineVariant),
      ],
    ),
  );
}
```

### Accessing Custom Tokens

```dart
// Via extension (preferred)
Container(color: context.appColors.successContainer)

// Or manually
Theme.of(context).extension<AppColors>()!.warning
```

### Surface Hierarchy for Elevation

Replace opacity overlays with the M3 surface container scale:

```dart
// Lowest emphasis → highest emphasis
cs.surfaceContainerLowest  // subtle backgrounds
cs.surfaceContainerLow     // cards, list tiles
cs.surfaceContainer        // default containers
cs.surfaceContainerHigh    // raised elements
cs.surfaceContainerHighest // highest emphasis (input fills, chips)
```

### Disabled States

```dart
// Content
color: cs.onSurface.withValues(alpha: 0.38)

// Container
color: cs.onSurface.withValues(alpha: 0.12)
```

---

## 7. Testing Both Modes

Every widget test must verify rendering in **both** light and dark themes:

```dart
void main() {
  Future<void> pumpWithTheme(
    WidgetTester tester, {
    required ThemeData theme,
    required Widget child,
  }) async {
    await tester.pumpWidget(
      MaterialApp(theme: theme, home: Scaffold(body: child)),
    );
  }

  group('StatusBadge', () {
    testWidgets('uses success color in light mode', (tester) async {
      await pumpWithTheme(
        tester,
        theme: AppTheme.lightTheme,
        child: const StatusBadge(status: Status.active),
      );
      // assert color matches AppColors.light.success
    });

    testWidgets('uses success color in dark mode', (tester) async {
      await pumpWithTheme(
        tester,
        theme: AppTheme.darkTheme,
        child: const StatusBadge(status: Status.active),
      );
      // assert color matches AppColors.dark.success
    });
  });
}
```

---

## 8. Performance

1. **Create ThemeData once** — `AppTheme.lightTheme` and `AppTheme.darkTheme`
   are `static final`. Never call `ThemeData(...)` inside a `build()` method.
2. **Cache `Theme.of(context)`** — Store it in a local variable at the top of
   `build()` rather than calling it multiple times.
3. **Use `const` constructors** — Lets Flutter skip rebuilds for unchanged
   subtrees during theme transitions.
4. **Do not call `Theme.of(context)` inside animation builders** — Extract
   theme values before the animation loop to avoid registering rebuild
   dependencies on every frame.
5. **Use `MediaQuery.sizeOf(context)`** — Not `MediaQuery.of(context).size`.
   The former only triggers rebuilds when size changes, not on every
   `MediaQuery` property change.

---

## 9. Common Pitfalls

### Hardcoded Colors

```dart
// BAD — breaks in dark mode
Container(color: Colors.white)
Text('Hello', style: TextStyle(color: Colors.black))
Divider(color: Color(0xFFE0E0E0))

// GOOD — resolves per theme
Container(color: cs.surface)
Text('Hello', style: TextStyle(color: cs.onSurface))
Divider(color: cs.outlineVariant)
```

### Importing AppPalette in Widgets

```dart
// BAD — palette is for theme setup only
Container(color: AppPalette.primary600)

// GOOD — go through the theme
Container(color: cs.primary)
```

### Opacity Instead of Semantic Surfaces

```dart
// BAD — invisible tint on dark backgrounds
Container(color: Colors.black.withOpacity(0.05))

// GOOD — tone-based surface containers
Container(color: cs.surfaceContainerLow)
```

### Using Deprecated APIs

```dart
// BAD
colorScheme.background     // deprecated
Colors.white.withOpacity() // deprecated
MaterialStateProperty      // deprecated

// GOOD
colorScheme.surface
Colors.white.withValues(alpha: 0.5)
WidgetStateProperty
```

### Creating ThemeData in build()

```dart
// BAD — new instance every build
Widget build(BuildContext context, WidgetRef ref) {
  return MaterialApp(
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: ...)),
  );
}

// GOOD — static final, created once
return MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
);
```

---

## Quick Reference

| Need | Where to look |
|------|---------------|
| Primary, secondary, error | `colorScheme.primary`, `.secondary`, `.error` |
| Text on colored surface | `colorScheme.onPrimary`, `.onSecondary`, `.onError` |
| Page/screen background | `colorScheme.surface` |
| Body text | `colorScheme.onSurface` |
| Card / list tile fill | `colorScheme.surfaceContainerLow` |
| Input field fill | `colorScheme.surfaceContainerHighest` |
| Subtle divider / border | `colorScheme.outlineVariant` |
| Prominent border | `colorScheme.outline` |
| Success / warning / info | `context.appColors.success` etc. |
| Success container | `context.appColors.successContainer` etc. |
| Shimmer placeholder | `context.appColors.shimmerBase` / `.shimmerHighlight` |
| Typography | `Theme.of(context).textTheme.bodyLarge` etc. |
| Disabled text | `colorScheme.onSurface.withValues(alpha: 0.38)` |
| Palette constants (theme only) | `AppPalette.primary600` etc. |

## Rules

- **DO** use `ColorScheme.fromSeed()` with brand overrides for the base palette.
- **DO** use `ThemeExtension<AppColors>` for semantic tokens outside M3.
- **DO** define component themes via `AppComponentThemes` accepting `ColorScheme`.
- **DO** use `context.appColors` extension for custom tokens in widgets.
- **DO** cache `Theme.of(context)` in a local variable per `build()`.
- **DO** create `ThemeData` as `static final` — never inside `build()`.
- **DO** test every widget in both light and dark mode.
- **DO** use M3 surface container hierarchy instead of opacity overlays.
- **DO NOT** import `AppPalette` in widget code — it is for theme setup only.
- **DO NOT** use `Colors.white`, `Colors.black`, `Colors.grey`, or any
  hardcoded hex color in widget code.
- **DO NOT** use deprecated roles (`background`, `surfaceVariant`).
- **DO NOT** use `MaterialStateProperty` — use `WidgetStateProperty`.
- **DO NOT** add theming packages without constitution approval.
- **DO NOT** use `.withOpacity()` — use `.withValues(alpha: ...)`.
