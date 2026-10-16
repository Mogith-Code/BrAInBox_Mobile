import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/knowledge_base_controller.dart';

/// Knowledge base screen - Model answers and keywords per question.
///
/// Route: `/knowledge-base`
///
// TODO(keshomigha): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class KnowledgeBaseScreen extends ConsumerWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(knowledgeBaseControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ErrorBanner(
          message: '$error',
          onRetry: () => ref.invalidate(knowledgeBaseControllerProvider),
        ),
      ),
      data: (summary) => FeaturePlaceholder(
        title: 'Knowledge base',
        owner: 'Keshomigha',
        description:
            'Model answers and keywords per question.\n${summary.message}',
      ),
    );
  }
}
