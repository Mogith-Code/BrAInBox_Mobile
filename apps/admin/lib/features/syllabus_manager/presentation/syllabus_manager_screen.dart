import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/syllabus_manager_controller.dart';

/// Syllabus manager screen - Tree editor for units, topics and concepts.
///
/// Route: `/syllabus`
///
// TODO(keshomigha): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class SyllabusManagerScreen extends ConsumerWidget {
  const SyllabusManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syllabusManagerControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ErrorBanner(
          message: '$error',
          onRetry: () => ref.invalidate(syllabusManagerControllerProvider),
        ),
      ),
      data: (summary) => FeaturePlaceholder(
        title: 'Syllabus manager',
        owner: 'Keshomigha',
        description:
            'Tree editor for units, topics and concepts.\n${summary.message}',
      ),
    );
  }
}
