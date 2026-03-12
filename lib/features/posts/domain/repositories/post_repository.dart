import 'package:testing_state_managment_riverpod/features/posts/domain/entities/post.dart';

abstract class PostRepository {
  Future<List<Posts>> getPosts();
  Future<Posts> getPostById(int id);
}
