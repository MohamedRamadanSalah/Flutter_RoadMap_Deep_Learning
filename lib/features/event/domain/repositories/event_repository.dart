import 'package:testing_state_managment_riverpod/features/event/data/models/event.dart';

/// Abstract contract for the Event data source.
///
/// The Controller depends ONLY on this interface — never on the concrete
/// implementation. This allows:
///   - MockEventRepository during M2 (fake in-memory data)
///   - EventRepositoryImpl during M3 (Retrofit API + Drift cache)
///   - InMemoryEventRepository in unit tests (zero network calls)
abstract class EventRepository {
  /// Fetch a paginated, optionally-filtered list of events.
  ///
  /// [page] is 1-based. [pageSize] defaults to 10.
  /// Returns an empty list when there are no more pages.
  Future<List<Event>> getEvents({
    int page = 1,
    int pageSize = 10,
    String? search,
  });

  /// Fetch a single event by its unique [id].
  ///
  /// Throws if the event does not exist.
  Future<Event> getEventById(String id);
}
