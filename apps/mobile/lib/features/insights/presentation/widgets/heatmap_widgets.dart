import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/insights_models.dart';
import 'insights_ring.dart';
import 'insights_style.dart';
import 'status_chip.dart';

/// One row of the mastery map: a unit and its topics.
typedef MasteryMapRow = ({String label, String unit, List<TopicResult> topics});

/// The map rows in syllabus order ("1 Introduction to Biology",
/// "2 Chemical & Cellular…"), each with its topics in topic-number order.
///
/// The unit number comes from the topic numbers the backend sends ("6.2" ->
/// unit 6). Units or topics without a number keep the backend's order, last.
/// Only the order changes: every value is shown as the backend sent it.
List<MasteryMapRow> masteryMapRows(TopicInsights data) {
  final rows = [
    for (final unit in data.unitsInOrder)
      (unit: unit, topics: [...data.topicsInUnit(unit)]..sort(_byNumber)),
  ];
  int? unitNumber(List<TopicResult> topics) {
    for (final topic in topics) {
      final first = _numberParts(topic.topicNumber);
      if (first.isNotEmpty) return first.first;
    }
    return null;
  }

  final numbered = [
    for (final row in rows) (number: unitNumber(row.topics), row: row),
  ];
  // Stable sort: numbered units first, by number; the rest as they came.
  final ordered = [
    ...(numbered.where((r) => r.number != null).toList()
      ..sort((a, b) => a.number!.compareTo(b.number!))),
    ...numbered.where((r) => r.number == null),
  ];
  return [
    for (final r in ordered)
      (
        label: r.number == null ? r.row.unit : '${r.number} ${r.row.unit}',
        unit: r.row.unit,
        topics: r.row.topics,
      ),
  ];
}

/// "6.10" -> [6, 10]. Empty when there is no usable number.
List<int> _numberParts(String? number) {
  if (number == null || number.trim().isEmpty) return const [];
  final parts = [for (final p in number.split('.')) int.tryParse(p.trim())];
  return parts.contains(null) ? const [] : parts.cast<int>();
}

/// Topic-number order ("6.2" before "6.10"); topics without one go last.
int _byNumber(TopicResult a, TopicResult b) {
  final x = _numberParts(a.topicNumber);
  final y = _numberParts(b.topicNumber);
  if (x.isEmpty || y.isEmpty) return (x.isEmpty ? 1 : 0) - (y.isEmpty ? 1 : 0);
  for (var i = 0; i < x.length && i < y.length; i++) {
    if (x[i] != y[i]) return x[i].compareTo(y[i]);
  }
  return x.length.compareTo(y.length);
}

/// "Weak ▢▢▢▢▢ Mastered": the cell colours from weakest to strongest.
class MasteryMapKey extends StatelessWidget {
  const MasteryMapKey({super.key});

  static const _scale = [
    TopicStatus.veryWeak,
    TopicStatus.weak,
    TopicStatus.developing,
    TopicStatus.good,
    TopicStatus.strong,
  ];

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: InsightsColors.mutedText(context));
    return Semantics(
      label:
          'Colour key: red is weak, amber is improving, teal is good, '
          'green is mastered',
      excludeSemantics: true,
      child: Row(
        children: [
          Text('Weak', style: style),
          const SizedBox(width: AppSpacing.sm),
          for (final status in _scale)
            Expanded(
              child: Container(
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: StatusStyle.of(status).heatFill(context),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          Text('Mastered', style: style),
        ],
      ),
    );
  }
}

/// A unit label and its topic cells.
class MasteryMapRowView extends StatelessWidget {
  const MasteryMapRowView({
    super.key,
    required this.row,
    required this.selectedKey,
    required this.onTap,
  });

  final MasteryMapRow row;
  final String? selectedKey;
  final ValueChanged<TopicResult> onTap;

  static const double labelWidth = 84;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            height: HeatmapCell.size,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                row.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: InsightsColors.text(context),
                ),
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final topic in row.topics)
                  HeatmapCell(
                    topic: topic,
                    selected: topic.key == selectedKey,
                    onTap: () => onTap(topic),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One topic on the mastery map: its percent on the status colour.
class HeatmapCell extends StatelessWidget {
  const HeatmapCell({
    super.key,
    required this.topic,
    required this.onTap,
    this.selected = false,
  });

  final TopicResult topic;
  final VoidCallback onTap;

  /// Outlined in the brand colour while its sheet is open.
  final bool selected;

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(topic.status);
    final border = selected
        ? const BorderSide(color: AppColors.primary, width: 2.5)
        : style.neutral
        ? BorderSide(color: InsightsColors.line(context))
        : BorderSide.none;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${topic.topic}, ${InsightsText.percentSpoken(topic.percent)}, '
          '${style.label.toLowerCase()}',
      excludeSemantics: true,
      child: Material(
        color: style.heatFill(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
          side: border,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Center(
              child: Opacity(
                // Not enough answers yet: shown, but faded.
                opacity: topic.reliable ? 1 : 0.55,
                child: Text(
                  topic.percent == null ? '—' : '${topic.percent!.round()}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: InsightsColors.text(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for a tapped cell: ring, unit, topic, status, buttons.
class TopicSheet extends StatelessWidget {
  const TopicSheet({
    super.key,
    required this.topic,
    required this.unitLabel,
    required this.minQuestionsPerTopic,
    required this.onOpenTopic,
    required this.onPractice,
  });

  final TopicResult topic;

  /// "Unit 6 Genetics" (from the map row).
  final String unitLabel;
  final int minQuestionsPerTopic;
  final VoidCallback onOpenTopic;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final needed = topic.questionsNeeded(minQuestionsPerTopic);
    final muted = InsightsColors.mutedText(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InsightsRing(
                  percent: topic.percent,
                  size: 72,
                  strokeWidth: 7,
                  faded: !topic.reliable,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unitLabel,
                        style: textTheme.bodySmall?.copyWith(color: muted),
                      ),
                      Text(
                        topic.topic,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusChip(status: topic.status),
                          Text(
                            '${topic.attempted} question'
                            '${topic.attempted == 1 ? '' : 's'} tried',
                            style: textTheme.bodyMedium?.copyWith(color: muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!topic.reliable && needed > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                InsightsText.needsMore(needed),
                style: textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Open topic',
                    variant: AppButtonVariant.secondary,
                    onPressed: onOpenTopic,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(label: 'Practice', onPressed: onPractice),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
