import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testing_state_managment_riverpod/features/posts/application/post_controller.dart';
import 'package:testing_state_managment_riverpod/features/posts/domain/entities/post.dart';
import 'package:testing_state_managment_riverpod/features/posts/presentation/screens/post_detail_screen.dart';
import 'package:testing_state_managment_riverpod/features/posts/presentation/widgets/post_list_tile.dart';

class PostListScreen extends ConsumerWidget {
  const PostListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the posts list
    final postsAsync = ref.watch(postListControllerProvider);

    // Listen for errors and show snackbar
    ref.listen<AsyncValue<List<Posts>>>(postListControllerProvider, (
      previous,
      next,
    ) {
      if (next is AsyncError && previous is! AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.error}'),
            backgroundColor: Colors.red.shade700,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => ref.invalidate(postListControllerProvider),
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(postListControllerProvider.notifier).refresh(),
          ),
        ],
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(
          error: error,
          onRetry: () => ref.invalidate(postListControllerProvider),
        ),
        data: (posts) => _PostListBody(posts: posts),
      ),
    );
  }
}

class _PostListBody extends ConsumerWidget {
  const _PostListBody({required this.posts});

  final List<Posts> posts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(postListControllerProvider.notifier).refresh(),
      child: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return PostListTile(
            post: post,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(postId: post.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
