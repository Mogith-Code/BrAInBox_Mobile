import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Verify email screen - Ask the student to open the verification link.
///
/// Route: `/auth/verify-email`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: FeaturePlaceholder(
        title: 'Verify email',
        owner: 'Mogith',
        description: 'Ask the student to open the verification link.',
        actionLabel: 'Next: profile setup',
        onAction: () => context.go(AppRoutes.profileSetup),
      ),
    );
  }
}
