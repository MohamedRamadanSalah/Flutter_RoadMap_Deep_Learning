import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:testing_state_managment_riverpod/core/network/dio_provider.dart';
import 'package:testing_state_managment_riverpod/features/posts/data/repositories/post_repository_impl.dart';
import 'package:testing_state_managment_riverpod/features/posts/domain/entities/post.dart';
import 'package:testing_state_managment_riverpod/features/posts/domain/repositories/post_repository.dart';

part 'post_controller.g.dart';

// Rename to avoid conflict
@Riverpod(keepAlive: true)
PostRepository postRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return PostRepositoryImpl(dio);
}

@riverpod 
class PostListController extends _$PostListController {
  @override
  Future<List<Posts>> build() async {  // Changed from Posts to Post
    final postRepository = ref.watch(postRepositoryProvider);
    return postRepository.getPosts();
  }
  
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
class PostDetailController extends _$PostDetailController {
  @override
  Future<Posts> build(int postId) async {   
    final postRepository = ref.watch(postRepositoryProvider);
    return postRepository.getPostById(postId);
  }
}
