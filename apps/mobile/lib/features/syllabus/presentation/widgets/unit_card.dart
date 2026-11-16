import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/syllabus_models.dart';
import 'learn_widgets.dart';

export 'learn_widgets.dart';

/// The icon in the teal tile, by unit number (A/L Biology has 10 units).
IconData unitIcon(int order) => switch (order) {
  1 => Icons.biotech_outlined,
  2 => Icons.bubble_chart_outlined,
  3 => Icons.account_tree_outlined,
  4 => Icons.local_florist_outlined,
  5 => Icons.pets_outlined,
  6 => Icons.auto_awesome_outlined,
  7 => Icons.coronavirus_outlined,
  8 => Icons.public,
  9 => Icons.science_outlined,
  10 => Icons.agriculture_outlined,
  _ => Icons.menu_book_outlined,
};

/// One unit on the Learn screen: teal icon tile, "UNIT n", title, mastery
/// chip, "x topics" and the progress ring.
class UnitCard extends StatelessWidget {
  const UnitCard({super.key, required this.unit, required this.onTap});

  final UnitProgress unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final topics = '${unit.topicCount} topic${unit.topicCount == 1 ? '' : 's'}';

    return Semantics(
      button: true,
      label:
          'Unit ${unit.order}, ${unit.title}, ${unit.masteryLevel.label}, '
          '$topics, ${Formatters.percent(unit.mastery)} mastery',
      child: ExcludeSemantics(
        child: LearnCard(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  unitIcon(unit.order),
                  size: 22,
                  color: AppColors.secondaryDark,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UNIT ${unit.order}',
                      style: textTheme.labelSmall?.copyWith(
                        color: context.learnMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unit.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: context.learnInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        MasteryChip(level: unit.masteryLevel),
                        Text(
                          topics,
                          style: textTheme.bodySmall?.copyWith(
                            color: context.learnMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ProgressRing(value: unit.mastery),
            ],
          ),
        ),
      ),
    );
  }
}
