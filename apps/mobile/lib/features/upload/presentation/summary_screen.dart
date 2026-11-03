import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

/// AI summary screen (Figma B13) - key concepts and gaps in uploaded notes.
///
/// Route: `/learn/summary/:summaryId` (full screen)
///
// TODO(samni): build the real UI from Figma (upload/summarisation branch).
class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key, required this.summaryId});

  final String summaryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Summary')),
      body: FeaturePlaceholder(
        title: 'Summary',
        owner: 'Samni',
        description:
            'Key concepts, syllabus match and missing topics. '
            '(summaryId: $summaryId)',
      ),
    );
  }
}
