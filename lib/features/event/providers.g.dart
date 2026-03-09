// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$eventRepositoryHash() => r'3197367ee8ad96934b762a28d62f6bed53c997eb';

/// The single source of event data for the entire app.
///
/// • keepAlive: true → survives navigation, preserves in-memory cache.
/// • Exposed as the abstract [EventRepository] type — the Controller never
///   touches [MockEventRepository] directly.
///
/// To swap to the real implementation in M3, change only the body of this
/// provider. Every provider that watches it updates automatically.
///
/// Copied from [eventRepository].
@ProviderFor(eventRepository)
final eventRepositoryProvider = Provider<EventRepository>.internal(
  eventRepository,
  name: r'eventRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$eventRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EventRepositoryRef = ProviderRef<EventRepository>;
String _$upcomingEventsHash() => r'31dce7048dbc2a640ce8f79a0aad22096efb87fc';

/// Returns only future events from the already-loaded list.
///
/// This is a "derived provider": it watches [eventListControllerProvider] and
/// transforms its value reactively. No API call is made here — the data is
/// already in memory.
///
/// Used by the "Upcoming" section on the home screen.
///
/// Copied from [upcomingEvents].
@ProviderFor(upcomingEvents)
final upcomingEventsProvider = AutoDisposeProvider<List<Event>>.internal(
  upcomingEvents,
  name: r'upcomingEventsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$upcomingEventsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UpcomingEventsRef = AutoDisposeProviderRef<List<Event>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
