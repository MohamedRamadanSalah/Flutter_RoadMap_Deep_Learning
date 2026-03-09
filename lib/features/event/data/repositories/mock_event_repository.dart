import 'package:testing_state_managment_riverpod/features/event/data/models/event.dart';
import 'package:testing_state_managment_riverpod/features/event/domain/repositories/event_repository.dart';

/// In-memory fake implementation used during M2 (pure state management).
///
/// All network calls in M3 (Retrofit + Dio) will replace this via
/// eventRepositoryProvider override — the Controller and Screen never change.
///
/// Demonstrates the power of the Dependency Inversion principle:
/// swap the implementation → zero UI code changes.
class MockEventRepository implements EventRepository {
  // 30 fake events spread over the next 3 months.
  // Odd-indexed events are in the past to make upcomingEventsProvider meaningful.
  static final List<Event> _mockEvents = List.generate(30, (i) {
    final daysOffset = i.isOdd ? -(i * 2) : (i * 3);
    return Event(
      id: 'event-$i',
      title: _eventTitles[i % _eventTitles.length],
      startDate: DateTime.now().add(Duration(days: daysOffset)),
      endDate: DateTime.now().add(Duration(days: daysOffset + 1)),
      venue: 'Dubai World Trade Centre, Hall ${(i % 5) + 1}',
    );
  });

  static const _eventTitles = [
    'Flutter Forward Summit',
    'AI & Machine Learning Expo',
    'Mobile Dev Conference',
    'UI/UX Design Sprint',
    'Cloud Architecture Workshop',
    'Open Source Hackathon',
    'Blockchain Developers Day',
    'DevOps & CI/CD Masterclass',
    'Startup Pitch Night',
    'Web3 Innovation Forum',
  ];

  @override
  Future<List<Event>> getEvents({
    int page = 1,
    int pageSize = 10,
    String? search,
  }) async {
    // Simulate realistic network latency.
    await Future.delayed(const Duration(milliseconds: 800));

    final all = search != null && search.isNotEmpty
        ? _mockEvents
              .where(
                (e) =>
                    e.title.toLowerCase().contains(search.toLowerCase()) ||
                    e.venue.toLowerCase().contains(search.toLowerCase()),
              )
              .toList()
        : List<Event>.from(_mockEvents);

    final start = (page - 1) * pageSize;
    if (start >= all.length) {
      return []; // No more pages — signals pagination end
    }

    final end = (start + pageSize).clamp(0, all.length);
    return all.sublist(start, end);
  }

  @override
  Future<Event> getEventById(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return _mockEvents.firstWhere(
      (e) => e.id == id,
      orElse: () => throw Exception('Event not found: $id'),
    );
  }
}
