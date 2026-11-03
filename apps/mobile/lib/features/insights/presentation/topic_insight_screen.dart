import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../domain/insights_models.dart';
import 'insights_navigation.dart';
import 'widgets/insights_states.dart';
import 'widgets/topic_detail_widgets.dart';

/// Topic detail: one topic's result, what it means, what to revise,
/// questions to review, misconceptions and resources.
///
/// Opened with [InsightsNav.openTopic] (no route constant yet).
/// Data: `GET /insights/topics` (same as the overview, no extra request).
class TopicInsightScreen extends StatelessWidget {
  const TopicInsightScreen({super.key, required this.topicKey, this.attemptId});

  /// [TopicResult.key]: the topic id, or the name when the id is null.
  final String topicKey;
  final String? attemptId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Topic result')),
      body: InsightsAsyncBody(
        attemptId: attemptId,
        builder: (context, data) {
          final topic = data.topicByKey(topicKey);
          if (topic == null) {
            return [
              EmptyState(
                icon: Icons.search_off_rounded,
                title: "This topic isn't in your results",
                actionLabel: 'Back',
                onAction: () => InsightsNav.back(context),
              ),
            ];
          }
          return _details(data, topic);
        },
      ),
    );
  }

  List<Widget> _details(TopicInsights data, TopicResult topic) {
    final feedback = data.feedbackFor(topic);
    return [
      TopicHeaderCard(
        topic: topic,
        minQuestionsPerTopic: data.minQuestionsPerTopic,
      ),
      if (feedback != null) ...[
        if (feedback.summary.isNotEmpty)
          FeedbackTextCard(
            icon: Icons.insights_rounded,
            title: 'What this means',
            text: feedback.summary,
          ),
        if (feedback.action.isNotEmpty)
          FeedbackTextCard(
            icon: Icons.flag_outlined,
            title: 'What to revise next',
            text: feedback.action,
          ),
        if (feedback.reviewQuestions.isNotEmpty) ...[
          const InsightsSectionTitle('Questions to review'),
          for (final question in feedback.reviewQuestions)
            ReviewQuestionCard(question: question),
        ],
        if (feedback.misconceptions.isNotEmpty) ...[
          const InsightsSectionTitle('Common misconceptions'),
          for (final misconception in feedback.misconceptions)
            MisconceptionTile(misconception: misconception),
        ],
        if (feedback.resources.isNotEmpty) ...[
          const InsightsSectionTitle('Resources'),
          for (final resource in feedback.resources)
            ResourceCard(resource: resource),
        ],
      ],
    ];
  }
}
