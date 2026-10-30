import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/syllabus_models.dart';

/// Colours, icon and label for each [UnitStatus] pill and ring.
extension UnitStatusStyle on UnitStatus {
  String get label => switch (this) {
    UnitStatus.mastered => 'Mastered',
    UnitStatus.strong => 'Strong',
    UnitStatus.improving => 'Improving',
    UnitStatus.weak => 'Weak',
  };

  IconData get icon => switch (this) {
    UnitStatus.mastered => Icons.verified_outlined,
    UnitStatus.strong || UnitStatus.improving => Icons.trending_up,
    UnitStatus.weak => Icons.warning_amber_rounded,
  };

  Color get background => switch (this) {
    UnitStatus.mastered || UnitStatus.strong => AppColors.successSoft,
    UnitStatus.improving => AppColors.streakSoft,
    UnitStatus.weak => AppColors.errorSoft,
  };

  Color get foreground => switch (this) {
    UnitStatus.mastered || UnitStatus.strong => AppColors.successDark,
    UnitStatus.improving => AppColors.warningDark,
    UnitStatus.weak => const Color(
      0xFFB91C1C,
    ), // red-700, readable on errorSoft
  };

  Color get ringColor => switch (this) {
    UnitStatus.mastered || UnitStatus.strong => AppColors.success,
    UnitStatus.improving => AppColors.warning,
    UnitStatus.weak => const Color(0xFFEA580C), // orange-600, as in Figma
  };
}

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
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs + 2),
                        Row(
                          children: [
                            UnitStatusPill(status: unit.status),
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
                      fontWeight: FontWeight.w700,
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

/// The small "✓ Mastered" / "↗ Improving" / "⚠ Weak" pill.
class UnitStatusPill extends StatelessWidget {
  const UnitStatusPill({super.key, required this.status});

  final UnitStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: status.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
