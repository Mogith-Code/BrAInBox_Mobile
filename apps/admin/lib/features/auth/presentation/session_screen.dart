import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/admin_page.dart';
import '../application/admin_session.dart';
import '../application/auth_controller.dart';
import 'widgets/gate_card.dart';

/// Shown while we check who is signed in (`GET /auth/me`), and when that
/// check failed (Retry / Log out). Admin pages are never built before the
/// check is done, so they never send a request without a token.
///
/// Route: `/session`.
class SessionScreen extends ConsumerWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(adminSessionProvider);
    final textTheme = Theme.of(context).textTheme;

    if (session.status != AdminSessionStatus.failed) {
      return GateCard(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            Text('Checking your account…', style: textTheme.bodyMedium),
          ],
        ),
      );
    }
    return GateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Couldn't check your account",
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ErrorBanner(
            message: adminErrorMessage(session.error),
            onRetry: () => ref.invalidate(currentUserProvider),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Log out',
            icon: Icons.logout,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
