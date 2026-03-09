import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:testing_state_managment_riverpod/features/event/data/models/event.dart';
import 'package:testing_state_managment_riverpod/features/event/providers.dart';

part 'event_detail_controller.g.dart';

/// Controls the Event Detail screen state.
///
/// FAMILY PROVIDER: the [eventId] parameter makes this a "family" — Riverpod
/// creates one independent instance per unique [eventId].
///
///   eventDetailControllerProvider('event-1')  → own AsyncValue for Event
///   eventDetailControllerProvider('event-7')  → completely separate instance
///
/// Each instance is auto-disposed when its screen leaves the navigation stack.
/// Navigating back and re-entering the same event creates a fresh fetch —
/// add @Riverpod(keepAlive: true) if you want cross-navigation caching.
@riverpod
class EventDetailController extends _$EventDetailController {
  @override
  Future<Event> build(String eventId) async {
    // ref.watch() ensures that if eventRepositoryProvider is overridden
    // (e.g., in tests), this controller automatically uses the mock.
    return ref.watch(eventRepositoryProvider).getEventById(eventId);
  }

  /// Manual retry after an error state.
  ///
  /// Equivalent to invalidating from outside, but encapsulated here so
  /// the View doesn't need to know about invalidation mechanics.
  Future<void> retry() async {
    ref.invalidateSelf();
    await future;
  }
}
