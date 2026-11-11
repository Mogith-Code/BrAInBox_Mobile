import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// The full-screen "the AI couldn't do it" state (Figma F7): a warning
/// icon, what went wrong, "Try again", "Report a problem" and the error code
/// (so support can find it).
///
/// ```dart
/// AiErrorState(
///   title: "We couldn't generate your notes",
///   message: 'The AI service took too long to respond. Nothing was lost.',
///   errorCode: 'AI_SERVICE_UNAVAILABLE',
///   onRetry: retry,
/// )
/// ```
class AiErrorState extends StatelessWidget {
  const AiErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.onReport,
    this.errorCode,
    this.retryLabel = 'Try again',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onReport;
  final String? errorCode;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.errorSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: retryLabel,
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
            if (onReport != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: onReport,
                child: const Text('Report a problem'),
              ),
            ],
            if (errorCode != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Error code: $errorCode',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
