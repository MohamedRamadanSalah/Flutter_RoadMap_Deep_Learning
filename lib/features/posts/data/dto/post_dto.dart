import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:testing_state_managment_riverpod/features/posts/domain/entities/post.dart';
part 'post_dto.freezed.dart';
part 'post_dto.g.dart';
@freezed
class PostDto with _$PostDto {
  const PostDto._();
  const factory PostDto({
    required int userId,
    required int id,
    required String title,
    required String body,
  }) = _PostDto;

  factory PostDto.fromJson(Map<String, dynamic> json) =>
      _$PostDtoFromJson(json);

  Posts toEntity() => Posts(userId: userId, id: id, title: title, body: body);
}
