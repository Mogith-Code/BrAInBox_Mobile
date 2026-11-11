import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../visuals/presentation/diagram_gallery_screen.dart';
import '../domain/syllabus_models.dart';

/// The tabs on the Topic page (Figma B4), in order.
enum TopicTab {
  notes('Notes', showsAskButton: true),
  shortNotes('Short Notes'),
  diagrams('Diagrams', showsAskButton: true),
  videos('Videos'),
  practice('Practice');

  const TopicTab(this.label, {this.showsAskButton = false});

  final String label;

  /// Show the "Ask BrAInBox" button on this tab.
  final bool showsAskButton;
}

/// The body of one Topic tab.
///
/// PLUG-IN SLOT: each tab belongs to another feature. To plug yours in,
/// replace its `FeaturePlaceholder` case below with your widget. It gets the
/// topic and its unit through [detail]. Keep the widget scrollable on its
/// own - the Topic page does not scroll the tab body for you.
class TopicTabBody extends StatelessWidget {
  const TopicTabBody({super.key, required this.tab, required this.detail});

  final TopicTab tab;
  final TopicDetail detail;

  @override
  Widget build(BuildContext context) {
    final topicId = detail.topic.id;
    return switch (tab) {
      // TODO(samni): plug in the notes reader.
      TopicTab.notes => FeaturePlaceholder(
        title: 'Notes',
        owner: 'Samni',
        description: 'Full notes for ${detail.topic.title}.',
        actionLabel: 'Open notes',
        onAction: () => context.push(AppRoutes.topicNotesPath(topicId)),
      ),
      // TODO(samni): plug in short notes.
      TopicTab.shortNotes => FeaturePlaceholder(
        title: 'Short Notes',
        owner: 'Samni',
        description: 'Quick revision points.',
        actionLabel: 'Open short notes',
        onAction: () => context.push(AppRoutes.shortNotesPath(topicId)),
      ),
      // Mogith's diagram gallery; its last card generates a visual for this
      // topic (students can also draw anything from Home > My visuals).
      TopicTab.diagrams => DiagramGallery(topicId: topicId, showHeader: false),
      TopicTab.videos => const FeaturePlaceholder(
        title: 'Videos',
        owner: 'TBD',
        description: 'Video lessons for this topic.',
      ),
      // TODO(udith): plug in topic practice.
      TopicTab.practice => FeaturePlaceholder(
        title: 'Practice',
        owner: 'Udith',
        description: 'MCQs and structured questions on this topic.',
        actionLabel: 'Set up a quiz',
        onAction: () => context.push(AppRoutes.quizSetup),
      ),
    };
  }
}
