import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/settings_controller.dart';

/// Settings screen - Account, theme, notifications, privacy, about, sign out.
///
/// Route: `/settings`
///
// TODO(samni): build the real UI from Figma. Keep this file UI-only: read state
// from the controller and call its methods. Never call Dio / Firebase here.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: ErrorBanner(
                  message: '$error',
                  onRetry: () => ref.invalidate(settingsControllerProvider),
                ),
              ),
              data: (summary) => FeaturePlaceholder(
                title: 'Settings',
                owner: 'Samni',
                description:
                    'Account, theme, notifications, privacy, about, sign out.\n${summary.message}',
                actionLabel: 'Back',
                onAction: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.home),
              ),
            ),
          ),
          const _LogoutButton(),
          const _AboutSection(),
        ],
      ),
    );
  }
}

/// "Log out" - signs out and goes back to the Log in screen.
class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logoutControllerProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        children: [
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                ErrorMessages.of(state.error),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          AppButton(
            label: 'Log out',
            icon: Icons.logout,
            variant: AppButtonVariant.secondary,
            isLoading: state.isLoading,
            onPressed: () async {
              await ref.read(logoutControllerProvider.notifier).logout();
              if (context.mounted &&
                  !ref.read(logoutControllerProvider).hasError) {
                context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Settings > About: the logo, tagline and app version.
class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider);
    final versionText = version.when(
      data: (v) => 'Version $v',
      loading: () => 'Version ...',
      error: (_, _) => 'Version unknown',
    );
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Divider(),
            const SizedBox(height: AppSpacing.lg),
            const AppLogo(variant: AppLogoVariant.stacked, showTagline: true),
            const SizedBox(height: AppSpacing.md),
            Text(
              versionText,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
