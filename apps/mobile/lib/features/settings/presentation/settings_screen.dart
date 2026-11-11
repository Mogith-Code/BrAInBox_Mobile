import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';
import '../application/settings_controller.dart';
import '../domain/settings_models.dart';
import 'widgets/settings_tiles.dart';

/// Settings (Figma F2): appearance, notifications, study goals, data &
/// privacy, about AI, help, and Log out.
///
/// Route: `/settings`
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // TODO(samni): confirm the support address with the team.
  static const supportEmail = 'support@brainbox.lk';

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    final notifications = ref.watch(settingsControllerProvider);
    final settings = ref.read(settingsControllerProvider.notifier);

    Future<void> save(NotificationSettings next) async {
      if (!await settings.save(next) && context.mounted) {
        _snack(context, "Couldn't save that. Try again.");
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Settings'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SettingsSection('Appearance'),
          SettingsGroup(
            children: [
              SettingsSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark mode',
                subtitle: 'Easier on the eyes at night',
                value: themeMode == ThemeMode.dark,
                onChanged: (v) =>
                    ref.read(appThemeModeProvider.notifier).setDark(v),
              ),
            ],
          ),
          const SettingsSection('Notifications'),
          SettingsGroup(
            children: switch (notifications) {
              AsyncData(:final value) => [
                SettingsSwitchTile(
                  icon: Icons.schedule,
                  title: 'Study reminders',
                  subtitle: 'Evenings at ${friendlyTime(value.reminderTime)}',
                  value: value.studyReminders,
                  onChanged: (v) => save(value.copyWith(studyReminders: v)),
                ),
                SettingsSwitchTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Community replies',
                  value: value.communityReplies,
                  onChanged: (v) => save(value.copyWith(communityReplies: v)),
                ),
              ],
              AsyncError() => [
                SettingsLinkTile(
                  icon: Icons.refresh,
                  title: "Couldn't load notification settings",
                  subtitle: 'Tap to try again',
                  onTap: () => ref.invalidate(settingsControllerProvider),
                ),
              ],
              _ => [const LinearProgressIndicator(minHeight: 2)],
            },
          ),
          const SettingsSection('Study'),
          SettingsGroup(
            children: [
              SettingsLinkTile(
                icon: Icons.track_changes,
                title: 'Study goals',
                subtitle: 'Exam year, target grade, confidence',
                onTap: () => context.push(AppRoutes.profileSetup),
              ),
              SettingsLinkTile(
                icon: Icons.calendar_today_outlined,
                title: 'Availability',
                subtitle: 'Days, hours and time of day',
                onTap: () => context.push(AppRoutes.profileSetup),
              ),
            ],
          ),
          const SettingsSection('Trust & support'),
          SettingsGroup(
            children: [
              SettingsLinkTile(
                icon: Icons.verified_user_outlined,
                title: 'Data & privacy',
                onTap: () => context.push(AppRoutes.privacy),
              ),
              SettingsLinkTile(
                icon: Icons.auto_awesome,
                title: 'About AI in BrAInBox',
                subtitle: 'How AI content is made & checked',
                onTap: () => _aboutAi(context),
              ),
              SettingsLinkTile(
                icon: Icons.help_outline,
                title: 'Help & feedback',
                onTap: () async {
                  final ok = await launchUrl(
                    Uri(
                      scheme: 'mailto',
                      path: supportEmail,
                      query: 'subject=BrAInBox help',
                    ),
                  );
                  if (!ok && context.mounted) {
                    _snack(context, 'Email us at $supportEmail');
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _LogoutButton(),
          const _AboutSection(),
        ],
      ),
    );
  }

  void _aboutAi(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AiBadge(),
              SizedBox(width: AppSpacing.sm),
              Text('About AI in BrAInBox'),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            '• Notes, visuals, questions and feedback marked "AI-generated" are '
            'made by AI from the NIE syllabus and approved teaching material.\n'
            '• Teachers review AI content before it is shared with everyone.\n'
            '• AI can still make mistakes. Use "Report" when something looks '
            'wrong, and check with your teacher.\n'
            '• Answer feedback is formative practice, not an official exam mark.',
          ),
        ],
      ),
    ),
  );
}

/// "Log out" - signs out and goes back to the Log in screen.
class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logoutControllerProvider);
    return Column(
      children: [
        if (state.hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              ErrorMessages.of(state.error),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        SettingsGroup(
          children: [
            SettingsLinkTile(
              icon: Icons.logout,
              title: 'Log out',
              danger: true,
              showChevron: false,
              onTap: state.isLoading
                  ? null
                  : () async {
                      await ref
                          .read(logoutControllerProvider.notifier)
                          .logout();
                      if (context.mounted &&
                          !ref.read(logoutControllerProvider).hasError) {
                        context.go(AppRoutes.login);
                      }
                    },
            ),
          ],
        ),
      ],
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
      data: (v) => 'BrAInBox v$v · Made in Sri Lanka 🇱🇰',
      loading: () => 'Version ...',
      error: (_, _) => 'Version unknown',
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
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
    );
  }
}
