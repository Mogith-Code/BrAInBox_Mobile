import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/splash_controller.dart';

/// Splash screen - Logo, then redirect based on sign-in and onboarding state.
///
/// Route: `/`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(splashControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Splash')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(splashControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Splash',
          owner: 'Mogith',
          description:
              'Logo, then redirect based on sign-in and onboarding state.\n${summary.message}',
          actionLabel: 'Get started',
          onAction: () => context.go(AppRoutes.onboarding),
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
