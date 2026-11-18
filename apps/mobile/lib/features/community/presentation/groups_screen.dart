import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../insights/domain/insights_models.dart' show TopicStatus;
import '../../insights/presentation/widgets/status_chip.dart';
import '../application/community_controller.dart';
import '../domain/community_models.dart';

/// Community: my study groups and the groups I can join (one per unit and
/// General). Weak units first, from `GET /insights/units`.
///
/// Route: `/community`
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(groupsProvider);
    Future<void> refresh() => ref.read(groupsProvider.notifier).refresh();

    Future<void> setMember(StudyGroup group, {required bool join}) async {
      final error = await ref
          .read(groupsProvider.notifier)
          .setMember(group, join: join);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const BrandAppBarTitle('Community')),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: switch (state) {
          AsyncValue(value: final groups?) => _GroupsList(
            groups: groups,
            onOpen: (g) => context.push(AppRoutes.groupFeedPath(g.id)),
            onJoin: (g) => setMember(g, join: true),
            onLeave: (g) => setMember(g, join: false),
          ),
          AsyncValue(:final error?) => ListView(
            padding: AppSpacing.screenPadding,
            children: [
              ErrorBanner(
                message: communityErrorMessage(error),
                onRetry: refresh,
              ),
            ],
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _GroupsList extends StatelessWidget {
  const _GroupsList({
    required this.groups,
    required this.onOpen,
    required this.onJoin,
    required this.onLeave,
  });

  final GroupsState groups;
  final ValueChanged<StudyGroup> onOpen;
  final ValueChanged<StudyGroup> onJoin;
  final ValueChanged<StudyGroup> onLeave;

  @override
  Widget build(BuildContext context) {
    if (groups.myGroups.isEmpty && groups.toJoin.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: AppSpacing.xxl),
          EmptyState(
            icon: Icons.groups_outlined,
            title: 'No study groups yet',
            message: 'Groups appear here once your teacher sets them up.',
          ),
        ],
      );
    }
    final textTheme = Theme.of(context).textTheme;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Semantics(
        header: true,
        child: Text(title, style: textTheme.titleMedium),
      ),
    );
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        section('My groups'),
        if (groups.myGroups.isEmpty)
          Text(
            'Join a group below to ask questions and help others.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        for (final group in groups.myGroups)
          _GroupTile(
            group: group,
            weak: groups.isWeak(group),
            busy: groups.busyGroupIds.contains(group.id),
            onOpen: () => onOpen(group),
            onToggle: () => onLeave(group),
          ),
        if (groups.toJoin.isNotEmpty) ...[
          section('Groups to join'),
          for (final group in groups.toJoin)
            _GroupTile(
              group: group,
              weak: groups.isWeak(group),
              busy: groups.busyGroupIds.contains(group.id),
              onOpen: () => onOpen(group),
              onToggle: () => onJoin(group),
            ),
        ],
      ],
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.weak,
    required this.busy,
    required this.onOpen,
    required this.onToggle,
  });

  final StudyGroup group;

  /// My mastery of this group's unit is weak: suggested first.
  final bool weak;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final members =
        '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                  child: Text(
                    group.unitNumber?.toString() ?? '#',
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, style: textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        [members, if (group.isPrivate) 'Private'].join(' · '),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                      if (weak) ...[
                        const SizedBox(height: AppSpacing.xs),
                        const StatusChip(status: TopicStatus.weak),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: group.isMember ? 'Leave' : 'Join',
                  variant: group.isMember
                      ? AppButtonVariant.secondary
                      : AppButtonVariant.primary,
                  expand: false,
                  isLoading: busy,
                  onPressed: busy ? null : onToggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
