import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/insights_controller.dart';
import '../../domain/unit_insights.dart';
import 'insights_style.dart';
import 'mastery_card.dart';

/// "Unit mastery": one bar per unit, Unit 1 first.
///
/// Data: `GET /insights/units`. Loads on its own, so a slow or failed
/// request never hides the rest of the overview.
class UnitMasteryCard extends ConsumerWidget {
  const UnitMasteryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(unitInsightsControllerProvider);
    final data = state.value;
    return InsightsPanel(
      title: 'Unit mastery',
      child: switch (data) {
        null when state.hasError => _CardError(
          message: '${state.error}',
          onRetry: () =>
              ref.read(unitInsightsControllerProvider.notifier).refresh(),
        ),
        null => const _CardLoading(),
        UnitInsights(assessedUnits: 0) => Text(
          'Finish a quiz to see how well you know each unit.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: InsightsColors.mutedText(context),
          ),
        ),
        _ => Column(
          children: [for (final unit in data.units) UnitMasteryRow(unit: unit)],
        ),
      },
    );
  }
}

/// "1. Introduction to Biology  ████░░  88%".
class UnitMasteryRow extends StatelessWidget {
  const UnitMasteryRow({super.key, required this.unit});

  final UnitMastery unit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = StatusStyle.of(unit.status);
    final mastery = unit.mastery;
    final name = '${unit.number}. ${unit.title}';
    return Semantics(
      container: true,
      label:
          'Unit $name, '
          '${mastery == null ? 'not assessed' : '$mastery percent, ${style.label.toLowerCase()}'}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                child: LinearProgressIndicator(
                  value: mastery == null ? 0 : (mastery / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: InsightsColors.line(context),
                  color: style.accent,
                ),
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                mastery == null ? '—' : '$mastery%',
                textAlign: TextAlign.end,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: mastery == null
                      ? InsightsColors.mutedText(context)
                      : InsightsColors.text(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardLoading extends StatelessWidget {
  const _CardLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading unit mastery',
      child: Column(
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              height: 14,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: InsightsColors.line(context),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardError extends StatelessWidget {
  const _CardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final muted = InsightsColors.mutedText(context);
    return Row(
      children: [
        Icon(Icons.error_outline_rounded, color: muted),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: muted),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}
