import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/insights_models.dart';
import 'insights_style.dart';

/// White rounded card used on the Insights overview.
class InsightsPanel extends StatelessWidget {
  const InsightsPanel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = InsightsColors.isDark(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: InsightsColors.line(context)),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }
}

/// One legend row of the mastery card: "Mastered · 11 topics".
@immutable
class MasteryLegendItem {
  const MasteryLegendItem({
    required this.label,
    required this.color,
    required this.topicCount,
  });

  final String label;
  final Color color;
  final int topicCount;
}

/// Mastery ring (the backend's overall percent) and the Mastered / Strong /
/// Improving / Weak legend (the backend's topic statuses).
///
/// Data: `GET /insights/topics`. Nothing is calculated here: the ring shows
/// `overall.percent` and the legend only counts the statuses the backend set.
class MasteryCard extends StatelessWidget {
  const MasteryCard({super.key, required this.data});

  final TopicInsights data;

  /// strong -> Mastered, good -> Strong, developing -> Improving,
  /// weak + very weak -> Weak. Colours follow the Insights colour code.
  static List<MasteryLegendItem> legendFor(TopicInsights data) {
    final counts = data.statusCounts;
    int count(TopicStatus status) => counts[status] ?? 0;
    return [
      MasteryLegendItem(
        label: 'Mastered',
        color: StatusStyle.of(TopicStatus.strong).accent,
        topicCount: count(TopicStatus.strong),
      ),
      MasteryLegendItem(
        label: 'Strong',
        color: StatusStyle.of(TopicStatus.good).accent,
        topicCount: count(TopicStatus.good),
      ),
      MasteryLegendItem(
        label: 'Improving',
        color: StatusStyle.of(TopicStatus.developing).accent,
        topicCount: count(TopicStatus.developing),
      ),
      MasteryLegendItem(
        label: 'Weak',
        color: StatusStyle.of(TopicStatus.weak).accent,
        topicCount: count(TopicStatus.weak) + count(TopicStatus.veryWeak),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return InsightsPanel(
      child: Row(
        children: [
          _MasteryRing(percent: data.overall.percent),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              children: [
                for (final item in legendFor(data)) _LegendRow(item: item),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryRing extends StatelessWidget {
  const _MasteryRing({required this.percent});

  final double? percent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'Mastery ${InsightsText.percentSpoken(percent)}',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 116,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: percent == null ? 0 : (percent! / 100).clamp(0.0, 1.0),
              strokeWidth: 12,
              strokeCap: StrokeCap.round,
              backgroundColor: InsightsColors.line(context),
              color: AppColors.primary,
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    percent == null ? '—' : '${percent!.round()}%',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: InsightsColors.text(context),
                    ),
                  ),
                  Text(
                    'mastery',
                    style: textTheme.bodySmall?.copyWith(
                      color: InsightsColors.mutedText(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.item});

  final MasteryLegendItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final topics = '${item.topicCount} topic${item.topicCount == 1 ? '' : 's'}';
    return Semantics(
      container: true,
      label: '${item.label}: $topics',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: item.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(item.label, style: textTheme.bodyMedium)),
            Text(
              topics,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
