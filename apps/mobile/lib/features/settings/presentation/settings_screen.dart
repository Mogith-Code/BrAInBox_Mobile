import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';
import '../../profile/application/profile_overview_controller.dart';
import '../../profile/application/saved_profile_provider.dart';
import '../../profile/domain/profile_models.dart';
import '../application/settings_controller.dart';
import '../domain/settings_models.dart';
import 'widgets/settings_tiles.dart';

/// The Settings tab (Figma F2): profile card, Profile, App settings,
/// Trust & support, Log out and the app version.
///
/// Route: `/settings` (a bottom-bar tab). Its pages (My profile, Edit
/// profile, Data & privacy) are pushed on top inside the tab.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // TODO(samni): confirm the support address with the team.
  static const supportEmail = 'support@brainbox.lk';

  static void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const _ProfileCard(),
          const SettingsSection('Profile'),
          const _ProfileGroup(),
          const SettingsSection('App settings'),
          const _AppSettingsGroup(),
          const SettingsSection('Trust & support'),
          SettingsGroup(
            children: [
              SettingsLinkTile(
                icon: Icons.verified_user_outlined,
                title: 'Data & privacy',
                subtitle: 'Download my data, delete my account',
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

/// A section that couldn't load: the reason and Retry (never a blank card).
class _SectionError extends StatelessWidget {
  const _SectionError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.cardPadding,
    child: ErrorBanner(message: settingsErrorMessage(error), onRetry: onRetry),
  );
}

/// A section that is still loading.
class _SectionLoading extends StatelessWidget {
  const _SectionLoading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: AppSpacing.cardPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.sm),
        const LinearProgressIndicator(minHeight: 2),
      ],
    ),
  );
}

/// Avatar, name, stream and exam year (`GET /profile/overview`). Opens
/// My profile inside the Settings tab.
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileOverviewControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    final Widget child;
    switch (state) {
      case AsyncData(:final value):
        final name = value.fullName.trim();
        final details = [
          if (value.streamLabel.isNotEmpty) value.streamLabel,
          if (value.examYear != null) 'A/L ${value.examYear}',
        ].join(' · ');
        child = ListTile(
          contentPadding: AppSpacing.cardPadding,
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.amber,
            child: name.isEmpty
                ? const Icon(Icons.person_outline, color: AppColors.ink)
                : Text(
                    Formatters.initials(name),
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          title: Text(
            name.isEmpty ? 'Your profile' : name,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          // Empty state: nothing saved yet.
          subtitle: Text(
            details.isEmpty ? 'Add your stream and exam year' : details,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.settingsProfile),
        );
      case AsyncError(:final error):
        child = _SectionError(
          error: error,
          onRetry: () => ref.invalidate(profileOverviewControllerProvider),
        );
      default:
        child = const _SectionLoading('Loading your profile...');
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Settings > Profile: Edit profile, Study goals, Availability, with the
/// saved answers (`GET /profile`) as summaries.
class _ProfileGroup extends ConsumerWidget {
  const _ProfileGroup();

  static String _hours(double h) =>
      h % 1 == 0 ? h.toStringAsFixed(0) : h.toStringAsFixed(1);

  static String _goals(Profile p) {
    final parts = [
      if (p.targetGrade != null) 'Target grade ${p.targetGrade}',
      if (p.examYear != null) 'A/L ${p.examYear}',
    ];
    return parts.isEmpty ? 'Not set yet' : parts.join(' · ');
  }

  static String _availability(Profile p) {
    if (p.studyDays.isEmpty) return 'Not set yet';
    final days = p.studyDays.length;
    final time = p.preferredTime;
    return [
      '$days ${days == 1 ? 'day' : 'days'} a week',
      if (p.hoursPerDay != null) '${_hours(p.hoursPerDay!)} h a day',
      if (time != null && time.isNotEmpty)
        time[0].toUpperCase() + time.substring(1),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedProfileProvider);
    return SettingsGroup(
      children: switch (state) {
        AsyncData(:final value) => [
          SettingsLinkTile(
            icon: Icons.person_outline,
            title: 'Edit profile',
            subtitle: 'Stream, subject, goals and study time',
            onTap: () => context.push(AppRoutes.settingsEditProfilePath()),
          ),
          SettingsLinkTile(
            icon: Icons.track_changes,
            title: 'Study goals',
            subtitle: _goals(value),
            onTap: () =>
                context.push(AppRoutes.settingsEditProfilePath('goals')),
          ),
          SettingsLinkTile(
            icon: Icons.calendar_today_outlined,
            title: 'Availability',
            subtitle: _availability(value),
            onTap: () =>
                context.push(AppRoutes.settingsEditProfilePath('availability')),
          ),
        ],
        AsyncError(:final error) => [
          _SectionError(
            error: error,
            onRetry: () => ref.invalidate(savedProfileProvider),
          ),
        ],
        _ => [const _SectionLoading('Loading your study profile...')],
      },
    );
  }
}

/// Settings > App settings: dark mode (kept on the phone) and notifications
/// (`GET /settings`, `PATCH /settings`).
class _AppSettingsGroup extends ConsumerWidget {
  const _AppSettingsGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(appThemeModeProvider);
    final notifications = ref.watch(settingsControllerProvider);
    final settings = ref.read(settingsControllerProvider.notifier);

    Future<void> save(NotificationSettings next) async {
      if (!await settings.save(next) && context.mounted) {
        SettingsScreen._snack(context, "Couldn't save that. Try again.");
      }
    }

    Future<void> pickTime(NotificationSettings value) async {
      final parts = value.reminderTime.split(':');
      final picked = await showTimePicker(
        context: context,
        helpText: 'Remind me at',
        initialTime: TimeOfDay(
          hour: int.tryParse(parts.first) ?? 20,
          minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 30 : 30,
        ),
      );
      if (picked == null) return;
      String two(int v) => v.toString().padLeft(2, '0');
      await save(
        value.copyWith(
          reminderTime: '${two(picked.hour)}:${two(picked.minute)}',
        ),
      );
    }

    return SettingsGroup(
      children: [
        SettingsSwitchTile(
          icon: Icons.dark_mode_outlined,
          title: 'Dark mode',
          subtitle: 'Easier on the eyes at night',
          value: themeMode == ThemeMode.dark,
          onChanged: (v) => ref.read(appThemeModeProvider.notifier).setDark(v),
        ),
        ...switch (notifications) {
          AsyncData(:final value) => [
            SettingsSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Study reminders',
              subtitle: value.studyReminders
                  ? 'Every day at ${friendlyTime(value.reminderTime)}'
                  : 'Off',
              value: value.studyReminders,
              onChanged: (v) => save(value.copyWith(studyReminders: v)),
            ),
            SettingsLinkTile(
              icon: Icons.schedule,
              title: 'Reminder time',
              subtitle: value.studyReminders
                  ? friendlyTime(value.reminderTime)
                  : 'Turn on study reminders first',
              onTap: value.studyReminders ? () => pickTime(value) : null,
            ),
            SettingsSwitchTile(
              icon: Icons.chat_bubble_outline,
              title: 'Community replies',
              subtitle: 'When someone replies to your post',
              value: value.communityReplies,
              onChanged: (v) => save(value.copyWith(communityReplies: v)),
            ),
          ],
          AsyncError(:final error) => [
            _SectionError(
              error: error,
              onRetry: () => ref.invalidate(settingsControllerProvider),
            ),
          ],
          _ => [const _SectionLoading('Loading notification settings...')],
        },
      ],
    );
  }
}
