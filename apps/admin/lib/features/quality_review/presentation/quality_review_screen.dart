import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/quality_review_controller.dart';

/// Quality review screen - AI question checks waiting for a human decision.
///
/// Route: `/quality-review`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class QualityReviewScreen extends ConsumerWidget {
  const QualityReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qualityReviewControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ErrorBanner(
          message: '$error',
          onRetry: () => ref.invalidate(qualityReviewControllerProvider),
        ),
      ),
      data: (summary) => FeaturePlaceholder(
        title: 'Quality review',
        owner: 'Udith',
        description:
            'AI question checks waiting for a human decision.\n${summary.message}',
      ),
    );
  }
}
