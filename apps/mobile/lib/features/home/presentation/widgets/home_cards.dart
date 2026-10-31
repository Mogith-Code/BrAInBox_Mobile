import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/home_models.dart';

/// Date, "Good evening, Nethmi 👋", the initials avatar and the two chips.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.summary,
    required this.now,
    required this.onAvatarTap,
  });

  final HomeSummary summary;
  final DateTime now;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = summary.greetingName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formatters.weekdayDayMonth(now),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Semantics(
                    header: true,
                    child: Text(
                      '${greetingFor(now)}${name.isEmpty ? '' : ', $name'} 👋',
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Semantics(
              button: true,
              label: 'Open settings',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onAvatarTap,
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4CC),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2.5),
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      summary.initials,
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            AppChip(
              emoji: '🔥',
              label: '${summary.streakDays}-day streak',
              tone: AppChipTone.streak,
            ),
            if (summary.daysToExam != null)
              AppChip(
                icon: Icons.schedule,
                label: '${summary.daysToExam} days to A/L',
              ),
          ],
        ),
      ],
    );
  }
}

/// The gradient "◎ NEXT BEST ACTION" card.
class NextBestActionCard extends StatelessWidget {
  const NextBestActionCard({
    super.key,
    required this.action,
    required this.onStart,
  });

  final NextBestAction action;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl - 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.track_changes,
                size: 16,
                color: AppColors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  'NEXT BEST ACTION',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (action.aiGenerated) const AiBadge(onDark: true),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            action.title,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (action.reason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              action.reason,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(action.buttonLabel),
          ),
        ],
      ),
    );
  }
}

/// White rounded card used by "Today's plan" and the mastery card.
class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// "Today's plan · 1/3" with tick circles.
class TodaysPlanCard extends StatelessWidget {
  const TodaysPlanCard({super.key, required this.plan, required this.onToggle});

  final TodaysPlan plan;
  final ValueChanged<PlanItem> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's plan",
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${plan.done}/${plan.total}',
                style: textTheme.labelMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final item in plan.items)
            _PlanRow(item: item, onTap: () => onToggle(item)),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.item, required this.onTap});

  final PlanItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = [
      if (item.minutes > 0) '${item.minutes} min',
      if (item.unitLabel.isNotEmpty) item.unitLabel,
    ].join(' · ');
    return Semantics(
      checked: item.done,
      button: true,
      label: '${item.title}, $subtitle',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.done ? AppColors.success : AppColors.white,
                      border: Border.all(
                        color: item.done ? AppColors.success : AppColors.border,
                        width: 2,
                      ),
                    ),
                    child: item.done
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: textTheme.bodyMedium?.copyWith(
                            color: item.done ? AppColors.muted : AppColors.ink,
                            decoration: item.done
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppColors.muted,
                          ),
                        ),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: textTheme.labelSmall?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                      ],
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

/// "62% · Overall mastery · +4% wk"
class MasteryCard extends StatelessWidget {
  const MasteryCard({
    super.key,
    required this.mastery,
    required this.changeWeek,
  });

  /// 0-1
  final double mastery;

  /// Percentage points this week (negative = red).
  final double changeWeek;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final change = changeWeek.round();
    final changeText = '${change >= 0 ? '+' : ''}$change% wk';
    return _WhiteCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MasteryRing(
            value: mastery,
            size: 76,
            strokeWidth: 8,
            color: AppColors.primary,
            labelStyle: textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Overall\nmastery',
            textAlign: TextAlign.center,
            style: textTheme.labelMedium?.copyWith(color: AppColors.muted),
          ),
          Text(
            changeText,
            style: textTheme.labelMedium?.copyWith(
              color: change < 0 ? AppColors.error : AppColors.successDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// One "Continue learning" card.
class ContinueCard extends StatelessWidget {
  const ContinueCard({
    super.key,
    required this.item,
    required this.tint,
    required this.onTap,
  });

  final ContinueItem item;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 170,
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
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 76,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: MasteryRing(
                    value: asFraction(item.progress),
                    size: 48,
                    strokeWidth: 5,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.unitCode.isNotEmpty)
                  Text(
                    Formatters.unitLabel(item.unitCode),
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grey blocks shown while the dashboard loads.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading your dashboard',
      child: const ExcludeSemantics(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 120, height: 14),
              SizedBox(height: AppSpacing.sm),
              SkeletonBox(width: 240, height: 28),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(width: 220, height: 30, radius: 15),
              SizedBox(height: AppSpacing.lg),
              SkeletonBox(height: 170, radius: AppSpacing.radiusXl),
              SizedBox(height: AppSpacing.md),
              SkeletonBox(height: 190, radius: AppSpacing.radiusLg),
            ],
          ),
        ),
      ),
    );
  }
}
