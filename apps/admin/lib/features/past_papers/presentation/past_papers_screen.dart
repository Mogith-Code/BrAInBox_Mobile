import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/past_papers_controller.dart';

/// Past papers screen - Upload papers (PDF) and marking schemes.
///
/// Route: `/past-papers`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class PastPapersScreen extends ConsumerWidget {
  const PastPapersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pastPapersControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ErrorBanner(
          message: '$error',
          onRetry: () => ref.invalidate(pastPapersControllerProvider),
        ),
      ),
      data: (summary) => FeaturePlaceholder(
        title: 'Past papers',
        owner: 'Udith',
        description:
            'Upload papers (PDF) and marking schemes.\n${summary.message}',
      ),
    );
  }
}
