import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/posts/application/post_controller.dart';

void main() async {
  final container = ProviderContainer();

  final postsAsync = await container.read(postControllerProvider.future);

  for (final post in postsAsync) {
    print("ID: ${post.id}");
    print("Title: ${post.title}");
    print("Body: ${post.body}");
    print("--------------------");
  }
}
