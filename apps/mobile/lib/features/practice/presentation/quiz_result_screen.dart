import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Quiz result screen - Score, mastery change, next steps.
///
/// Route: `/practice/result`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class QuizResultScreen extends StatelessWidget {
  const QuizResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz result')),
      body: FeaturePlaceholder(
        title: 'Quiz result',
        owner: 'Udith',
        description: 'Score, mastery change, next steps.',
        actionLabel: 'Next steps',
        onAction: () => context.push(AppRoutes.nextSteps),
      ),
    );
  }
}
