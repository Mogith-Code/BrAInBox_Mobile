import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/moderation_controller.dart';

/// Moderation screen - Reported posts and groups: hide, warn, lock.
///
/// Route: `/moderation`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moderationControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ErrorBanner(
          message: '$error',
          onRetry: () => ref.invalidate(moderationControllerProvider),
        ),
      ),
      data: (summary) => FeaturePlaceholder(
        title: 'Moderation',
        owner: 'Mogith',
        description:
            'Reported posts and groups: hide, warn, lock.\n${summary.message}',
      ),
    );
  }
}
