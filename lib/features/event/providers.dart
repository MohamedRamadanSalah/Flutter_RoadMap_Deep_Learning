import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:testing_state_managment_riverpod/features/event/data/models/event.dart';
import 'package:testing_state_managment_riverpod/features/event/data/repositories/mock_event_repository.dart';
import 'package:testing_state_managment_riverpod/features/event/domain/repositories/event_repository.dart';
import 'package:testing_state_managment_riverpod/features/event/presentation/controllers/event_list_controller.dart';

part 'providers.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

/// The single source of event data for the entire app.
///
/// • keepAlive: true → survives navigation, preserves in-memory cache.
/// • Exposed as the abstract [EventRepository] type — the Controller never
///   touches [MockEventRepository] directly.
///
/// To swap to the real implementation in M3, change only the body of this
/// provider. Every provider that watches it updates automatically.
@Riverpod(keepAlive: true)
EventRepository eventRepository(Ref ref) {
  return MockEventRepository();
}

// ---------------------------------------------------------------------------
// Derived providers (computed / filtered views — zero extra network calls)
// ---------------------------------------------------------------------------

/// Returns only future events from the already-loaded list.
///
/// This is a "derived provider": it watches [eventListControllerProvider] and
/// transforms its value reactively. No API call is made here — the data is
/// already in memory.
///
/// Used by the "Upcoming" section on the home screen.
@riverpod
List<Event> upcomingEvents(Ref ref) {
  final allEvents =
      ref.watch(eventListControllerProvider).valueOrNull ?? const [];
  return allEvents.where((e) => e.startDate.isAfter(DateTime.now())).toList();
}
