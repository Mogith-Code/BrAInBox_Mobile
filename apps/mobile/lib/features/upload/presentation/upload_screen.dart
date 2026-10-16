import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/upload_controller.dart';

/// Upload notes screen - Pick a PDF or photo, upload it, wait for processing, show the AI summary.
///
/// Route: `/upload`
///
// TODO(samni): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class UploadScreen extends ConsumerWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uploadControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Upload notes')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(uploadControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Upload notes',
          owner: 'Samni',
          description:
              'Pick a PDF or photo, upload it, wait for processing, show the AI summary.\n${summary.message}',
          actionLabel: 'Back',
          onAction: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
    );
  }
}
