import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../domain/insights_models.dart';
import 'insights_navigation.dart';
import 'widgets/heatmap_widgets.dart';
import 'widgets/insights_states.dart';

/// Mastery map: one row per unit, one cell per topic.
///
/// Route: `/insights/heatmap`. Opened with [attemptId] from the
/// single-attempt overview.
///
/// Data: `GET /insights/topics` (same as the overview).
class HeatmapScreen extends StatelessWidget {
  const HeatmapScreen({super.key, this.attemptId});

  final String? attemptId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          attemptId == null ? 'Mastery map' : 'Mastery map · This attempt',
        ),
      ),
      body: InsightsAsyncBody(
        attemptId: attemptId,
        builder: (context, data) => [
          if (data.gradeBands.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            HeatmapKey(bands: data.gradeBands),
          ],
          for (final unit in data.unitsInOrder) ...[
            InsightsSectionTitle(unit),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final topic in data.topicsInUnit(unit))
                  HeatmapCell(
                    topic: topic,
                    onTap: () => _showTopic(context, data, topic),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showTopic(BuildContext context, TopicInsights data, TopicResult topic) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => TopicSheet(
        topic: topic,
        minQuestionsPerTopic: data.minQuestionsPerTopic,
        onOpenTopic: () {
          Navigator.of(sheetContext).pop();
          InsightsNav.openTopic(
            context,
            topicKey: topic.key,
            attemptId: attemptId,
          );
        },
        onPractice: () {
          Navigator.of(sheetContext).pop();
          // TODO(keshomigha): open practice for this topic once Udith's
          // practice feature takes a topic id. For now: the Practice tab.
          InsightsNav.goToPractice(context);
        },
      ),
    );
  }
}
