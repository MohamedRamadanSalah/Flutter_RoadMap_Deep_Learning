import 'package:dio/dio.dart';
import '../dto/post_dto.dart';

class PostRepository {

  final Dio dio;

  PostRepository(this.dio);

  Future<List<PostDto>> getPosts() async {

    final response = await dio.get("/posts");

    final List data = response.data;

    return data
        .map((json) => PostDto.fromJson(json))
        .toList();

  }
  

}