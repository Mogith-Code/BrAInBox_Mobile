import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Generate model paper screen - AI model paper from chosen units.
///
/// Route: `/exams/generate`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class GeneratePaperScreen extends StatelessWidget {
  const GeneratePaperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate model paper')),
      body: FeaturePlaceholder(
        title: 'Generate model paper',
        owner: 'Udith',
        description: 'AI model paper from chosen units.',
        actionLabel: 'Start exam',
        onAction: () => context.push(AppRoutes.examAttemptPath('demo')),
      ),
    );
  }
}
