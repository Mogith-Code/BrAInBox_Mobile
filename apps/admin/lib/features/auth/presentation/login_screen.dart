import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../application/auth_controller.dart';

/// Admin login screen - Email + password sign-in. Non-admin accounts are refused.
///
/// Route: `/login`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Admin login')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(authControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Admin login',
          owner: 'Mogith',
          description:
              'Email + password sign-in. Non-admin accounts are refused.\n${summary.message}',
          actionLabel: 'Continue to dashboard',
          onAction: () => context.go(AdminRoutes.dashboard),
        ),
      ),
    );
  }
}
