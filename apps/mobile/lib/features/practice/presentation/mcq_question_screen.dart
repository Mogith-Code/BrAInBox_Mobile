import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// MCQ question screen - One MCQ at a time (McqOptionTile).
///
/// Route: `/practice/quiz`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class McqQuestionScreen extends StatelessWidget {
  const McqQuestionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MCQ question')),
      body: FeaturePlaceholder(
        title: 'MCQ question',
        owner: 'Udith',
        description: 'One MCQ at a time (McqOptionTile).',
        actionLabel: 'Check answer',
        onAction: () => context.push(AppRoutes.answerFeedback),
      ),
    );
  }
}
