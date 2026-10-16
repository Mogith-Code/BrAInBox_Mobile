import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/evaluation_controller.dart';

/// Typed answer screen - Type a structured / essay answer.
///
/// Route: `/evaluation/typed/:questionId`
///
// TODO(keshomigha): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class TypedAnswerScreen extends ConsumerWidget {
  const TypedAnswerScreen({super.key, required this.questionId});

  final String questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(evaluationControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Typed answer')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(evaluationControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Typed answer',
          owner: 'Keshomigha',
          description:
              'Type a structured / essay answer. (questionId: $questionId)\n${summary.message}',
          actionLabel: 'Upload handwritten instead',
          onAction: () => context.push(AppRoutes.handwrittenUploadPath('demo')),
        ),
      ),
    );
  }
}
