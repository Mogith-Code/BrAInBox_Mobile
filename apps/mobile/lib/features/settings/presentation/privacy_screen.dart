import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/account_controller.dart';
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
      appBar: AppBar(
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
                    message: settingsErrorMessage(error),
                    onRetry: () => ref.invalidate(privacyControllerProvider),
                  ),
                ),
              ],
              _ => [const LinearProgressIndicator(minHeight: 2)],
            },
          ),
          const SettingsSection('Your data'),
          const _YourData(),
        ],
      ),
    );
  }
}

/// "Download my data" and "Delete my account".
class _YourData extends ConsumerWidget {
  const _YourData();

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (ok != true) return;
    final deleted = await ref
        .read(accountControllerProvider.notifier)
        .deleteAccount();
    if (deleted && context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountControllerProvider);
    final account = ref.read(accountControllerProvider.notifier);
    ref.listen(accountControllerProvider, (_, next) {
      if (next.action == AccountAction.exported) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Your data was saved.')));
      }
    });

    return SettingsGroup(
      children: [
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Download my data'),
          subtitle: const Text('A JSON file with everything we keep'),
          trailing: state.action == AccountAction.exporting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: state.busy ? null : account.exportData,
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: AppColors.error),
          title: const Text(
            'Delete my account',
            style: TextStyle(color: AppColors.error),
          ),
          subtitle: const Text('Removes all your data'),
          trailing: state.action == AccountAction.deleting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          onTap: state.busy ? null : () => _confirmDelete(context, ref),
        ),
        if (state.action == AccountAction.failed && state.error != null)
          ErrorBanner(message: state.error!),
      ],
    );
  }
}

/// Owns the text controller, so it is disposed only after the dialog's
/// closing animation has removed the [TextField].
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
    title: const Text('Delete my account?'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This removes your profile, answers, evaluations, uploaded '
          'answer photos, study plan and community posts. '
          'It cannot be undone.',
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _typed,
          decoration: const InputDecoration(
            labelText: 'Type DELETE to confirm',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: AppColors.error),
        onPressed: _typed.text.trim() == 'DELETE'
            ? () => Navigator.pop(context, true)
            : null,
        child: const Text('Delete forever'),
      ),
    ],
  );
}
