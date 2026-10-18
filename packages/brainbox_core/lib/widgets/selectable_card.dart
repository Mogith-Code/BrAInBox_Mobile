import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A tappable card with selected / disabled states (stream, subject,
/// preferred time...).
///
/// Selected = indigo border on a soft indigo background. Disabled = faded,
/// not tappable (e.g. "Coming soon" subjects).
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.child,
    required this.selected,
    this.onTap,
    this.enabled = true,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.selectedColor = AppColors.primarySoft,
    this.semanticLabel,
  });

  final Widget child;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;
  final EdgeInsetsGeometry padding;

  /// Background when selected (some cards stay white when selected).
  final Color selectedColor;

  /// Read by screen readers instead of the child's text.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusLg);
    final Color borderColor = selected ? AppColors.primary : AppColors.border;
    final Color background = !enabled
        ? AppColors.background
        : selected
        ? selectedColor
        : AppColors.white;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.75,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: borderColor, width: selected ? 1.8 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small grey "⏱ Coming soon" pill for disabled options.
class ComingSoonChip extends StatelessWidget {
  const ComingSoonChip({super.key, this.label = 'Coming soon'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 13, color: AppColors.muted),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
