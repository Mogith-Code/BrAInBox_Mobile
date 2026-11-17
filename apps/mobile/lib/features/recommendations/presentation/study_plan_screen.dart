import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/recommendations_controller.dart';
import '../domain/recommendations_models.dart';
import 'widgets/open_action.dart';

/// The weekly study plan: the top-priority actions fitted into the
/// student's study days. Tick items, drag to reorder, or regenerate.
///
/// Route: `/recommendations/study-plan`
class StudyPlanScreen extends ConsumerWidget {
  const StudyPlanScreen({super.key});

  static const _weekdays = {
    'mon': 'Monday',
    'tue': 'Tuesday',
    'wed': 'Wednesday',
    'thu': 'Thursday',
    'fri': 'Friday',
    'sat': 'Saturday',
    'sun': 'Sunday',
  };

  Future<void> _regenerate(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make a new plan?'),
        content: const Text(
          'A new 7-day plan is built from your current next steps. '
          'Your ticks on this plan are kept in your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Make a new plan'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(studyPlanProvider.notifier).regenerate();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(studyPlanProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study plan'),
        actions: [
          IconButton(
            tooltip: 'Make a new plan',
            icon: const Icon(Icons.refresh),
            onPressed: () => _regenerate(context, ref),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: ErrorMessages.of(error),
            onRetry: () => ref.invalidate(studyPlanProvider),
          ),
        ),
        data: (plan) {
          if (plan.total == 0) {
            return EmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'Nothing to plan yet',
              message: plan.hint,
              actionLabel: 'Go to Practice',
              onAction: () => context.go(AppRoutes.practice),
            );
          }
          final theme = Theme.of(context);
          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              Text(plan.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: plan.done / plan.total,
                minHeight: 8,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('${plan.done} of ${plan.total} done'),
              const SizedBox(height: AppSpacing.lg),
              for (final day in plan.days)
                _Day(day: day, name: _weekdays[day.weekday] ?? day.weekday),
            ],
          );
        },
      ),
    );
  }
}

class _Day extends ConsumerWidget {
  const _Day({required this.day, required this.name});

  final PlanDay day;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(studyPlanProvider.notifier);
    final today = DateUtils.isSameDay(day.date, DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$name ${day.date.day}/${day.date.month}',
                style: theme.textTheme.titleSmall,
              ),
              if (today) ...[
                const SizedBox(width: AppSpacing.sm),
                const AppChip(label: 'Today'),
              ],
              const Spacer(),
              if (day.items.isNotEmpty)
                Text(
                  '${day.minutesPlanned} of ${day.minutesAvailable} min',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (day.items.isEmpty)
            Text(
              day.isStudyDay ? 'Nothing planned' : 'Rest day',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (oldIndex, newIndex) =>
                  controller.reorder(day, oldIndex, newIndex),
              children: [
                for (final (index, item) in day.items.indexed)
                  Card(
                    key: ValueKey(item.id),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ListTile(
                      leading: Checkbox(
                        value: item.isDone,
                        onChanged: (_) => controller.toggle(item),
                      ),
                      title: Text(
                        item.title,
                        style: item.isDone
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              )
                            : null,
                      ),
                      subtitle: Text(
                        '${actionStyle(item.action).label} · '
                        '${item.estimatedMinutes ?? 10} min',
                      ),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.all(AppSpacing.sm),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                      onTap: () => openAction(
                        context,
                        action: item.action,
                        target: item.target,
                        topicId: item.topicId,
                        conceptId: item.conceptId,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
