import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Topic screen - Topic page with tabs: Notes, Visuals, Practice.
///
/// Route: `/learn/topics/:topicId`
///
// TODO(keshomigha): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
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
        actionLabel: 'Open notes',
        onAction: () => context.push(AppRoutes.topicNotesPath('demo')),
      ),
    );
  }
}
