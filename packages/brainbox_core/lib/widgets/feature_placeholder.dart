import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// TEMPORARY body for screens that are not built yet.
///
/// Shows the screen title, who owns it, "Coming soon" and one button.
/// When you build the real screen, delete the `FeaturePlaceholder` from it.
/// Once no screen uses it any more, delete this file too.
class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    super.key,
    required this.title,
    required this.owner,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String owner;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_rounded,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Owner: $owner',
                style: textTheme.titleSmall?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Coming soon', style: textTheme.titleMedium),
              if (description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description!,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
