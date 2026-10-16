import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/community_controller.dart';

/// Community screen - Study groups the student can join.
///
/// Route: `/community`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(communityControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Community',
          owner: 'Mogith',
          description: 'Study groups the student can join.\n${summary.message}',
          actionLabel: 'Open a group',
          onAction: () => context.push(AppRoutes.groupFeedPath('demo')),
        ),
      ),
    );
  }
}
