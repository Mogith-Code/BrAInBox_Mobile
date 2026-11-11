import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/network_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Shows "You're offline. Saved notes still work." above [child] while the
/// backend can't be reached (Figma F6). Retry asks the server again.
///
/// ```dart
/// OfflineBanner(onRetry: () => api.get('/health'), child: page)
/// ```
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child, required this.onRetry});

  final Widget child;

  /// Any request: a reply flips the banner off again by itself.
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(networkStatusProvider);
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: online
              ? const SizedBox(width: double.infinity)
              : Semantics(
                  liveRegion: true,
                  child: Material(
                    color: AppColors.ink,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.sm,
                          AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.wifi_off,
                              color: AppColors.amber,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Expanded(
                              child: Text(
                                "You're offline. Saved notes still work.",
                                style: TextStyle(color: AppColors.white),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.white,
                                backgroundColor: AppColors.darkSurface,
                              ),
                              onPressed: () async {
                                try {
                                  await onRetry();
                                } catch (_) {
                                  // Still offline: the banner stays.
                                }
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
