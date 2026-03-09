import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_state_managment_riverpod/features/event/data/models/event.dart';
import 'package:testing_state_managment_riverpod/features/event/presentation/controllers/event_list_controller.dart';
import 'package:testing_state_managment_riverpod/features/event/presentation/screens/event_detail_screen.dart';
import 'package:testing_state_managment_riverpod/features/event/providers.dart';

/// The Event List screen.
///
/// Demonstrates every M2 pattern:
///   1. AsyncValue.when()            → loading / data / error states
///   2. ref.listen()                 → error snackbar (side effect, no rebuild)
///   3. select()                     → AppBar count only rebuilds on count change
///   4. ref.invalidateSelf()         → pull-to-refresh (via controller.refresh())
///   5. upcomingEventsProvider       → derived provider in a sub-widget
class EventListScreen extends ConsumerWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Pattern 3: select() ───────────────────────────────────────────────
    // This widget already watches eventsAsync below, but this demonstrates
    // the pattern: only the AppBar title rebuilds when the count changes.
    // In a larger screen with many sub-widgets, each select() watch means
    // only that sub-widget rebuilds — not the whole tree.
    final eventCount = ref.watch(
      eventListControllerProvider
          .select((s) => s.valueOrNull?.length ?? 0),
    );

    // Full state — used for the body
    final eventsAsync = ref.watch(eventListControllerProvider);

    // ── Pattern 2: ref.listen() ───────────────────────────────────────────
    // ref.listen does NOT cause a rebuild here. It is only a side-effect hook.
    // We show a snackbar when the state transitions into an error.
    // The `prev is! AsyncError` guard prevents showing the snackbar again
    // on every `build()` call while the error state persists.
    ref.listen<AsyncValue<List<Event>>>(
      eventListControllerProvider,
      (prev, next) {
        if (next is AsyncError && prev is! AsyncError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${next.error}'),
              backgroundColor: Colors.red.shade700,
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => ref.invalidate(eventListControllerProvider),
              ),
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Events ($eventCount)'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            // ref.read() in a callback — never ref.watch() here
            onPressed: () =>
                ref.read(eventListControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: eventsAsync.when(
        // skipLoadingOnRefresh: true → keeps showing old data while refreshing
        // instead of flashing the spinner. This is critical for good UX.
        skipLoadingOnRefresh: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(
          error: error,
          onRetry: () => ref.invalidate(eventListControllerProvider),
        ),
        data: (events) => _EventListBody(events: events),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets (separated to limit rebuild scope)
// ─────────────────────────────────────────────────────────────────────────────

class _EventListBody extends ConsumerWidget {
  const _EventListBody({required this.events});

  final List<Event> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(eventListControllerProvider.notifier);
    final hasMore =
        ref.watch(eventListControllerProvider.notifier).hasMore;

    return Column(
      children: [
        // ── Derived provider demo: upcoming events count ──────────────────
        _UpcomingEventsHeader(),

        // ── Main list with pull-to-refresh ────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            // Pattern 4: pull-to-refresh calls refresh() which calls
            // invalidateSelf() + awaits future. The RefreshIndicator spinner
            // closes only after the new data is ready.
            onRefresh: controller.refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: events.length + (hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                // Last item = "Load More" button
                if (index == events.length) {
                  return _LoadMoreButton(onPressed: controller.loadMore);
                }

                final event = events[index];
                return _EventListTile(event: event);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Demonstrates the derived [upcomingEventsProvider] — reads filtered data
/// without making any new API call.
class _UpcomingEventsHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingEventsProvider);

    return Container(
      width: double.infinity,
      color: const Color(0xFFE3F2FD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        '${upcoming.length} upcoming event${upcoming.length == 1 ? '' : 's'}',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }
}

class _EventListTile extends StatelessWidget {
  const _EventListTile({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${event.startDate.day}/${event.startDate.month}/${event.startDate.year}';
    final isPast = event.startDate.isBefore(DateTime.now());

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isPast ? Colors.grey.shade300 : const Color(0xFF2196F3),
        child: Text(
          event.title[0],
          style: TextStyle(
            color: isPast ? Colors.grey.shade600 : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        event.title,
        style: TextStyle(
          color: isPast ? Colors.grey.shade500 : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(event.venue, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        dateStr,
        style: TextStyle(
          fontSize: 12,
          color: isPast ? Colors.grey.shade400 : const Color(0xFF1976D2),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: event.id),
          ),
        );
      },
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      child: OutlinedButton(
        onPressed: onPressed,
        child: const Text('Load More'),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
