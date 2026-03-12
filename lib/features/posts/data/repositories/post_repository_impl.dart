import 'package:dio/dio.dart';
import 'package:testing_state_managment_riverpod/features/posts/data/dto/post_dto.dart';
import 'package:testing_state_managment_riverpod/features/posts/domain/entities/post.dart';
import 'package:testing_state_managment_riverpod/features/posts/domain/repositories/post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  final Dio dio;
  PostRepositoryImpl(this.dio);

  @override
  Future<Posts> getPostById(int id) async {
    final response = await dio.get('/posts/$id');
    return PostDto.fromJson(response.data).toEntity();
  }

  @override
  Future<List<Posts>> getPosts() async {
    final response = await dio.get('/posts');
    final List data = response.data as List;
    return data.map((json) => PostDto.fromJson(json).toEntity()).toList();
  }
}
