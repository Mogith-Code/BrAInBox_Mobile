import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/auth_controller.dart';

/// Log in screen - Email + password sign-in with Firebase Auth.
///
/// Route: `/auth/login`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: '$error',
            onRetry: () => ref.invalidate(authControllerProvider),
          ),
        ),
        data: (summary) => FeaturePlaceholder(
          title: 'Log in',
          owner: 'Mogith',
          description:
              'Email + password sign-in with Firebase Auth.\n${summary.message}',
          actionLabel: 'Create an account',
          onAction: () => context.push(AppRoutes.signup),
        ),
      ),
    );
  }
}
