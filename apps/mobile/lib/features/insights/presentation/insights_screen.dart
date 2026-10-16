import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/insights_controller.dart';

/// Insights screen - Mastery overview charts.
///
/// Route: `/insights`
///
// TODO(keshomigha): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(insightsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const BrandAppBarTitle('Insights')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(insightsControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Insights',
          owner: 'Keshomigha',
          description: 'Mastery overview charts.\n${summary.message}',
          actionLabel: 'Open heatmap',
          onAction: () => context.push(AppRoutes.heatmap),
        ),
      ),
    );
  }
}
