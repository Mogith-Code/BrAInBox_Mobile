import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Post screen - A post with its comments.
///
/// Route: `/community/posts/:postId`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: FeaturePlaceholder(
        title: 'Post',
        owner: 'Mogith',
        description: 'A post with its comments. (postId: $postId)',
        actionLabel: 'Write a post',
        onAction: () => context.push(AppRoutes.createPost),
      ),
    );
  }
}
