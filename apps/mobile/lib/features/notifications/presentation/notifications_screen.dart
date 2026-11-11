import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/notifications_controller.dart';
import '../domain/notifications_models.dart';

/// Notification center (Figma F4): filter chips, unread dots, "Mark all
/// read". Tapping a notification marks it read.
///
/// Route: `/notifications`
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationFilter _filter = NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsControllerProvider);
    final controller = ref.read(notificationsControllerProvider.notifier);
    final hasUnread = state.value?.any((n) => !n.read) ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Notifications'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        actions: [
          TextButton(
            onPressed: hasUnread
                ? () async {
                    final ok = await controller.markAllRead();
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Couldn't update. Try again."),
                        ),
                      );
                    }
                  }
                : null,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  for (final f in NotificationFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: ChoiceChip(
                        label: Text(f.label),
                        selected: f == _filter,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: switch (state) {
              AsyncData(:final value) => () {
                final shown = value.where(_filter.matches).toList();
                if (shown.isEmpty) {
                  return const EmptyState(
                    icon: Icons.notifications_none,
                    title: "You're all caught up",
                    message: 'New reminders and replies will show up here.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(notificationsControllerProvider.future),
                  child: ListView.separated(
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) => _NotificationTile(
                      notification: shown[i],
                      onTap: () => controller.markRead(shown[i].id),
                    ),
                  ),
                );
              }(),
              AsyncError(:final error) => Center(
                child: ErrorBanner(
                  message: ErrorMessages.of(error),
                  onRetry: () =>
                      ref.invalidate(notificationsControllerProvider),
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  static (IconData, Color, Color) _style(NotificationKind kind) =>
      switch (kind) {
        NotificationKind.reminder => (
          Icons.schedule,
          AppColors.primary,
          AppColors.primarySoft,
        ),
        NotificationKind.recommendation => (
          Icons.auto_awesome,
          AppColors.warningDark,
          AppColors.warningSoft,
        ),
        NotificationKind.community => (
          Icons.chat_bubble_outline,
          AppColors.secondaryDark,
          AppColors.secondarySoft,
        ),
        NotificationKind.achievement => (
          Icons.emoji_events_outlined,
          AppColors.successDark,
          AppColors.successSoft,
        ),
        NotificationKind.streak => (
          Icons.local_fire_department_outlined,
          AppColors.streakDark,
          AppColors.streakSoft,
        ),
        NotificationKind.other => (
          Icons.notifications_none,
          AppColors.muted,
          AppColors.surfaceMuted,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final (icon, fg, bg) = _style(n.type);
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: n.read
          ? Colors.transparent
          : AppColors.primarySoft.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: bg,
                child: Icon(icon, color: fg, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: n.read ? FontWeight.w500 : FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    if (n.aiGenerated) ...[
                      const SizedBox(height: AppSpacing.xs),
                      const AiBadge(),
                    ],
                    if (n.body.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        n.body,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                    if (n.createdAt != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        Formatters.relativeTime(n.createdAt!),
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.mutedLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!n.read)
                Semantics(
                  label: 'Unread',
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, left: AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
