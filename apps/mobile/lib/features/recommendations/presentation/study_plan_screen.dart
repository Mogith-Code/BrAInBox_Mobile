import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Study plan screen - Day-by-day study plan.
///
/// Route: `/recommendations/study-plan`
///
// TODO(udith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class StudyPlanScreen extends StatelessWidget {
  const StudyPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study plan')),
      body: FeaturePlaceholder(
        title: 'Study plan',
        owner: 'Udith',
        description: 'Day-by-day study plan.',
        actionLabel: 'Reassessment',
        onAction: () => context.push(AppRoutes.reassessment),
      ),
    );
  }
}
