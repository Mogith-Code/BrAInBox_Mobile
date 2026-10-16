import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Answer feedback screen - Correct / wrong, explanation, misconception.
///
/// Route: `/practice/feedback`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class AnswerFeedbackScreen extends StatelessWidget {
  const AnswerFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Answer feedback')),
      body: FeaturePlaceholder(
        title: 'Answer feedback',
        owner: 'Udith',
        description: 'Correct / wrong, explanation, misconception.',
        actionLabel: 'See results',
        onAction: () => context.push(AppRoutes.quizResult),
      ),
    );
  }
}
