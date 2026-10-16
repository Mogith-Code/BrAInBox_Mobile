import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/syllabus_controller.dart';

/// Learn screen - All syllabus units with mastery.
///
/// Route: `/learn`
///
// TODO(keshomigha): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class SyllabusScreen extends ConsumerWidget {
  const SyllabusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(syllabusControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const BrandAppBarTitle('Learn')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(syllabusControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Learn',
          owner: 'Keshomigha',
          description: 'All syllabus units with mastery.\n${summary.message}',
          actionLabel: 'Open a unit',
          onAction: () => context.push(AppRoutes.unitDetailPath('demo')),
        ),
      ),
    );
  }
}
