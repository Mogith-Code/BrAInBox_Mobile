import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Topic screen - Topic page with tabs: Notes, Visuals, Practice.
///
/// Route: `/learn/topics/:topicId`. Opened from Home with a real topic id
/// (Next best action / Continue learning).
///
// TODO(keshomigha): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
// The Diagrams tab can show `DiagramGallery(topicId: topicId, showHeader: false)`
// from features/visuals.
class TopicScreen extends StatelessWidget {
  const TopicScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Topic')),
      body: FeaturePlaceholder(
        title: 'Topic',
        owner: 'Keshomigha',
        description:
            'Topic page with tabs: Notes, Visuals, Practice. (topicId: $topicId)',
        actionLabel: 'Open diagrams',
        onAction: () => context.push(AppRoutes.visualsPath(topicId)),
      ),
    );
  }
}
