import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';

/// Short notes screen - Short revision notes for a topic.
///
/// Route: `/notes/topics/:topicId/short`
///
// TODO(samni): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class ShortNotesScreen extends StatelessWidget {
  const ShortNotesScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Short notes')),
      body: FeaturePlaceholder(
        title: 'Short notes',
        owner: 'Samni',
        description: 'Short revision notes for a topic. (topicId: $topicId)',
        actionLabel: 'Open library',
        onAction: () => context.push(AppRoutes.notesLibrary),
      ),
    );
  }
}
