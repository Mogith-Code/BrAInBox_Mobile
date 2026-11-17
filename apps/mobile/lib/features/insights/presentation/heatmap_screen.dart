import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/progress_providers.dart';
import '../data/insights_repository.dart';
import '../domain/insights_models.dart';
import 'insights_navigation.dart';
import 'widgets/heatmap_widgets.dart';
import 'widgets/insights_states.dart';
import 'widgets/insights_style.dart';

/// Mastery map: one row per unit, one coloured square per topic.
///
/// Route: `/insights/heatmap`.
/// - Overall: `GET /insights/heatmap` (every syllabus topic, mastery from
///   practised concepts). Tapping a topic opens quiz setup for it.
/// - With [attemptId] (from the single-attempt overview):
///   `GET /insights/topics?attempt_id=`; tapping opens the topic sheet.
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
      body: attemptId == null
          ? const _TopicHeatmapBody()
          : _AttemptMapBody(attemptId: attemptId!),
    );
  }
}

/// Overall mode: `GET /insights/heatmap`.
class _TopicHeatmapBody extends ConsumerWidget {
  const _TopicHeatmapBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(topicHeatmapProvider);
    Future<void> refresh() => ref
        .refresh(topicHeatmapProvider.future)
        .then((_) {}, onError: (Object _) {});

    ref.listen(topicHeatmapProvider, (_, next) {
      if (next.error is InsightsNotRegistered) {
        InsightsNav.goToProfileSetup(context);
      }
    });

    final data = state.value;
    if (data == null) {
      if (state.hasError) {
        return InsightsErrorView(error: state.error!, onRetry: refresh);
      }
      return const InsightsSkeleton();
    }
    if (!data.hasTopics) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: AppSpacing.xxl),
            EmptyState(
              icon: Icons.grid_view_rounded,
              title: 'No topics yet',
              message: 'The syllabus topics will appear here.',
            ),
          ],
        ),
      );
    }

    final muted = InsightsColors.mutedText(context);
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          if (state.hasError)
            ErrorBanner(message: '${state.error}', onRetry: refresh),
          const SizedBox(height: AppSpacing.sm),
          const MasteryMapKey(),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.nothingPractised
                ? 'Nothing practised yet. Tap a topic to start a quiz on it.'
                : 'Tap a topic to practise it.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final unit in data.units)
            if (unit.topics.isNotEmpty)
              TopicHeatmapRow(
                unit: unit,
                onTap: (topic) =>
                    InsightsNav.practiseTopic(context, topic.topicId),
              ),
        ],
      ),
    );
  }
}

/// Single-attempt mode: `GET /insights/topics?attempt_id=`.
class _AttemptMapBody extends StatefulWidget {
  const _AttemptMapBody({required this.attemptId});

  final String attemptId;

  @override
  State<_AttemptMapBody> createState() => _AttemptMapBodyState();
}

class _AttemptMapBodyState extends State<_AttemptMapBody> {
  /// The topic whose sheet is open (outlined on the map).
  String? _selectedKey;

  @override
  Widget build(BuildContext context) {
    return InsightsAsyncBody(
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
          InsightsNav.practiseTopic(context, topic.topicId);
        },
      ),
    );
    if (mounted) setState(() => _selectedKey = null);
  }
}
