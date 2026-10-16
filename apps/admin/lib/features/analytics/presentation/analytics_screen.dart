import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/analytics_controller.dart';

/// Analytics screen - Most-missed topics and misconceptions.
///
/// Route: `/analytics`
///
// TODO(keshomigha): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ErrorBanner(
          message: '$error',
          onRetry: () => ref.invalidate(analyticsControllerProvider),
        ),
      ),
      data: (summary) => FeaturePlaceholder(
        title: 'Analytics',
        owner: 'Keshomigha',
        description:
            'Most-missed topics and misconceptions.\n${summary.message}',
      ),
    );
  }
}
