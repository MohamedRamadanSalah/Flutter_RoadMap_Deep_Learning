# Performance

## Overview

Constitution mandates: 16ms frame budget (60fps), <3s cold start on
mid-range Android, release APK under 30MB, resident memory under 200MB,
99.5% crash-free rate. Performance is a feature, not an afterthought.

## Performance Budgets

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Frame time | < 16ms (60fps) | Flutter DevTools → Performance overlay |
| Cold start | < 3s on Snapdragon 600-series | `adb shell am start -W` |
| APK size | < 30 MB (release) | `flutter build apk --release --analyze-size` |
| Memory | < 200 MB resident | Flutter DevTools → Memory tab |
| Crash-free rate | 99.5% (7-day rolling) | Firebase Crashlytics dashboard |

## Widget Rebuild Optimization

### Use `const` Constructors

```dart
// GOOD — no rebuild when parent rebuilds
const SizedBox(height: 16)
const Icon(Icons.star)
const Text('Static text')

// BAD — creates new instance every build
SizedBox(height: 16)  // missing const
```

### Selective State Watching

Watch only what you need — use `select` to avoid unnecessary rebuilds:

```dart
// GOOD — only rebuilds when order count changes
final count = ref.watch(
  orderListControllerProvider.select((state) => state.valueOrNull?.length),
);

// BAD — rebuilds on ANY change to the order list
final orders = ref.watch(orderListControllerProvider);
```

### Split Widgets

Break large widgets into smaller `const`-constructable children:

```dart
// GOOD — only OrderTotal rebuilds when total changes
class OrderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OrderHeader(),    // const — never rebuilds
        const OrderItems(),     // const — never rebuilds
        const OrderTotal(),     // ConsumerWidget — watches total
      ],
    );
  }
}
```

### RepaintBoundary

Use when a subtree repaints frequently but its ancestors don't:

```dart
RepaintBoundary(
  child: AnimatedProgressBar(progress: progress),
)
```

Only add `RepaintBoundary` when profiling shows it helps — it has memory cost.

## Image Performance

### Remote Images

Always use `cached_network_image`:

```dart
// GOOD — disk-cached, placeholder while loading
CachedNetworkImage(
  imageUrl: order.imageUrl,
  width: 80,
  height: 80,
  fit: BoxFit.cover,
  placeholder: (_, __) => const ShimmerBox(width: 80, height: 80),
  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
)

// BAD — no cache, re-fetches every time
Image.network(order.imageUrl)
```

### Image Sizing

Request appropriately sized images from the API. Never download a 2000px
image to display at 80px:

```dart
// If the API supports size parameters:
CachedNetworkImage(
  imageUrl: '${order.imageUrl}?w=160&h=160', // 2x for retina
  width: 80,
  height: 80,
)
```

### SVG Performance

SVGs are compiled to `.vec` at build time via `vector_graphics_compiler`.
See `docs/svg-icons.md` for details. This eliminates runtime SVG parsing.

## List Performance

### Use `ListView.builder` / `ListView.separated`

```dart
// GOOD — lazily builds visible items only
ListView.builder(
  itemCount: orders.length,
  itemBuilder: (context, i) => OrderCard(order: orders[i]),
)

// BAD — builds ALL items upfront
ListView(
  children: orders.map((o) => OrderCard(order: o)).toList(),
)
```

### Use `itemExtent` When Possible

If all items have the same height, set `itemExtent` for faster scrolling:

```dart
ListView.builder(
  itemExtent: 72, // Each item is exactly 72px
  itemCount: orders.length,
  itemBuilder: (context, i) => OrderTile(order: orders[i]),
)
```

### Avoid Expensive Builds in Items

Keep list item `build()` methods lightweight. Move heavy computation to
the controller.

## Isolates

Heavy computation MUST run in isolates to keep the main thread responsive:

```dart
// GOOD — runs on a separate isolate
final result = await Isolate.run(() {
  return expensiveJsonParsing(rawData);
});

// BAD — blocks the main isolate
final result = expensiveJsonParsing(rawData);
```

Use `Isolate.run` for one-shot tasks. For long-running work, use
`compute()` or spawn a persistent isolate.

### When to Use Isolates

| Task | Isolate needed? |
|------|----------------|
| JSON parsing (< 1KB) | No |
| JSON parsing (> 100KB) | Yes |
| Image processing | Yes |
| Complex filtering/sorting (> 1000 items) | Yes |
| Crypto/hashing | Yes |
| Simple list operations | No |

## App Size

### Analyze Size

```sh
flutter build apk --release --analyze-size
# Opens a size breakdown in DevTools
```

### Reduce Size

- Use `--split-per-abi` for APK (or use AAB for Play Store):
  ```sh
  flutter build apk --release --split-per-abi
  ```
- Remove unused assets and dependencies.
- Use `--obfuscate --split-debug-info=debug-info/` for release builds.
- SVG → `.vec` compilation reduces asset size.

## Profiling

### Flutter DevTools

```sh
flutter run --profile  # Profile mode (not debug)
# DevTools opens automatically
```

Key tabs:
- **Performance**: Frame rendering, jank detection
- **CPU Profiler**: Hot functions, call trees
- **Memory**: Allocations, leak detection
- **Network**: API call timing

### Profile Mode Only

Always profile in `--profile` mode, never `--debug`. Debug mode disables
optimizations and gives misleading performance data.

## Release Build Checklist

- [ ] `flutter build apk --release` succeeds
- [ ] APK size < 30 MB
- [ ] `flutter build ios --release` succeeds
- [ ] No `kDebugMode`-only code leaks into release
- [ ] `--obfuscate` and `--split-debug-info` flags used
- [ ] Tree-shaking enabled (default in release)

## Rules

- **DO** use `const` constructors wherever possible.
- **DO** use `ref.watch(...select(...))` to minimize rebuilds.
- **DO** use `cached_network_image` for all remote images.
- **DO** use `ListView.builder` for dynamic lists.
- **DO** use `Isolate.run` for heavy computation (> 16ms).
- **DO** profile in `--profile` mode, not `--debug`.
- **DO NOT** use `Image.network()` directly.
- **DO NOT** build all list items upfront with `ListView(children: [...])`.
- **DO NOT** add `RepaintBoundary` without profiling evidence.
- **DO NOT** ship debug-mode builds for performance testing.
