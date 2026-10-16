import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Heatmap screen - Topic x mastery heatmap.
///
/// Route: `/insights/heatmap`
///
// TODO(keshomigha): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class HeatmapScreen extends StatelessWidget {
  const HeatmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Heatmap')),
      body: FeaturePlaceholder(
        title: 'Heatmap',
        owner: 'Keshomigha',
        description: 'Topic x mastery heatmap.',
        actionLabel: 'Mistake journal',
        onAction: () => context.push(AppRoutes.mistakeJournal),
      ),
    );
  }
}
