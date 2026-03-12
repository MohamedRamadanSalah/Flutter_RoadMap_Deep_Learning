import 'package:freezed_annotation/freezed_annotation.dart';
part 'post.freezed.dart';
part 'post.g.dart';
@freezed
class Posts with _$Posts {
  const factory Posts({
    required int userId,
    required int id,
    required String title,
    required String body,
  }) = _Posts;

  factory Posts.fromJson(Map<String, dynamic> json) => _$PostsFromJson(json);
}
