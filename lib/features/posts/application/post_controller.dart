import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dto/post_dto.dart';
import '../data/repository/post_repository.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(baseUrl: "https://jsonplaceholder.typicode.com"));
});

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PostRepository(dio);
});

final postControllerProvider = FutureProvider<List<PostDto>>((ref) async {
  final repository = ref.watch(postRepositoryProvider);
  return repository.getPosts();
});
