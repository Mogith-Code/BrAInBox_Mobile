import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/content_review_controller.dart';

/// Content review screen - Queue of AI content waiting for review.
///
/// Route: `/content-review`
///
// TODO(samni): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class ContentReviewScreen extends ConsumerWidget {
  const ContentReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(contentReviewControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ErrorBanner(
          message: '$error',
          onRetry: () => ref.invalidate(contentReviewControllerProvider),
        ),
      ),
      data: (summary) => FeaturePlaceholder(
        title: 'Content review',
        owner: 'Samni',
        description:
            'Queue of AI content waiting for review.\n${summary.message}',
      ),
    );
  }
}
