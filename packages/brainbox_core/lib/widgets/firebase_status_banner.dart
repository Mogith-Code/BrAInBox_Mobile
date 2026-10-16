import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/firebase_setup.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// In DEBUG builds only: shows an amber strip at the top of the app when
/// Firebase is not configured, so nobody wonders why sign-in does nothing.
///
/// Used in `MaterialApp.builder` in both apps.
class FirebaseStatusBanner extends StatelessWidget {
  const FirebaseStatusBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || FirebaseSetup.isReady) return child;

    return Column(
      children: [
        Material(
          color: AppColors.amber,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.ink),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Firebase not configured - sign-in is disabled. '
                      'Run `flutterfire configure` (see README).',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          // The strip already handled the status bar.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
