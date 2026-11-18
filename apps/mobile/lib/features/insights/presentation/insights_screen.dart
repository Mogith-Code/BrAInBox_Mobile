import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/insights_controller.dart';
import '../application/progress_providers.dart';
import '../domain/insights_models.dart';
import 'insights_navigation.dart';
import 'widgets/insights_states.dart';
import 'widgets/mastery_card.dart';
import 'widgets/overview_cards.dart';
import 'widgets/progress_charts.dart';
import 'widgets/unit_mastery_card.dart';

/// Insights overview: mastery ring, unit mastery, strongest / weakest, weak
/// topics, mastery map, grade bands.
///
/// Route: `/insights` (bottom-nav tab). With `?attempt_id=<id>` (see
/// [InsightsNav.attemptLocation]) it shows one attempt, titled
/// "This attempt", with the per-attempt result instead of the mastery ring.
///
/// Data: `GET /insights/topics` (MCQ results), `GET /insights/units`
/// (unit mastery) and `GET /insights/overview` (study time, accuracy trend).
class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key, this.attemptId});

  /// Analyse only this attempt. When null, the route's `attempt_id` query is
  /// used, and without one every finished attempt is analysed.
  final String? attemptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = attemptId ?? InsightsNav.attemptIdFromRoute(context);
    return Scaffold(
      appBar: AppBar(
        title: id == null
            ? const BrandAppBarTitle('Insights')
            : const Text('This attempt'),
      ),
      body: InsightsAsyncBody(
        attemptId: id,
        // Pull-to-refresh on the overview also reloads the unit mastery card
        // and the study time / accuracy charts.
        onRefresh: id == null
            ? () async {
                ref.invalidate(insightsOverviewProvider);
                await ref
                    .read(unitInsightsControllerProvider.notifier)
                    .refresh();
              }
            : null,
        builder: (context, data) => [
          if (id == null) ...[
            MasteryCard(data: data),
            const UnitMasteryCard(),
            const ProgressCharts(),
          ] else
            OverallHeroCard(
              overall: data.overall,
              attemptsAnalysed: data.attemptsAnalysed,
              singleAttempt: true,
            ),
          ..._topics(context, data, id),
        ],
      ),
    );
  }

  List<Widget> _topics(
    BuildContext context,
    TopicInsights data,
    String? attemptId,
  ) {
    void open(TopicResult topic) => InsightsNav.openTopic(
      context,
      topicKey: topic.key,
      attemptId: attemptId,
    );

    final weak = [for (final name in data.weakTopics) ?data.topicByName(name)];
    final insufficient = [
      for (final name in data.insufficientDataTopics) ?data.topicByName(name),
    ];

    return [
      if (attemptId != null && data.topics.isNotEmpty) ...[
        const InsightsSectionTitle('Topic status'),
        StatusSummary(counts: data.statusCounts),
      ],
      StrongestWeakestTiles(
        strongest: data.strongestTopic,
        weakest: data.weakestTopic,
        onOpen: open,
      ),
      if (weak.isNotEmpty) ...[
        const InsightsSectionTitle('Weak topics'),
        for (final topic in weak)
          InsightTopicTile(
            topic: topic,
            minQuestionsPerTopic: data.minQuestionsPerTopic,
            onTap: () => open(topic),
          ),
      ],
      if (insufficient.isNotEmpty)
        InsufficientDataSection(
          topics: insufficient,
          minQuestionsPerTopic: data.minQuestionsPerTopic,
          onOpen: open,
        ),
      if (data.topics.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Open mastery map',
          icon: Icons.grid_view_rounded,
          variant: AppButtonVariant.secondary,
          onPressed: () =>
              InsightsNav.openHeatmap(context, attemptId: attemptId),
        ),
      ],
      if (data.gradeBands.isNotEmpty) ...[
        const InsightsSectionTitle('Grade bands'),
        GradeBandLegend(bands: data.gradeBands),
      ],
      if (data.note.isNotEmpty) FormativeNoteBox(note: data.note),
    ];
  }
}
