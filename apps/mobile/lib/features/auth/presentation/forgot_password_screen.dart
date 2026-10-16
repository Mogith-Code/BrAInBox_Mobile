import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Forgot password screen - Send a password reset email.
///
/// Route: `/auth/forgot-password`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: FeaturePlaceholder(
        // Brand: stacked logo above the form.
        header: const AppLogo(variant: AppLogoVariant.stacked, size: 72),

        title: 'Forgot password',
        owner: 'Mogith',
        description: 'Send a password reset email.',
        actionLabel: 'Back',
        onAction: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.home),
      ),
    );
  }
}
