import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Mistake journal screen - Every wrong answer, grouped by misconception.
///
/// Route: `/insights/mistakes`
///
// TODO(keshomigha): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class MistakeJournalScreen extends StatelessWidget {
  const MistakeJournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mistake journal')),
      body: FeaturePlaceholder(
        title: 'Mistake journal',
        owner: 'Keshomigha',
        description: 'Every wrong answer, grouped by misconception.',
        actionLabel: 'Back',
        onAction: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.home),
      ),
    );
  }
}
