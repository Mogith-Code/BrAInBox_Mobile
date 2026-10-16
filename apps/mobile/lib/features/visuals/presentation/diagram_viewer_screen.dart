import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Diagram viewer screen - Full-screen zoomable diagram (photo_view).
///
/// Route: `/visuals/view/:visualId`
///
// TODO(mogith): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class DiagramViewerScreen extends StatelessWidget {
  const DiagramViewerScreen({super.key, required this.visualId});

  final String visualId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagram viewer')),
      body: FeaturePlaceholder(
        title: 'Diagram viewer',
        owner: 'Mogith',
        description:
            'Full-screen zoomable diagram (photo_view). (visualId: $visualId)',
        actionLabel: 'Generate a visual',
        onAction: () => context.push(AppRoutes.generateVisual),
      ),
    );
  }
}
