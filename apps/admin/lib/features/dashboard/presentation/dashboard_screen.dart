import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/dashboard_controller.dart';

/// Dashboard screen - KPI tiles (students, questions, pending reviews) and activity.
///
/// Route: `/dashboard`
///
// TODO(samni): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: ErrorBanner(
          message: '$error',
          onRetry: () => ref.invalidate(dashboardControllerProvider),
        ),
      ),
      data: (summary) => FeaturePlaceholder(
        title: 'Dashboard',
        owner: 'Samni',
        description:
            'KPI tiles (students, questions, pending reviews) and activity.\n${summary.message}',
      ),
    );
  }
}
