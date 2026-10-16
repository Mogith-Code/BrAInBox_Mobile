import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Exam mode screen - Timed exam mode.
///
/// Route: `/exams/attempt/:paperId`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class ExamAttemptScreen extends StatelessWidget {
  const ExamAttemptScreen({super.key, required this.paperId});

  final String paperId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam mode')),
      body: FeaturePlaceholder(
        title: 'Exam mode',
        owner: 'Udith',
        description: 'Timed exam mode. (paperId: $paperId)',
        actionLabel: 'Back',
        onAction: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.home),
      ),
    );
  }
}
