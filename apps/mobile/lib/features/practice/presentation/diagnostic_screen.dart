import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Diagnostic test screen - First-time diagnostic to find weak topics.
///
/// Route: `/practice/diagnostic`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class DiagnosticScreen extends StatelessWidget {
  const DiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostic test')),
      body: FeaturePlaceholder(
        title: 'Diagnostic test',
        owner: 'Udith',
        description: 'First-time diagnostic to find weak topics.',
        actionLabel: 'Back',
        onAction: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.home),
      ),
    );
  }
}
