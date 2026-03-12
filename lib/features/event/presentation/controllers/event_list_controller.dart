import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:testing_state_managment_riverpod/features/event/data/models/event.dart';
import 'package:testing_state_managment_riverpod/features/event/providers.dart';

part 'event_list_controller.g.dart';

/// Controls the Event List screen state.
///
/// Demonstrates every M2 pattern in one controller:
///   • AsyncNotifier (NOT FutureProvider — we need mutations)
///   • Pagination via loadMore()
///   • Pull-to-refresh via invalidateSelf()
///   • AsyncValue.guard() for safe error capture
///   • ref.watch() in build() vs ref.read() in actions
///
/// Auto-disposed when EventListScreen leaves the tree.
/// State resets cleanly on re-entry (pagination starts over).
@riverpod
class EventListController extends _$EventListController {
  static const _pageSize = 10;

  // Mutable pagination state — lives inside the notifier, not in providers.
  int _currentPage = 1;
  bool _hasMore = true;

  // ──────────────────────────────────────────────────────────────────────────
  // build() — called automatically on first watch and after invalidateSelf()
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<List<Event>> build() async {
    // Reset pagination every time the provider is (re)built.
    _currentPage = 1;
    _hasMore = true;

    // ref.watch() here: if the repository provider is replaced (e.g., in tests),
    // this controller automatically rebuilds with the new repository.
    return ref
        .watch(eventRepositoryProvider)
        .getEvents(page: 1, pageSize: _pageSize);
     }

  // ──────────────────────────────────────────────────────────────────────────
  // Pagination — append next page without losing existing data
  // ──────────────────────────────────────────────────────────────────────────

  /// Loads the next page and appends it to the current list.
  ///
  /// Guards against duplicate calls (already loading or no more pages).
  /// State stays as [AsyncData] with the previous list during the fetch
  /// — no loading flash shown to the user.
  Future<void> loadMore() async {
    if (!_hasMore) return;
    if (state is AsyncLoading) return; // already in a build() call

    _currentPage++;

    // ref.read() here — we're in a callback, not build().
    // We want a one-shot read, not a reactive subscription.
    final more = await AsyncValue.guard(
      () => ref
          .read(eventRepositoryProvider)
          .getEvents(page: _currentPage, pageSize: _pageSize),
    );

    more.when(
      data: (newEvents) {
        if (newEvents.isEmpty) {
          _hasMore = false;
          return;
        }
        // Append without flashing spinner — state stays AsyncData.
        state = AsyncData([...state.requireValue, ...newEvents]);
      },
      loading: () {},
      error: (e, st) {
        // Roll back page counter so the user can retry.
        _currentPage--;
        state = AsyncError(e, st);
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Pull-to-refresh
  // ──────────────────────────────────────────────────────────────────────────

  /// Resets pagination and re-fetches page 1.
  ///
  /// [invalidateSelf()] marks the provider stale so build() reruns.
  /// [await future] waits for the new data before the RefreshIndicator
  /// closes its spinner — this is the correct pattern to avoid premature
  /// dismissal of the loading indicator.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Expose whether more pages are available (for "Load More" button state)
  // ──────────────────────────────────────────────────────────────────────────

  bool get hasMore => _hasMore;
}
