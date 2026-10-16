import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/notes_controller.dart';

/// Topic notes screen - AI notes for a topic (markdown) + generate-notes sheet.
///
/// Route: `/notes/topics/:topicId`
///
// TODO(samni): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class TopicNotesScreen extends ConsumerWidget {
  const TopicNotesScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notesControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Topic notes')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(notesControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Topic notes',
          owner: 'Samni',
          description:
              'AI notes for a topic (markdown) + generate-notes sheet. (topicId: $topicId)\n${summary.message}',
          actionLabel: 'Short notes',
          onAction: () => context.push(AppRoutes.shortNotesPath('demo')),
        ),
      ),
    );
  }
}
