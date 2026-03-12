import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_state_managment_riverpod/features/posts/application/post_controller.dart';
import 'package:testing_state_managment_riverpod/features/posts/domain/entities/post.dart';

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postDetailControllerProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Post #$postId'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(postDetailControllerProvider(postId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (post) => _PostDetailContent(post: post),
      ),
    );
  }
}

class _PostDetailContent extends StatelessWidget {
  const _PostDetailContent({required this.post});

  final Posts post;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User ID badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'User #${post.userId}',
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            post.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Divider
          const Divider(),
          const SizedBox(height: 16),

          // Body
          Text(post.body, style: const TextStyle(fontSize: 16, height: 1.6)),
        ],
      ),
    );
  }
}
