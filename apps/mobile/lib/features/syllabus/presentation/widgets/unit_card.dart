import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/syllabus_models.dart';
import 'status_pill.dart';

export 'status_pill.dart';

/// The icon in the teal tile, by unit number (A/L Biology has 10 units).
IconData unitIcon(int order) => switch (order) {
  1 => Icons.biotech_outlined,
  2 => Icons.auto_awesome_outlined,
  3 => Icons.eco_outlined,
  4 => Icons.local_florist_outlined,
  5 => Icons.track_changes,
  6 => Icons.auto_awesome_outlined,
  7 => Icons.coronavirus_outlined,
  8 => Icons.science_outlined,
  9 => Icons.public,
  10 => Icons.agriculture_outlined,
  _ => Icons.menu_book_outlined,
};

/// One unit on the Learn screen: icon tile, "UNIT 1", title, status pill,
/// topic count and the mastery ring.
class UnitCard extends StatelessWidget {
  const UnitCard({super.key, required this.unit, required this.onTap});

  final UnitProgress unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mastery = masteryFraction(unit.mastery).clamp(0.0, 1.0);
    final topics = '${unit.topicCount} topic${unit.topicCount == 1 ? '' : 's'}';

    return Semantics(
      button: true,
      label:
          'Unit ${unit.order}, ${unit.title}, ${unit.status.label}, $topics, '
          '${Formatters.percent(mastery)} mastery',
      child: ExcludeSemantics(
        child: Material(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            side: const BorderSide(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md + 2),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.secondarySoft,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      unitIcon(unit.order),
                      size: 20,
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
                            color: AppColors.muted,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          unit.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        Row(
                          children: [
                            StatusPill.unit(unit.status),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Text(
                                topics,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  MasteryRing(
                    value: mastery,
                    size: 44,
                    strokeWidth: 4,
                    color: unit.status.ringColor,
                    labelStyle: textTheme.labelSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
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

/// Grey placeholder cards while the units load.
class LearnSkeleton extends StatelessWidget {
  const LearnSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading units',
      child: ExcludeSemantics(
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: 6,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (_, _) =>
              const SkeletonBox(height: 76, radius: AppSpacing.radiusLg),
        ),
      ),
    );
  }
}
