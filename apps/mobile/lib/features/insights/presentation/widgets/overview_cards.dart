import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/insights_models.dart';
import 'insights_ring.dart';
import 'insights_style.dart';
import 'status_chip.dart';

/// Big card at the top: overall percent, grade and counts.
class OverallHeroCard extends StatelessWidget {
  const OverallHeroCard({
    super.key,
    required this.overall,
    required this.attemptsAnalysed,
    required this.singleAttempt,
  });

  final OverallResult overall;
  final int attemptsAnalysed;
  final bool singleAttempt;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = InsightsColors.mutedText(context);
    final source = singleAttempt
        ? 'From this attempt'
        : 'From $attemptsAnalysed attempt${attemptsAnalysed == 1 ? '' : 's'}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            InsightsRing(
              percent: overall.percent,
              size: 104,
              strokeWidth: 10,
              labelStyle: textTheme.headlineSmall,
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (overall.grade != null)
                    Semantics(
                      container: true,
                      label: 'Grade ${overall.grade}, ${overall.gradeLabel}',
                      excludeSemantics: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(overall.grade!, style: textTheme.headlineMedium),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              overall.gradeLabel ?? '',
                              style: textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text('Not attempted', style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${overall.correct} correct of ${overall.attempted} '
                    'attempted',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${overall.unanswered} unanswered · $source',
                    style: textTheme.bodySmall?.copyWith(color: muted),
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

/// Number of topics per status, as chips.
class StatusSummary extends StatelessWidget {
  const StatusSummary({super.key, required this.counts});

  final Map<TopicStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final statuses = TopicStatus.values.where((s) => (counts[s] ?? 0) > 0);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final status in statuses)
          StatusChip(status: status, count: counts[status]),
      ],
    );
  }
}

/// "Strongest" and "Weakest" tiles. A tile is hidden when it has no topic.
class StrongestWeakestTiles extends StatelessWidget {
  const StrongestWeakestTiles({
    super.key,
    required this.strongest,
    required this.weakest,
    required this.onOpen,
  });

  final TopicResult? strongest;
  final TopicResult? weakest;
  final ValueChanged<TopicResult> onOpen;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      if (strongest != null)
        _HighlightTile(
          title: 'Strongest',
          icon: Icons.emoji_events_outlined,
          topic: strongest!,
          onTap: () => onOpen(strongest!),
        ),
      if (weakest != null)
        _HighlightTile(
          title: 'Weakest',
          icon: Icons.flag_outlined,
          topic: weakest!,
          onTap: () => onOpen(weakest!),
        ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < tiles.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.md),
              Expanded(child: tiles[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  const _HighlightTile({
    required this.title,
    required this.icon,
    required this.topic,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final TopicResult topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = StatusStyle.of(topic.status);
    return Semantics(
      button: true,
      label:
          '$title: ${topic.topic}, ${InsightsText.percentSpoken(topic.percent)}, '
          '${style.label}',
      excludeSemantics: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            color: style.fill(context),
            padding: AppSpacing.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: InsightsColors.text(context)),
                    const SizedBox(width: AppSpacing.xs),
                    Text(title, style: textTheme.labelLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  topic.topic,
                  style: textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    StatusIcon(status: topic.status, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '${InsightsText.percent(topic.percent)} · ${style.label}',
                        style: textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable topic row: ring, name, unit, status chip.
///
/// Used instead of `TopicCard` because every status must show colour, icon
/// and label, and TopicCard has no place for the status icon.
class InsightTopicTile extends StatelessWidget {
  const InsightTopicTile({
    super.key,
    required this.topic,
    required this.minQuestionsPerTopic,
    required this.onTap,
  });

  final TopicResult topic;
  final int minQuestionsPerTopic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = InsightsText.topicSubtitle(topic);
    final needed = topic.questionsNeeded(minQuestionsPerTopic);
    final style = StatusStyle.of(topic.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: true,
        label: [
          topic.topic,
          InsightsText.percentSpoken(topic.percent),
          style.label,
          if (!topic.reliable && needed > 0) InsightsText.needsMore(needed),
        ].join(', '),
        excludeSemantics: true,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                children: [
                  InsightsRing(
                    percent: topic.percent,
                    size: 48,
                    strokeWidth: 5,
                    faded: !topic.reliable,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(topic.topic, style: textTheme.titleSmall),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            subtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: InsightsColors.mutedText(context),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusChip(status: topic.status),
                            if (!topic.reliable && needed > 0)
                              Text(
                                InsightsText.needsMore(needed),
                                style: textTheme.bodySmall?.copyWith(
                                  color: InsightsColors.mutedText(context),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: InsightsColors.mutedText(context),
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

/// Collapsed list of topics without enough answers yet.
class InsufficientDataSection extends StatelessWidget {
  const InsufficientDataSection({
    super.key,
    required this.topics,
    required this.minQuestionsPerTopic,
    required this.onOpen,
  });

  final List<TopicResult> topics;
  final int minQuestionsPerTopic;
  final ValueChanged<TopicResult> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Theme(
          // ExpansionTile draws its own dividers; the card has a border.
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: const StatusIcon(status: TopicStatus.insufficientData),
            title: Text(
              'Not enough data yet (${topics.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: Text(
              'Answer at least $minQuestionsPerTopic questions per topic.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: InsightsColors.mutedText(context),
              ),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            children: [
              for (final topic in topics)
                InsightTopicTile(
                  topic: topic,
                  minQuestionsPerTopic: minQuestionsPerTopic,
                  onTap: () => onOpen(topic),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grade boundaries, built from `grade_bands` (nothing hard-coded).
class GradeBandLegend extends StatelessWidget {
  const GradeBandLegend({super.key, required this.bands});

  final List<GradeBand> bands;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          children: [
            for (final band in bands)
              Semantics(
                container: true,
                label:
                    'Grade ${band.grade}, ${band.label}, '
                    '${InsightsText.bandRange(band)}',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      _GradeBadge(band: band),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(band.label, style: textTheme.bodyMedium),
                      ),
                      Text(
                        InsightsText.bandRange(band),
                        style: textTheme.bodySmall?.copyWith(
                          color: InsightsColors.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.band});

  final GradeBand band;

  @override
  Widget build(BuildContext context) {
    final color = InsightsColors.forPercent(band.minPercent);
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color),
      ),
      child: Text(
        band.grade,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: InsightsColors.text(context),
        ),
      ),
    );
  }
}

/// The "Formative feedback" info box. Always shows the backend's `note`.
class FormativeNoteBox extends StatelessWidget {
  const FormativeNoteBox({super.key, required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final accent = InsightsColors.infoAccent(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: InsightsColors.isDark(context) ? 0.22 : 0.07,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Formative feedback', style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(note, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
