import 'package:flutter/material.dart';

import '../api/api_exception.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/error_messages.dart';

/// A red box with an error message and an optional "Retry" button.
///
/// When the message is [ApiException.networkMessage] (no connection) it
/// shows a calm "You're offline" state instead of an error.
///
/// ```dart
/// error: (e, _) => ErrorBanner(message: '$e', onRetry: () => ref.invalidate(p)),
/// ```
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  bool get _offline =>
      message == ErrorMessages.offline ||
      message == ApiException.networkMessage;

  @override
  Widget build(BuildContext context) {
    if (_offline) {
      return Semantics(
        liveRegion: true,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.muted),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You're offline",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      'This needs the internet. Saved notes and the '
                      'syllabus still open offline.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              if (onRetry != null)
                TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
