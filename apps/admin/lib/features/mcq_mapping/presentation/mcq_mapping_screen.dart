import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/mcq_mapping_controller.dart';

/// MCQ mapping screen - Pick a question, tag a misconception per wrong option.
///
/// Route: `/mcq-mapping`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class McqMappingScreen extends ConsumerWidget {
  const McqMappingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mcqMappingControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ErrorBanner(
          message: '$error',
          onRetry: () => ref.invalidate(mcqMappingControllerProvider),
        ),
      ),
      data: (summary) => FeaturePlaceholder(
        title: 'MCQ mapping',
        owner: 'Udith',
        description:
            'Pick a question, tag a misconception per wrong option.\n${summary.message}',
      ),
    );
  }
}
