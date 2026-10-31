import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/insights_controller.dart';
import '../domain/insights_models.dart';
import '../domain/insights_summary.dart';
import 'insights_navigation.dart';
import 'widgets/insights_states.dart';
import 'widgets/overview_cards.dart';
import 'widgets/summary_cards.dart';

/// Insights overview: mastery ring, study time, accuracy trend, unit
/// mastery, then strongest / weak topics.
///
/// Route: `/insights` (bottom-nav tab). With `?attempt_id=<id>` (see
/// [InsightsNav.attemptLocation]) it shows one attempt, titled
/// "This attempt", with the per-attempt result instead of the summary cards.
///
/// Data: `GET /insights/topics` and `GET /insights/summary?period=`.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key, this.attemptId});

  /// Analyse only this attempt. When null, the route's `attempt_id` query is
  /// used, and without one every finished attempt is analysed.
  final String? attemptId;

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  InsightsPeriod _period = InsightsPeriod.week;

  @override
  Widget build(BuildContext context) {
    final id = widget.attemptId ?? InsightsNav.attemptIdFromRoute(context);
    final summaryProvider = insightsSummaryControllerProvider(period: _period);
    // Only the overview uses the summary; "This attempt" never requests it.
    final summary = id == null ? ref.watch(summaryProvider) : null;
    Future<void> refreshSummary() =>
        ref.read(summaryProvider.notifier).refresh();
    return Scaffold(
      appBar: AppBar(
        title: id == null
            ? const BrandAppBarTitle('Insights')
            : const Text('This attempt'),
        actions: [
          if (id == null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: InsightsPeriodSelector(
                period: _period,
                onChanged: (period) => setState(() => _period = period),
              ),
            ),
        ],
      ),
      body: InsightsAsyncBody(
        attemptId: id,
        onRefresh: id == null ? refreshSummary : null,
        builder: (context, data) => [
          if (summary != null)
            ..._summary(data, summary, refreshSummary)
          else
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

  List<Widget> _summary(
    TopicInsights data,
    AsyncValue<InsightsSummary> summary,
    VoidCallback retry,
  ) {
    return [
      MasteryCard(summary: summary, fallback: MasteryCard.fromTopics(data)),
      StudyTimeCard(summary: summary, period: _period, onRetry: retry),
      AccuracyTrendCard(summary: summary, onRetry: retry),
      UnitMasteryCard(summary: summary, onRetry: retry),
    ];
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
