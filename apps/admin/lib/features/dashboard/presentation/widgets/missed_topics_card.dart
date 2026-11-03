import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/dashboard_models.dart';
import 'dashboard_card.dart';

/// "Most-missed topics - this week": a table of the topics students get
/// wrong most often, with the top misconception for each.
class MissedTopicsCard extends StatelessWidget {
  const MissedTopicsCard({
    super.key,
    required this.topics,
    required this.attempts,
    required this.onCreateSet,
  });

  final List<MissedTopic> topics;

  /// How many attempts the numbers are based on.
  final int attempts;

  /// "Create set" on a row.
  final ValueChanged<MissedTopic> onCreateSet;

  /// Below this width the table scrolls sideways instead of squashing.
  static const double _minTableWidth = 860;

  /// Miss rates at or above this are shown in red, below it in amber.
  static const double _highMissRate = 0.55;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DashboardCard(
      title: 'Most-missed topics · this week',
      trailing: attempts > 0
          ? Text(
              'Based on ${Formatters.thousands(attempts)} attempts',
              style: textTheme.labelSmall?.copyWith(color: AppColors.muted),
            )
          : null,
      child: topics.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Text(
                'No attempts this week yet.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final table = Column(
                  children: [
                    const _HeaderRow(),
                    for (final topic in topics) ...[
                      const Divider(height: 1),
                      _TopicRow(
                        topic: topic,
                        onCreateSet: () => onCreateSet(topic),
                      ),
                    ],
                  ],
                );
                if (constraints.maxWidth >= _minTableWidth) return table;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(width: _minTableWidth, child: table),
                );
              },
            ),
    );
  }
}

/// Column widths (flex) shared by the header and the rows.
const _topicFlex = 3;
const _unitFlex = 2;
const _missRateFlex = 3;
const _attemptsFlex = 1;
const _misconceptionFlex = 4;
const double _actionWidth = 96;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: AppColors.muted,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
    );
    Widget cell(String text, int flex) => Expanded(
      flex: flex,
      child: Text(text, style: style),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          cell('TOPIC', _topicFlex),
          cell('UNIT', _unitFlex),
          cell('MISS RATE', _missRateFlex),
          cell('ATTEMPTS', _attemptsFlex),
          cell('TOP MISCONCEPTION', _misconceptionFlex),
          const SizedBox(width: _actionWidth),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  const _TopicRow({required this.topic, required this.onCreateSet});

  final MissedTopic topic;
  final VoidCallback onCreateSet;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final barColor = topic.missRate >= MissedTopicsCard._highMissRate
        ? AppColors.error
        : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: _topicFlex,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Text(topic.topic, style: textTheme.labelLarge),
            ),
          ),
          Expanded(
            flex: _unitFlex,
            child: Text(
              topic.unit,
              style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ),
          Expanded(
            flex: _missRateFlex,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: ExcludeSemantics(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                        child: LinearProgressIndicator(
                          value: topic.missRate.clamp(0.0, 1.0),
                          minHeight: 6,
                          color: barColor,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 40,
                    child: Text(
                      Formatters.percent(topic.missRate),
                      textAlign: TextAlign.right,
                      style: textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: _attemptsFlex,
            child: Text(
              Formatters.thousands(topic.attempts),
              style: textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: _misconceptionFlex,
            child: Align(
              alignment: Alignment.centerLeft,
              child: topic.topMisconception.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Text(
                        topic.topMisconception,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(
            width: _actionWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCreateSet,
                child: Text(
                  'Create set',
                  semanticsLabel: 'Create practice set for ${topic.topic}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
