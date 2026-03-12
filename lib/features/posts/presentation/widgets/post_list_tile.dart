import 'package:flutter/material.dart';
import 'package:testing_state_managment_riverpod/features/posts/domain/entities/post.dart';

class PostListTile extends StatelessWidget {
  const PostListTile({super.key, required this.post, required this.onTap});

  final Posts post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          post.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            post.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chevron_right, color: Colors.grey),
            Text(
              'Post #${post.id}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
