import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/practice_controller.dart';

/// Practice screen - Start a quiz, continue, or take the diagnostic.
///
/// Route: `/practice`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(practiceControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Practice',
          owner: 'Udith',
          description:
              'Start a quiz, continue, or take the diagnostic.\n${summary.message}',
          actionLabel: 'Set up a quiz',
          onAction: () => context.push(AppRoutes.quizSetup),
        ),
      ),
    );
  }
}
