import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

/// The horizontal BrAInBox logo with an "ADMIN" pill next to it.
///
/// Used in the sidebar, on the login page's gradient panel ([onDark] = true)
/// and above the login form on narrow screens.
class AdminLogo extends StatelessWidget {
  const AdminLogo({super.key, this.onDark = false, this.size = 32});

  final bool onDark;

  /// Height of the logo icon.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(variant: AppLogoVariant.horizontal, size: size, onDark: onDark),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: onDark
                ? AppColors.white.withValues(alpha: 0.2)
                : AppColors.ink,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
          ),
          child: Text(
            'ADMIN',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
