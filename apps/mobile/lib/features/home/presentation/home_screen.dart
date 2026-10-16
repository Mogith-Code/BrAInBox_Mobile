import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/home_controller.dart';

/// Home screen - Dashboard: next best action and today's plan.
///
/// Route: `/home`
///
// TODO(samni): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const BrandAppBarTitle(BrandAssets.appName),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(homeControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Home',
          owner: 'Samni',
          description:
              'Dashboard: next best action and today\'s plan.\n${summary.message}',
          actionLabel: 'Open today\'s plan',
          onAction: () => context.push(AppRoutes.studyPlan),
        ),
      ),
      // DEBUG ONLY: jump to any screen while features are being built.
      floatingActionButton: kDebugMode
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.devMenu),
              icon: const Icon(Icons.developer_mode),
              label: const Text('Dev menu'),
            )
          : null,
    );
  }
}
