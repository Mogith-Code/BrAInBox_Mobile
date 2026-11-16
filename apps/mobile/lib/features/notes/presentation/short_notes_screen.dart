import 'package:flutter/material.dart';

import 'topic_notes_screen.dart';

/// Short notes for a topic, full screen. Route: `/notes/topics/:topicId/short`.
class ShortNotesScreen extends StatelessWidget {
  const ShortNotesScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) =>
      TopicNotesScreen(topicId: topicId, short: true);
}
