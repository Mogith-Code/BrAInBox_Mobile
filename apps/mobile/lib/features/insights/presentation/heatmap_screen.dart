import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../domain/insights_models.dart';
import 'insights_navigation.dart';
import 'widgets/heatmap_widgets.dart';
import 'widgets/insights_states.dart';

/// Mastery map: one row per unit, one coloured square per topic.
///
/// Route: `/insights/heatmap`. Opened with [attemptId] from the
/// single-attempt overview.
///
/// Data: `GET /insights/topics` (same as the overview).
class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key, this.attemptId});

  final String? attemptId;

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  /// The topic whose sheet is open (outlined on the map).
  String? _selectedKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.attemptId == null
              ? 'Mastery map'
              : 'Mastery map · This attempt',
        ),
      ),
      body: InsightsAsyncBody(
        attemptId: widget.attemptId,
        builder: (context, data) {
          final rows = masteryMapRows(data);
          return [
            const SizedBox(height: AppSpacing.sm),
            const MasteryMapKey(),
            const SizedBox(height: AppSpacing.lg),
            for (final row in rows)
              MasteryMapRowView(
                row: row,
                selectedKey: _selectedKey,
                onTap: (topic) => _showTopic(context, data, row, topic),
              ),
          ];
        },
      ),
    );
  }

  Future<void> _showTopic(
    BuildContext context,
    TopicInsights data,
    MasteryMapRow row,
    TopicResult topic,
  ) async {
    setState(() => _selectedKey = topic.key);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => TopicSheet(
        topic: topic,
        unitLabel: row.label == row.unit ? row.unit : 'Unit ${row.label}',
        minQuestionsPerTopic: data.minQuestionsPerTopic,
        onOpenTopic: () {
          Navigator.of(sheetContext).pop();
          InsightsNav.openTopic(
            context,
            topicKey: topic.key,
            attemptId: widget.attemptId,
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
    if (mounted) setState(() => _selectedKey = null);
  }
}
