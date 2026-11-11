import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/admin_page.dart';
import '../application/moderation_controller.dart';
import '../domain/moderation_models.dart';

/// Community moderation: reported posts / replies / visuals with their AI
/// flag and student reports (Keep, Warn, Remove), and the study groups.
///
/// Route: `/moderation`.
class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  static const _twoColumns = 1000.0;

  Future<void> _newGroup(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewGroupDialog(),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    final created = await ref
        .read(studyGroupsControllerProvider.notifier)
        .create(name);
    if (context.mounted) {
      showAdminSnack(
        context,
        created ? 'Group "$name" created.' : "Couldn't create the group.",
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(moderationControllerProvider);
    final groups = ref.watch(studyGroupsControllerProvider);
    final count = reports.value?.length;
    final groupCount = groups.value?.length;

    final queue = switch (reports) {
      AsyncData(:final value) when value.isEmpty => const EmptyState(
        icon: Icons.verified_outlined,
        title: 'Nothing to review',
        message: 'New reports from students and the AI land here.',
      ),
      AsyncData(:final value) => ListView.separated(
        itemCount: value.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) => _ReportCard(item: value[i]),
      ),
      AsyncError(:final error) => AdminLoadError(
        error: error,
        onRetry: () => ref.invalidate(moderationControllerProvider),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
    final side = _GroupsPanel(state: groups);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPageHeader(
          eyebrow: [
            if (count != null) '$count reported',
            if (groupCount != null) '$groupCount study groups',
          ].join(' · '),
          title: 'Community moderation',
          actions: [
            TextButton.icon(
              onPressed: () => _newGroup(context, ref),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New group'),
            ),
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => box.maxWidth >= _twoColumns
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: queue),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(flex: 2, child: side),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: queue),
                      const SizedBox(height: AppSpacing.lg),
                      Expanded(flex: 2, child: side),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends ConsumerWidget {
  const _ReportCard({required this.item});

  final ModerationItem item;

  Future<void> _act(
    BuildContext context,
    WidgetRef ref,
    ModerationAction action,
  ) async {
    final ok = await ref
        .read(moderationControllerProvider.notifier)
        .resolve(item.id, action);
    if (context.mounted) {
      showAdminSnack(
        context,
        ok
            ? switch (action) {
                ModerationAction.keep => 'Kept. The report is closed.',
                ModerationAction.warn => 'Warning sent to the author.',
                ModerationAction.remove => 'Removed.',
              }
            : "Couldn't save that. Try again.",
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final isVisual = item.targetType == ReportTarget.visual;
    final who = isVisual ? 'Visual' : '@${item.authorHandle ?? 'student'}';
    final where = [
      ?item.groupName,
      if (item.createdAt != null) Formatters.relativeTime(item.createdAt!),
    ].join(' · ');
    final body = isVisual
        ? '${item.visualTitle ?? 'A visual'}'
              '${item.details == null ? '' : ' — ${item.details}'}'
        : item.text ?? '';

    return AdminPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceMuted,
            child: isVisual
                ? const Icon(Icons.image_outlined, size: 18)
                : Text((item.authorHandle ?? '?')[0].toUpperCase()),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: who,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    children: [
                      if (where.isNotEmpty)
                        TextSpan(
                          text: '  $where',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Text(body),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (item.aiFlagLabel != null)
                      StatusBadge(
                        label:
                            'AI flag: ${item.aiFlagLabel}'
                            '${item.aiFlagScore == null ? '' : ' · ${Formatters.percent(item.aiFlagScore!)}'}',
                        tone: BadgeTone.warning,
                      ),
                    StatusBadge(
                      label: item.reportCount == 1
                          ? '1 student report'
                          : '${item.reportCount} student reports',
                      tone: BadgeTone.danger,
                      showIcon: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () => _act(context, ref, ModerationAction.keep),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Keep'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warningDark,
                ),
                onPressed: () => _act(context, ref, ModerationAction.warn),
                icon: const Icon(Icons.warning_amber_rounded, size: 16),
                label: const Text('Warn'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => _act(context, ref, ModerationAction.remove),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupsPanel extends StatelessWidget {
  const _GroupsPanel({required this.state});

  final AsyncValue<List<StudyGroup>> state;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.muted);
    return AdminPanel(
      title: 'Study groups',
      trailing: state.value == null
          ? null
          : Text('${state.value!.length} groups', style: muted),
      child: Expanded(
        child: switch (state) {
          AsyncData(:final value) => ListView.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final g = value[i];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  child: Icon(Icons.groups_outlined, color: AppColors.primary),
                ),
                title: Text(g.name),
                subtitle: Text(
                  '${Formatters.thousands(g.members)} members · '
                  'Mod: ${g.moderatorName ?? '—'}',
                  style: muted,
                ),
                trailing: g.moderatorName == null
                    ? const StatusBadge(
                        label: 'No moderator',
                        tone: BadgeTone.warning,
                        showIcon: false,
                      )
                    : StatusBadge(
                        label: g.isOpen ? 'Open' : 'Closed',
                        tone: g.isOpen ? BadgeTone.success : BadgeTone.neutral,
                      ),
              );
            },
          ),
          AsyncError(:final error) =>
            isEndpointMissing(error)
                ? Text('Groups need GET /admin/community/groups.', style: muted)
                : Text(ErrorMessages.of(error), style: muted),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

/// Asks for the new group's name; pops it (trimmed) or null on Cancel.
class _NewGroupDialog extends StatefulWidget {
  const _NewGroupDialog();

  @override
  State<_NewGroupDialog> createState() => _NewGroupDialogState();
}

class _NewGroupDialogState extends State<_NewGroupDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    void create() => Navigator.of(context).pop(_name.text.trim());
    return AlertDialog(
      title: const Text('New study group'),
      content: TextField(
        controller: _name,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'e.g. Unit 7 · Molecular'),
        onSubmitted: (_) => create(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: create, child: const Text('Create')),
      ],
    );
  }
}
