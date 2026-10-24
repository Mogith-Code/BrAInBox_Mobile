import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Amber "AI-generated" chip.
///
/// RULE: show this on EVERY piece of AI-generated content (notes, visuals,
/// questions, feedback, next best action) so students know to double-check
/// it.
///
/// - Light backgrounds: soft amber chip with amber text (default).
/// - Dark / gradient backgrounds: `onDark: true` gives a solid amber chip.
/// - Other labels in the same style, e.g. `AiBadge(label: 'Adaptive')`.
class AiBadge extends StatelessWidget {
  const AiBadge({super.key, this.label = 'AI-generated', this.onDark = false});

  final String label;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final foreground = onDark ? AppColors.ink : AppColors.warningDark;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: onDark ? AppColors.amber : AppColors.warningSoft,
          border: onDark ? null : Border.all(color: AppColors.warningBorder),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 13, color: foreground),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
