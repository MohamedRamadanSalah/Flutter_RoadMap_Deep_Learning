# Responsive Sizing

## Overview

A hybrid approach: **fixed typography** on the Material 3 type scale,
**elastic spacing** that scales proportionally with screen width, and
**breakpoint-driven layout** adaptation. No third-party sizing packages.

## Design Principles

1. **Text stays fixed** — M3 `TextTheme` sizes are optimised for readability
   at each role. Scaling text proportionally breaks this and harms accessibility.
2. **Spacing scales elastically** — Margins, paddings, gaps, and icon sizes
   adapt to screen width so layouts feel proportional on a 4" phone and a 12"
   tablet.
3. **Layout adapts at breakpoints** — Column counts, navigation patterns, and
   content width change at defined width thresholds.
4. **No flutter_screenutil** — Stale maintenance, global state, conflicts with
   accessibility font scaling, adds complexity for little benefit.

## Architecture

```
lib/core/
├── theme/
│   ├── app_theme.dart          # M3 ThemeData (already exists)
│   ├── app_spacing.dart        # Elastic spacing scale
│   └── app_breakpoints.dart    # Breakpoint constants + helpers
```

---

## 1. Typography — Fixed M3 Type Scale

Use `Theme.of(context).textTheme` roles. Never hardcode font sizes.

```dart
// GOOD — uses the M3 type scale
Text(
  t.orders.title,
  style: Theme.of(context).textTheme.headlineMedium,
)

// BAD — hardcoded size
Text(t.orders.title, style: TextStyle(fontSize: 24))
```

### When to Customize

Override weight or colour, never size:

```dart
Text(
  t.orders.price,
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w700,
    color: Theme.of(context).colorScheme.primary,
  ),
)
```

---

## 2. Elastic Spacing — `AppSpacing`

A utility that provides a spacing scale relative to screen width. The
reference design width is **375 logical pixels** (iPhone SE / standard
mobile design frame). On wider screens spacing grows proportionally; on
narrower screens it shrinks.

### Implementation

```dart
// lib/core/theme/app_spacing.dart
import 'dart:math';
import 'package:flutter/widgets.dart';

/// Elastic spacing that scales proportionally with screen width.
///
/// Reference width: 375 lp (standard mobile design frame).
/// On a 375-wide screen the scale factor is 1.0.
/// On a 768-wide tablet the scale factor is ~1.25 (clamped).
///
/// Usage:
///   final sp = AppSpacing.of(context);
///   Padding(padding: EdgeInsets.all(sp.md))
class AppSpacing {
  AppSpacing._(this._factor);

  /// Create from the current [BuildContext].
  factory AppSpacing.of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Scale relative to 375, clamped to avoid extreme values.
    final factor = (width / 375).clamp(0.85, 1.35);
    return AppSpacing._(factor);
  }

  final double _factor;

  // ── Base scale (multiples of 4) ──────────────────────────
  /// 4 lp on reference screen
  double get xs => 4 * _factor;

  /// 8 lp on reference screen
  double get sm => 8 * _factor;

  /// 12 lp on reference screen
  double get md => 12 * _factor;

  /// 16 lp on reference screen
  double get lg => 16 * _factor;

  /// 24 lp on reference screen
  double get xl => 24 * _factor;

  /// 32 lp on reference screen
  double get xxl => 32 * _factor;

  /// 48 lp on reference screen
  double get xxxl => 48 * _factor;

  // ── Screen-level padding ─────────────────────────────────
  /// Horizontal page margin (16 on phones, scales up on tablets).
  double get pagePaddingH => lg;

  /// Vertical page margin.
  double get pagePaddingV => lg;

  /// Standard padding for page content.
  EdgeInsets get pageInsets =>
      EdgeInsets.symmetric(horizontal: pagePaddingH, vertical: pagePaddingV);

  // ── Common patterns ──────────────────────────────────────
  /// Standard gap between list items.
  double get listItemGap => sm;

  /// Gap between sections.
  double get sectionGap => xl;

  /// Card inner padding.
  EdgeInsets get cardInsets => EdgeInsets.all(lg);

  // ── Arbitrary scaling ────────────────────────────────────
  /// Scale any base value by the current factor.
  double scale(double base) => base * _factor;
}
```

### Usage

```dart
class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sp = AppSpacing.of(context);

    return Padding(
      padding: sp.pageInsets,
      child: Column(
        children: [
          // Section header
          Text(
            t.orders.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: sp.sectionGap),

          // List with elastic gaps
          Expanded(
            child: ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) => SizedBox(height: sp.listItemGap),
              itemBuilder: (_, i) => OrderCard(order: orders[i]),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Scaling Other Dimensions

Icons, avatars, and other visual elements can scale too:

```dart
final sp = AppSpacing.of(context);

// Elastic icon size (24 on reference, ~30 on tablet)
Icon(Icons.star, size: sp.scale(24));

// Elastic avatar radius
CircleAvatar(radius: sp.scale(20));

// Elastic border radius
BorderRadius.circular(sp.scale(12));
```

---

## 3. Breakpoints — `AppBreakpoints`

Layout structure changes at width thresholds, not via proportional scaling.

### Implementation

```dart
// lib/core/theme/app_breakpoints.dart
import 'package:flutter/widgets.dart';

abstract final class AppBreakpoints {
  /// Compact phones (< 600 dp).
  static const double compact = 0;

  /// Medium — large phones & small tablets (600–839 dp).
  static const double medium = 600;

  /// Expanded — tablets & desktop (≥ 840 dp).
  static const double expanded = 840;

  /// True if current width is at least [medium].
  static bool isMedium(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= medium;

  /// True if current width is at least [expanded].
  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;
}
```

### Usage with LayoutBuilder

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth >= AppBreakpoints.expanded) {
      return const WideOrderLayout();   // side-by-side list + detail
    }
    return const NarrowOrderLayout();   // stacked list → detail
  },
)
```

### Grid Columns by Breakpoint

```dart
int _crossAxisCount(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= AppBreakpoints.expanded) return 3;
  if (width >= AppBreakpoints.medium) return 2;
  return 1;
}
```

---

## 4. Safe Area

Always wrap top-level screens with `SafeArea` to handle notches, Dynamic
Island, and system bars:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  return Scaffold(
    body: SafeArea(
      child: Padding(
        padding: AppSpacing.of(context).pageInsets,
        child: ...,
      ),
    ),
  );
}
```

---

## Quick Reference

| What | How | Scales? |
|---|---|---|
| Text sizes | `Theme.of(context).textTheme.bodyLarge` | No (fixed M3 scale) |
| Margins, paddings | `AppSpacing.of(context).lg` | Yes (elastic) |
| List gaps | `AppSpacing.of(context).listItemGap` | Yes (elastic) |
| Section gaps | `AppSpacing.of(context).sectionGap` | Yes (elastic) |
| Page insets | `AppSpacing.of(context).pageInsets` | Yes (elastic) |
| Icon sizes | `AppSpacing.of(context).scale(24)` | Yes (elastic) |
| Border radii | `AppSpacing.of(context).scale(12)` | Yes (elastic) |
| Column count | `AppBreakpoints.isMedium(context)` | Breakpoint switch |
| Navigation pattern | `LayoutBuilder` + `AppBreakpoints` | Breakpoint switch |
| Notch/island | `SafeArea` | System-handled |

## Rules

- **DO** use `AppSpacing.of(context)` for all margins, paddings, and gaps.
- **DO** use M3 `TextTheme` roles for all text — never hardcode font sizes.
- **DO** use `AppBreakpoints` for layout structure changes.
- **DO** wrap screen bodies with `SafeArea`.
- **DO** use `sp.scale(base)` for icons, avatars, and border radii.
- **DO NOT** use `flutter_screenutil` or any third-party sizing package.
- **DO NOT** scale font sizes proportionally to screen width.
- **DO NOT** use magic numbers — always use `AppSpacing` named values or `sp.scale()`.
- **DO NOT** use `MediaQuery.of(context).size` — prefer `MediaQuery.sizeOf(context)` (avoids unnecessary rebuilds).
