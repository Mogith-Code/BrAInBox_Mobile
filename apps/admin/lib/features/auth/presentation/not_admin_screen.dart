import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_session.dart';
import '../application/auth_controller.dart';
import '../domain/auth_models.dart';
import 'widgets/gate_card.dart';

/// Signed in, but the account's role isn't "admin" (the backend answers
/// 403 to every admin request). Only Log out helps here.
///
/// Route: `/not-admin`. The router guard opens it; after Log out the guard
/// shows the login page.
class NotAdminScreen extends ConsumerWidget {
  const NotAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(adminSessionProvider).user?.email ?? '';
    final textTheme = Theme.of(context).textTheme;
    return GateCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.gpp_bad_outlined, size: 40, color: AppColors.error),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(
              NotAdminException.message,
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            email.isEmpty
                ? 'Only BrAInBox admins can use this portal. Log out and sign '
                      'in with an admin account.'
                : 'You are signed in as $email. Only BrAInBox admins can use '
                      'this portal. Log out and sign in with an admin account.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Log out',
            icon: Icons.logout,
            expand: true,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
    );
  }
}
