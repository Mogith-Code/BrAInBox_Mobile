import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Colour sets for [AppChip].
enum AppChipTone {
  /// Amber, e.g. "🔥 12-day streak".
  streak(AppColors.streakSoft, AppColors.streakDark, AppColors.warningBorder),

  /// Indigo, e.g. "⏱ 287 days to A/L".
  info(AppColors.primarySoft, AppColors.primary, AppColors.primaryLight),

  /// Green, e.g. "Done".
  success(AppColors.successSoft, AppColors.successDark, AppColors.mint),

  /// Grey.
  neutral(AppColors.surfaceMuted, AppColors.muted, AppColors.border);

  const AppChipTone(this.background, this.foreground, this.border);

  final Color background;
  final Color foreground;
  final Color border;
}

/// A rounded pill with an optional icon (or emoji) and a short label.
///
/// ```dart
/// const AppChip(emoji: '🔥', label: '12-day streak', tone: AppChipTone.streak)
/// const AppChip(icon: Icons.schedule, label: '287 days to A/L')
/// ```
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.emoji,
    this.tone = AppChipTone.info,
  });

  final String label;
  final IconData? icon;
  final String? emoji;
  final AppChipTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: tone.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            ExcludeSemantics(
              child: Text(emoji!, style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: AppSpacing.xs + 2),
          ] else if (icon != null) ...[
            Icon(icon, size: 15, color: tone.foreground),
            const SizedBox(width: AppSpacing.xs + 2),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
