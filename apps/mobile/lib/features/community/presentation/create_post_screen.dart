import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Create post screen - Write a new post.
///
/// Route: `/community/create`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create post')),
      body: FeaturePlaceholder(
        title: 'Create post',
        owner: 'Mogith',
        description: 'Write a new post.',
        actionLabel: 'Back',
        onAction: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.home),
      ),
    );
  }
}
