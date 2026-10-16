import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/recommendations_controller.dart';

/// Next steps screen - What to do next and recommended resources.
///
/// Route: `/recommendations`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class NextStepsScreen extends ConsumerWidget {
  const NextStepsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendationsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Next steps')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(recommendationsControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Next steps',
          owner: 'Udith',
          description:
              'What to do next and recommended resources.\n${summary.message}',
          actionLabel: 'Open study plan',
          onAction: () => context.push(AppRoutes.studyPlan),
        ),
      ),
    );
  }
}
