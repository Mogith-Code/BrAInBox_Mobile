import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Quiz setup screen - Choose topics, number of questions, difficulty.
///
/// Route: `/practice/setup`, or `/practice/setup?topicId=...&mode=quick|weak`
/// from a topic's Practice tab (Learn).
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class QuizSetupScreen extends StatelessWidget {
  const QuizSetupScreen({super.key, this.topicId, this.mode});

  /// Practise only this topic (from Learn > topic > Practice).
  final String? topicId;

  /// `quick` = 10 MCQs, `weak` = weak areas only.
  final String? mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz setup')),
      body: FeaturePlaceholder(
        title: 'Quiz setup',
        owner: 'Udith',
        description: topicId == null
            ? 'Choose topics, number of questions, difficulty.'
            : '${mode == 'weak' ? 'Weak areas only' : 'Quick 10 MCQs'} '
                  'for topic $topicId.',
        actionLabel: 'Start quiz',
        onAction: () => context.push(AppRoutes.mcqQuestion),
      ),
    );
  }
}
