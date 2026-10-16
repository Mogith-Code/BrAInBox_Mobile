import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/exams_controller.dart';

/// Past papers screen - Past A/L Biology papers by year.
///
/// Route: `/exams`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class PastPapersScreen extends ConsumerWidget {
  const PastPapersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(examsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Past papers')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(examsControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Past papers',
          owner: 'Udith',
          description: 'Past A/L Biology papers by year.\n${summary.message}',
          actionLabel: 'Generate a model paper',
          onAction: () => context.push(AppRoutes.generatePaper),
        ),
      ),
    );
  }
}
