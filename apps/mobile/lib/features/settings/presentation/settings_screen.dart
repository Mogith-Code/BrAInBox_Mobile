import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/settings_controller.dart';

/// Settings screen - Account, theme, notifications, privacy, about, sign out.
///
/// Route: `/settings`
///
// TODO(samni): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(settingsControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Settings',
          owner: 'Samni',
          description:
              'Account, theme, notifications, privacy, about, sign out.\n${summary.message}',
          actionLabel: 'Back',
          onAction: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
    );
  }
}
