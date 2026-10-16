import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/visuals_controller.dart';

/// Diagrams screen - Grid of diagrams for a topic.
///
/// Route: `/visuals`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class DiagramGalleryScreen extends ConsumerWidget {
  const DiagramGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(visualsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Diagrams')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(visualsControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Diagrams',
          owner: 'Mogith',
          description: 'Grid of diagrams for a topic.\n${summary.message}',
          actionLabel: 'Open a diagram',
          onAction: () => context.push(AppRoutes.diagramViewerPath('demo')),
        ),
      ),
    );
  }
}
