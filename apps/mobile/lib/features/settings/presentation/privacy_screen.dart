import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/settings_controller.dart';
import '../domain/settings_models.dart';
import 'widgets/settings_tiles.dart';

/// Data & privacy (Figma F3): what we collect and why, and the choices the
/// student controls. Personalised recommendations are required for the
/// core app, so that switch is locked on.
///
/// Route: `/settings/privacy`
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  static const _collected = [
    ('Your answers & scores', 'To find gaps and recommend next steps'),
    ('Study time & activity', 'To build your weekly plan'),
    ('Uploads & handwriting', 'Processed to summarise, then stored privately'),
    ('Profile (name, email, phone)', 'For your account only'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(privacyControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    Future<void> save(PrivacySettings next) async {
      final ok = await ref.read(privacyControllerProvider.notifier).save(next);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save that. Try again.")),
        );
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Data & privacy'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.settings),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.successDark,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your data helps you, not advertisers.',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.successDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  "We never sell your data or show ads. You're in control of "
                  'everything below.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.successDark,
                  ),
                ),
              ],
            ),
          ),
          const SettingsSection('What we collect'),
          SettingsGroup(
            children: [
              for (final (title, why) in _collected)
                ListTile(
                  leading: const Icon(Icons.check, color: AppColors.success),
                  title: Text(title),
                  subtitle: Text(why),
                  dense: true,
                ),
            ],
          ),
          const SettingsSection('Your choices'),
          SettingsGroup(
            children: switch (state) {
              AsyncData(:final value) => [
                const SettingsSwitchTile(
                  icon: Icons.recommend_outlined,
                  title: 'Personalised recommendations',
                  subtitle: 'Required for the core app',
                  value: true,
                  onChanged: null, // locked on
                ),
                SettingsSwitchTile(
                  icon: Icons.auto_awesome,
                  title: 'Use my answers to improve AI feedback',
                  subtitle: 'Anonymised',
                  value: value.improveAi,
                  onChanged: (v) => save(value.copyWith(improveAi: v)),
                ),
                SettingsSwitchTile(
                  icon: Icons.badge_outlined,
                  title: 'Show my name in community',
                  subtitle: 'Otherwise "A/L student"',
                  value: value.showNameInCommunity,
                  onChanged: (v) =>
                      save(value.copyWith(showNameInCommunity: v)),
                ),
                SettingsSwitchTile(
                  icon: Icons.school_outlined,
                  title: 'Share anonymised data for education research',
                  subtitle: 'With approved Sri Lankan universities',
                  value: value.shareResearch,
                  onChanged: (v) => save(value.copyWith(shareResearch: v)),
                ),
              ],
              AsyncError(:final error) => [
                Padding(
                  padding: AppSpacing.cardPadding,
                  child: ErrorBanner(
                    message: ErrorMessages.of(error),
                    onRetry: () => ref.invalidate(privacyControllerProvider),
                  ),
                ),
              ],
              _ => [const LinearProgressIndicator(minHeight: 2)],
            },
          ),
        ],
      ),
    );
  }
}
