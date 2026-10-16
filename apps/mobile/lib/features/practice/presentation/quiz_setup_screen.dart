import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Quiz setup screen - Choose topics, number of questions, difficulty.
///
/// Route: `/practice/setup`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class QuizSetupScreen extends StatelessWidget {
  const QuizSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz setup')),
      body: FeaturePlaceholder(
        title: 'Quiz setup',
        owner: 'Udith',
        description: 'Choose topics, number of questions, difficulty.',
        actionLabel: 'Start quiz',
        onAction: () => context.push(AppRoutes.mcqQuestion),
      ),
    );
  }
}
