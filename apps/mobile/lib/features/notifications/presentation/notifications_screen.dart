import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/notifications_controller.dart';

/// Notifications screen - Reminders, AI job results, community replies.
///
/// Route: `/notifications`
///
// TODO(samni): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(notificationsControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Notifications',
          owner: 'Samni',
          description:
              'Reminders, AI job results, community replies.\n${summary.message}',
          actionLabel: 'Back',
          onAction: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
    );
  }
}
