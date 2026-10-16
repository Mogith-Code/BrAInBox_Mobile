import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Sign up screen - Create an account (name, email, password).
///
/// Route: `/auth/signup`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: FeaturePlaceholder(
        // Brand: stacked logo above the form.
        header: const AppLogo(variant: AppLogoVariant.stacked, size: 72),

        title: 'Sign up',
        owner: 'Mogith',
        description: 'Create an account (name, email, password).',
        actionLabel: 'Next: verify email',
        onAction: () => context.push(AppRoutes.verifyEmail),
      ),
    );
  }
}
