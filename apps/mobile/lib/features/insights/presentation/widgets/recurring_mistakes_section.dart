import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/progress_providers.dart';
import '../../domain/recurring_mistakes.dart';
import '../insights_navigation.dart';

/// Icon, word and colour for a [MistakeTrend] (never colour alone).
({IconData icon, String label, Color color}) trendStyle(MistakeTrend trend) =>
    switch (trend) {
      MistakeTrend.up => (
        icon: Icons.trending_up_rounded,
        label: 'Rising',
        color: AppColors.error,
      ),
      MistakeTrend.down => (
        icon: Icons.trending_down_rounded,
        label: 'Falling',
        color: AppColors.successDark,
      ),
      MistakeTrend.same => (
        icon: Icons.trending_flat_rounded,
        label: 'Steady',
        color: AppColors.muted,
      ),
    };

/// "Recurring mistakes": misconceptions hit 3+ times in 14 days, each with
/// its trend against the 14 days before (`GET /mistakes/recurring`).
///
/// Loads on its own, so a failure never hides the journal below it.
class RecurringMistakesSection extends ConsumerWidget {
  const RecurringMistakesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recurringMistakesProvider);
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.muted);
    final data = state.value;

    final Widget body = switch (data) {
      null when state.hasError => Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.muted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text("Couldn't load recurring mistakes.", style: muted),
          ),
          TextButton(
            onPressed: () => ref.invalidate(recurringMistakesProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
      null => Semantics(
        label: 'Loading recurring mistakes',
        child: const LinearProgressIndicator(minHeight: 4),
      ),
      RecurringMistakes(items: []) => Text(
        'No repeat mistakes in the last ${data.windowDays} days. Keep it up!',
        style: muted,
      ),
      _ => Column(
        children: [
          for (final item in data.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: RecurringMistakeCard(
                item: item,
                windowDays: data.windowDays,
              ),
            ),
        ],
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Recurring mistakes',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        body,
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

/// One recurring misconception with its count and trend.
class RecurringMistakeCard extends StatelessWidget {
  const RecurringMistakeCard({
    super.key,
    required this.item,
    required this.windowDays,
  });

  final RecurringMistake item;
  final int windowDays;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trend = trendStyle(item.trend);
    final where = [?item.topic, ?item.concept].join(' · ');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Semantics(
                  container: true,
                  label: 'Trend: ${trend.label.toLowerCase()}',
                  excludeSemantics: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trend.icon, size: 18, color: trend.color),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        trend.label,
                        style: textTheme.labelMedium?.copyWith(
                          color: trend.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (where.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                where,
                style: textTheme.labelSmall?.copyWith(color: AppColors.muted),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${item.count}× in the last $windowDays days '
              '(${item.previousCount}× the $windowDays days before)',
              style: textTheme.bodySmall?.copyWith(color: AppColors.ink),
            ),
            if (item.correction != null && item.correction!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.correction!,
                style: textTheme.bodySmall?.copyWith(color: AppColors.primary),
              ),
            ],
            if (item.topicId != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () =>
                      InsightsNav.practiseTopic(context, item.topicId),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Practise topic'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
