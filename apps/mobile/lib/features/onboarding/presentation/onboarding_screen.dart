import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/onboarding_controller.dart';

/// Onboarding screen - Welcome carousel: what BrAInBox does, in 3-4 slides.
///
/// Route: `/onboarding`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(onboardingControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Onboarding',
          owner: 'Mogith',
          description:
              'Welcome carousel: what BrAInBox does, in 3-4 slides.\n${summary.message}',
          actionLabel: 'Continue',
          onAction: () => context.go(AppRoutes.login),
        ),
      ),
    );
  }
}
