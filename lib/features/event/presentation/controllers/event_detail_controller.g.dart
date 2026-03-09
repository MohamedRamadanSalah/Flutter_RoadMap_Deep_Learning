// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$eventDetailControllerHash() =>
    r'40e5840163ffcb7f949635839ca20b7ec93873d7';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$EventDetailController
    extends BuildlessAutoDisposeAsyncNotifier<Event> {
  late final String eventId;

  FutureOr<Event> build(String eventId);
}

/// Controls the Event Detail screen state.
///
/// FAMILY PROVIDER: the [eventId] parameter makes this a "family" — Riverpod
/// creates one independent instance per unique [eventId].
///
///   eventDetailControllerProvider('event-1')  → own AsyncValue<Event>
///   eventDetailControllerProvider('event-7')  → completely separate instance
///
/// Each instance is auto-disposed when its screen leaves the navigation stack.
/// Navigating back and re-entering the same event creates a fresh fetch —
/// add @Riverpod(keepAlive: true) if you want cross-navigation caching.
///
/// Copied from [EventDetailController].
@ProviderFor(EventDetailController)
const eventDetailControllerProvider = EventDetailControllerFamily();

/// Controls the Event Detail screen state.
///
/// FAMILY PROVIDER: the [eventId] parameter makes this a "family" — Riverpod
/// creates one independent instance per unique [eventId].
///
///   eventDetailControllerProvider('event-1')  → own AsyncValue<Event>
///   eventDetailControllerProvider('event-7')  → completely separate instance
///
/// Each instance is auto-disposed when its screen leaves the navigation stack.
/// Navigating back and re-entering the same event creates a fresh fetch —
/// add @Riverpod(keepAlive: true) if you want cross-navigation caching.
///
/// Copied from [EventDetailController].
class EventDetailControllerFamily extends Family<AsyncValue<Event>> {
  /// Controls the Event Detail screen state.
  ///
  /// FAMILY PROVIDER: the [eventId] parameter makes this a "family" — Riverpod
  /// creates one independent instance per unique [eventId].
  ///
  ///   eventDetailControllerProvider('event-1')  → own AsyncValue<Event>
  ///   eventDetailControllerProvider('event-7')  → completely separate instance
  ///
  /// Each instance is auto-disposed when its screen leaves the navigation stack.
  /// Navigating back and re-entering the same event creates a fresh fetch —
  /// add @Riverpod(keepAlive: true) if you want cross-navigation caching.
  ///
  /// Copied from [EventDetailController].
  const EventDetailControllerFamily();

  /// Controls the Event Detail screen state.
  ///
  /// FAMILY PROVIDER: the [eventId] parameter makes this a "family" — Riverpod
  /// creates one independent instance per unique [eventId].
  ///
  ///   eventDetailControllerProvider('event-1')  → own AsyncValue<Event>
  ///   eventDetailControllerProvider('event-7')  → completely separate instance
  ///
  /// Each instance is auto-disposed when its screen leaves the navigation stack.
  /// Navigating back and re-entering the same event creates a fresh fetch —
  /// add @Riverpod(keepAlive: true) if you want cross-navigation caching.
  ///
  /// Copied from [EventDetailController].
  EventDetailControllerProvider call(String eventId) {
    return EventDetailControllerProvider(eventId);
  }

  @override
  EventDetailControllerProvider getProviderOverride(
    covariant EventDetailControllerProvider provider,
  ) {
    return call(provider.eventId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'eventDetailControllerProvider';
}

/// Controls the Event Detail screen state.
///
/// FAMILY PROVIDER: the [eventId] parameter makes this a "family" — Riverpod
/// creates one independent instance per unique [eventId].
///
///   eventDetailControllerProvider('event-1')  → own AsyncValue<Event>
///   eventDetailControllerProvider('event-7')  → completely separate instance
///
/// Each instance is auto-disposed when its screen leaves the navigation stack.
/// Navigating back and re-entering the same event creates a fresh fetch —
/// add @Riverpod(keepAlive: true) if you want cross-navigation caching.
///
/// Copied from [EventDetailController].
class EventDetailControllerProvider
    extends AutoDisposeAsyncNotifierProviderImpl<EventDetailController, Event> {
  /// Controls the Event Detail screen state.
  ///
  /// FAMILY PROVIDER: the [eventId] parameter makes this a "family" — Riverpod
  /// creates one independent instance per unique [eventId].
  ///
  ///   eventDetailControllerProvider('event-1')  → own AsyncValue<Event>
  ///   eventDetailControllerProvider('event-7')  → completely separate instance
  ///
  /// Each instance is auto-disposed when its screen leaves the navigation stack.
  /// Navigating back and re-entering the same event creates a fresh fetch —
  /// add @Riverpod(keepAlive: true) if you want cross-navigation caching.
  ///
  /// Copied from [EventDetailController].
  EventDetailControllerProvider(String eventId)
    : this._internal(
        () => EventDetailController()..eventId = eventId,
        from: eventDetailControllerProvider,
        name: r'eventDetailControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$eventDetailControllerHash,
        dependencies: EventDetailControllerFamily._dependencies,
        allTransitiveDependencies:
            EventDetailControllerFamily._allTransitiveDependencies,
        eventId: eventId,
      );

  EventDetailControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.eventId,
  }) : super.internal();

  final String eventId;

  @override
  FutureOr<Event> runNotifierBuild(covariant EventDetailController notifier) {
    return notifier.build(eventId);
  }

  @override
  Override overrideWith(EventDetailController Function() create) {
    return ProviderOverride(
      origin: this,
      override: EventDetailControllerProvider._internal(
        () => create()..eventId = eventId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        eventId: eventId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<EventDetailController, Event>
  createElement() {
    return _EventDetailControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EventDetailControllerProvider && other.eventId == eventId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, eventId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EventDetailControllerRef on AutoDisposeAsyncNotifierProviderRef<Event> {
  /// The parameter `eventId` of this provider.
  String get eventId;
}

class _EventDetailControllerProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<EventDetailController, Event>
    with EventDetailControllerRef {
  _EventDetailControllerProviderElement(super.provider);

  @override
  String get eventId => (origin as EventDetailControllerProvider).eventId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
