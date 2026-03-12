// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postRepositoryHash() => r'5b7f3bc1633b9830159da647cb80a9570964e541';

/// See also [postRepository].
@ProviderFor(postRepository)
final postRepositoryProvider = Provider<PostRepository>.internal(
  postRepository,
  name: r'postRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PostRepositoryRef = ProviderRef<PostRepository>;
String _$postListControllerHash() =>
    r'e82ccd06a8ec2d876c6022124537b52898ffdb19';

/// See also [PostListController].
@ProviderFor(PostListController)
final postListControllerProvider =
    AutoDisposeAsyncNotifierProvider<PostListController, List<Posts>>.internal(
      PostListController.new,
      name: r'postListControllerProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$postListControllerHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PostListController = AutoDisposeAsyncNotifier<List<Posts>>;
String _$postDetailControllerHash() =>
    r'ce5537b7343f2363f27ed09a3489f1dc15a80118';

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

abstract class _$PostDetailController
    extends BuildlessAutoDisposeAsyncNotifier<Posts> {
  late final int postId;

  FutureOr<Posts> build(int postId);
}

/// See also [PostDetailController].
@ProviderFor(PostDetailController)
const postDetailControllerProvider = PostDetailControllerFamily();

/// See also [PostDetailController].
class PostDetailControllerFamily extends Family<AsyncValue<Posts>> {
  /// See also [PostDetailController].
  const PostDetailControllerFamily();

  /// See also [PostDetailController].
  PostDetailControllerProvider call(int postId) {
    return PostDetailControllerProvider(postId);
  }

  @override
  PostDetailControllerProvider getProviderOverride(
    covariant PostDetailControllerProvider provider,
  ) {
    return call(provider.postId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'postDetailControllerProvider';
}

/// See also [PostDetailController].
class PostDetailControllerProvider
    extends AutoDisposeAsyncNotifierProviderImpl<PostDetailController, Posts> {
  /// See also [PostDetailController].
  PostDetailControllerProvider(int postId)
    : this._internal(
        () => PostDetailController()..postId = postId,
        from: postDetailControllerProvider,
        name: r'postDetailControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$postDetailControllerHash,
        dependencies: PostDetailControllerFamily._dependencies,
        allTransitiveDependencies:
            PostDetailControllerFamily._allTransitiveDependencies,
        postId: postId,
      );

  PostDetailControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final int postId;

  @override
  FutureOr<Posts> runNotifierBuild(covariant PostDetailController notifier) {
    return notifier.build(postId);
  }

  @override
  Override overrideWith(PostDetailController Function() create) {
    return ProviderOverride(
      origin: this,
      override: PostDetailControllerProvider._internal(
        () => create()..postId = postId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<PostDetailController, Posts>
  createElement() {
    return _PostDetailControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostDetailControllerProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PostDetailControllerRef on AutoDisposeAsyncNotifierProviderRef<Posts> {
  /// The parameter `postId` of this provider.
  int get postId;
}

class _PostDetailControllerProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<PostDetailController, Posts>
    with PostDetailControllerRef {
  _PostDetailControllerProviderElement(super.provider);

  @override
  int get postId => (origin as PostDetailControllerProvider).postId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
