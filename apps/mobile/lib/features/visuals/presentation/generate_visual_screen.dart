import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Generate visual screen - Ask the AI for a diagram.
///
/// Route: `/visuals/generate`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class GenerateVisualScreen extends StatelessWidget {
  const GenerateVisualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate visual')),
      body: FeaturePlaceholder(
        title: 'Generate visual',
        owner: 'Mogith',
        description: 'Ask the AI for a diagram.',
        actionLabel: 'Back',
        onAction: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.home),
      ),
    );
  }
}
