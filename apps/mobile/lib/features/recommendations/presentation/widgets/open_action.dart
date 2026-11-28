import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes.dart';

/// Icon and button label for each recommendation action.
({IconData icon, String label}) actionStyle(String? action) => switch (action) {
  'revise_note' => (icon: Icons.menu_book_outlined, label: 'Open short notes'),
  'practice_quiz' => (icon: Icons.quiz_outlined, label: 'Start practice'),
  'watch_video' => (icon: Icons.play_circle_outline, label: 'Watch video'),
  'retry_answer' => (icon: Icons.edit_note, label: 'Rewrite my answer'),
  'reassess' => (icon: Icons.fact_check_outlined, label: 'Take the check'),
  'view_visual' => (icon: Icons.image_outlined, label: 'Open diagram'),
  _ => (icon: Icons.arrow_forward, label: 'Open'),
};

/// Opens the screen a recommendation or plan item points at.
///
/// Next steps and Study plan are full-screen pages above the bottom tabs.
/// Quiz setup and topics live inside the tabs, so they must open with `go`:
/// a `push` would put the tab shell on the stack twice and crash.
Future<void> openAction(
  BuildContext context, {
  required String? action,
  required Map<String, dynamic> target,
  String? topicId,
  String? conceptId,
}) async {
  final topic = topicId ?? target['topic_id'] as String?;
  final concept = conceptId ?? target['concept_id'] as String?;
  switch (action) {
    case 'revise_note' when topic != null:
      await context.push(AppRoutes.shortNotesPath(topic));
    case 'view_visual' when topic != null:
      await context.push(AppRoutes.visualsPath(topic));
    case 'practice_quiz' || 'reassess':
      context.go(AppRoutes.quizSetupPath(conceptId: concept));
    case 'watch_video':
      final url = Uri.tryParse('${target['url'] ?? ''}');
      if (url != null && url.hasScheme) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (topic != null && context.mounted) {
        context.go(AppRoutes.topicPath(topic));
      }
    case 'retry_answer':
      await context.push(AppRoutes.writtenQuestions);
    default:
      if (topic != null) context.go(AppRoutes.topicPath(topic));
  }
}
