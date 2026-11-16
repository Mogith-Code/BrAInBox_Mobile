import 'package:flutter/material.dart';

import '../../notes/presentation/notes_tabs.dart';
import '../../visuals/presentation/diagram_gallery_screen.dart';
import '../domain/syllabus_models.dart';
import 'topic_media_tabs.dart';

/// The tabs on the Topic page, in order.
enum TopicTab {
  notes('Notes', showsAskButton: true),
  shortNotes('Short Notes'),
  diagrams('Diagrams'),
  videos('Videos'),
  practice('Practice');

  const TopicTab(this.label, {this.showsAskButton = false});

  final String label;

  /// Show the full "Ask BrAInBox" button on this tab.
  final bool showsAskButton;
}

/// The body of one Topic tab. Each body scrolls on its own and has
/// skeleton, error (Retry) and pull-to-refresh states.
class TopicTabBody extends StatelessWidget {
  const TopicTabBody({super.key, required this.tab, required this.detail});

  final TopicTab tab;
  final TopicDetail detail;

  @override
  Widget build(BuildContext context) => switch (tab) {
    TopicTab.notes => NotesTab(detail: detail),
    TopicTab.shortNotes => ShortNotesTab(detail: detail),
    // Mogith's visuals gallery: AI visuals with labels, and a "Generate a
    // new visual" card for this topic.
    TopicTab.diagrams => DiagramGallery(
      topicId: detail.topic.id,
      showHeader: false,
    ),
    TopicTab.videos => VideosTab(detail: detail),
    TopicTab.practice => PracticeTab(detail: detail),
  };
}
