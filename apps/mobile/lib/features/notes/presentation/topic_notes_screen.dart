import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../syllabus/application/topic_controller.dart';
import '../../syllabus/presentation/widgets/learn_widgets.dart';
import 'notes_tabs.dart';

/// Full-screen notes for a topic (outside the Topic page), e.g. from links.
///
/// Routes: `/notes/topics/:topicId` (full) and `/notes/topics/:topicId/short`.
class TopicNotesScreen extends ConsumerWidget {
  const TopicNotesScreen({super.key, required this.topicId, this.short = false});

  final String topicId;
  final bool short;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(topicControllerProvider(topicId));
    return Scaffold(
      backgroundColor: context.learnBackground,
      appBar: AppBar(
        title: Text(
          state.value?.topic.title ?? (short ? 'Short notes' : 'Notes'),
        ),
      ),
      body: switch (state) {
        AsyncValue(:final value?) =>
          short ? ShortNotesTab(detail: value) : NotesTab(detail: value),
        AsyncError(:final error) => ErrorCard(
          error: error,
          onRetry: () => ref.invalidate(topicControllerProvider(topicId)),
        ),
        _ => const SkeletonList(label: 'Loading notes'),
      },
    );
  }
}
