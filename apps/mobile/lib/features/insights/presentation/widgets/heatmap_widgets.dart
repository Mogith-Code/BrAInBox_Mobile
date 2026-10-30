import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/insights_models.dart';
import 'insights_ring.dart';
import 'insights_style.dart';
import 'status_chip.dart';

/// One topic in the mastery map. Coloured by percent; topics without enough
/// data (or not attempted) use the neutral style with their status icon.
class HeatmapCell extends StatelessWidget {
  const HeatmapCell({super.key, required this.topic, required this.onTap});

  final TopicResult topic;
  final VoidCallback onTap;

  static const double size = 76;

  bool get _neutral =>
      topic.percent == null || StatusStyle.of(topic.status).neutral;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = StatusStyle.of(topic.status);
    final color = InsightsColors.forPercent(topic.percent);
    final isDark = InsightsColors.isDark(context);
    final fill = _neutral
        ? Colors.transparent
        : color.withValues(alpha: isDark ? 0.34 : 0.26);
    final border = _neutral
        ? InsightsColors.line(context)
        : color.withValues(alpha: 0.8);
    final shortName = (topic.topicNumber?.isNotEmpty ?? false)
        ? topic.topicNumber!
        : topic.topic;

    return Semantics(
      button: true,
      label:
          '${topic.topic}, ${InsightsText.percentSpoken(topic.percent)}, '
          '${style.label.toLowerCase()}',
      excludeSemantics: true,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shortName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: InsightsColors.text(context),
                          ),
                        ),
                      ),
                      StatusIcon(status: topic.status, size: 16),
                    ],
                  ),
                  const Spacer(),
                  Opacity(
                    opacity: topic.reliable ? 1 : 0.55,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        topic.percent == null
                            ? '—'
                            : '${topic.percent!.round()}%',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: InsightsColors.text(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Colour key for the map, built from `grade_bands`.
class HeatmapKey extends StatelessWidget {
  const HeatmapKey({super.key, required this.bands});

  final List<GradeBand> bands;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget swatch(Color? color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color?.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color ?? InsightsColors.line(context)),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: textTheme.bodySmall),
      ],
    );
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        for (final band in bands.reversed)
          swatch(
            InsightsColors.forPercent(band.minPercent),
            '${band.grade} ${InsightsText.bandRange(band)}',
          ),
        swatch(null, 'Not enough data'),
      ],
    );
  }
}

/// Bottom sheet for a tapped heatmap cell.
class TopicSheet extends StatelessWidget {
  const TopicSheet({
    super.key,
    required this.topic,
    required this.minQuestionsPerTopic,
    required this.onOpenTopic,
    required this.onPractice,
  });

  final TopicResult topic;
  final int minQuestionsPerTopic;
  final VoidCallback onOpenTopic;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = InsightsText.topicSubtitle(topic);
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
                  size: 64,
                  strokeWidth: 7,
                  faded: !topic.reliable,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(topic.topic, style: textTheme.titleMedium),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: textTheme.bodySmall?.copyWith(color: muted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(status: topic.status),
                Text(
                  '${topic.attempted} question${topic.attempted == 1 ? '' : 's'}'
                  ' tried',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            if (!topic.reliable && needed > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                InsightsText.needsMore(needed),
                style: textTheme.bodySmall?.copyWith(color: muted),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Open topic',
              icon: Icons.menu_book_rounded,
              onPressed: onOpenTopic,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Practice',
              icon: Icons.quiz_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: onPractice,
            ),
          ],
        ),
      ),
    );
  }
}
