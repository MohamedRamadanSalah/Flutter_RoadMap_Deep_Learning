// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$eventListControllerHash() =>
    r'8d30fc876c993c7fc5f37ca2f3925695c0475049';

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
///
/// Copied from [EventListController].
@ProviderFor(EventListController)
final eventListControllerProvider =
    AutoDisposeAsyncNotifierProvider<EventListController, List<Event>>.internal(
      EventListController.new,
      name: r'eventListControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$eventListControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EventListController = AutoDisposeAsyncNotifier<List<Event>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
