import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/password_strength.dart';

/// Four bars under a password field, plus "Good · Add a symbol to make it
/// stronger". Pass the current password text.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  static Color colorFor(PasswordStrength strength) => switch (strength) {
    PasswordStrength.empty => AppColors.border,
    PasswordStrength.weak => AppColors.error,
    PasswordStrength.fair => AppColors.warning,
    PasswordStrength.good => AppColors.secondary,
    PasswordStrength.strong => AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    final strength = PasswordStrength.of(password);
    final hint = PasswordStrength.hintFor(password);
    final color = colorFor(strength);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      label: strength == PasswordStrength.empty
          ? hint
          : 'Password strength ${strength.label}. $hint',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i < strength.score ? color : AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Row(
              children: [
                if (strength != PasswordStrength.empty)
                  Text(
                    strength.label,
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    hint,
                    textAlign: TextAlign.end,
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
