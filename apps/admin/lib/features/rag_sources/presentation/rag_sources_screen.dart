import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/rag_sources_controller.dart';

/// RAG sources screen - Source documents, ingestion status, re-index button.
///
/// Route: `/rag-sources`
///
// TODO(samni): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class RagSourcesScreen extends ConsumerWidget {
  const RagSourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ragSourcesControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ErrorBanner(
          message: '$error',
          onRetry: () => ref.invalidate(ragSourcesControllerProvider),
        ),
      ),
      data: (summary) => FeaturePlaceholder(
        title: 'RAG sources',
        owner: 'Samni',
        description:
            'Source documents, ingestion status, re-index button.\n${summary.message}',
      ),
    );
  }
}
