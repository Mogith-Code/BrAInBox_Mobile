import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Answer feedback screen - Marks, missing keywords and AI feedback.
///
/// Route: `/evaluation/feedback/:evaluationId`
///
// TODO(keshomigha): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class EvaluationFeedbackScreen extends StatelessWidget {
  const EvaluationFeedbackScreen({super.key, required this.evaluationId});

  final String evaluationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Answer feedback')),
      body: FeaturePlaceholder(
        title: 'Answer feedback',
        owner: 'Keshomigha',
        description:
            'Marks, missing keywords and AI feedback. (evaluationId: $evaluationId)',
        actionLabel: 'Back',
        onAction: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.home),
      ),
    );
  }
}
