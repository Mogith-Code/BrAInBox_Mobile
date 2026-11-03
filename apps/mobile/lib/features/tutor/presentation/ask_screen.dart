import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

/// Ask BrAInBox screen - chat with the AI tutor, optionally about a topic.
///
/// Route: `/ask?topicId=...` (full screen)
///
// TODO: build the real UI from Figma once an owner is assigned. Keep this
// file UI-only: read state from a controller. Never call Dio / Firebase here.
class AskScreen extends StatelessWidget {
  const AskScreen({super.key, this.topicId});

  final String? topicId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask BrAInBox')),
      body: FeaturePlaceholder(
        title: 'Ask BrAInBox',
        owner: 'TBD',
        description:
            'Ask the AI tutor anything about the syllabus.'
            '${topicId == null ? '' : ' (topicId: $topicId)'}',
      ),
    );
  }
}
