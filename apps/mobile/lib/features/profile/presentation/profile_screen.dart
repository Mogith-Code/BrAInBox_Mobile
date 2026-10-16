import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/profile_controller.dart';

/// Profile setup screen - Stream, exam year, goals and daily study time.
///
/// Route: `/profile/setup`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile setup')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(profileControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Profile setup',
          owner: 'Mogith',
          description:
              'Stream, exam year, goals and daily study time.\n${summary.message}',
          actionLabel: 'Finish and go home',
          onAction: () => context.go(AppRoutes.home),
        ),
      ),
    );
  }
}
