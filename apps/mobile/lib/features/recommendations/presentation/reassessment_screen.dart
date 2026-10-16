import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Reassessment screen - Short test to re-check weak topics.
///
/// Route: `/recommendations/reassessment`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class ReassessmentScreen extends StatelessWidget {
  const ReassessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reassessment')),
      body: FeaturePlaceholder(
        title: 'Reassessment',
        owner: 'Udith',
        description: 'Short test to re-check weak topics.',
        actionLabel: 'Back',
        onAction: () =>
            context.canPop() ? context.pop() : context.go(AppRoutes.home),
      ),
    );
  }
}
