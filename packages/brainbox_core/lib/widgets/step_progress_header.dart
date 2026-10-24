import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Back arrow + one bar per step + "1/3" (profile setup).
class StepProgressHeader extends StatelessWidget {
  const StepProgressHeader({
    super.key,
    required this.step,
    required this.total,
    this.onBack,
  });

  /// 1-based current step.
  final int step;
  final int total;

  /// Null hides the back arrow (keeps the space so bars don't jump).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: 48,
          child: onBack == null
              ? null
              : IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Icons.chevron_left, size: 28),
                  color: AppColors.ink,
                ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Semantics(
            label: 'Step $step of $total',
            child: ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 1; i <= total; i++) ...[
                    if (i > 1) const SizedBox(width: AppSpacing.xs + 2),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 5,
                        decoration: BoxDecoration(
                          color: i <= step
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        ExcludeSemantics(
          child: Text(
            '$step/$total',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
    );
  }
}
