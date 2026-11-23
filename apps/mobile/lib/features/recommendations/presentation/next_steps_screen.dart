import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/recommendations_controller.dart';
import '../data/recommendations_repository.dart';
import '../domain/recommendations_models.dart';
import 'widgets/open_action.dart';

/// "Next steps": what to study next, each with the reason it was given.
///
/// Route: `/recommendations`
class NextStepsScreen extends ConsumerWidget {
  const NextStepsScreen({super.key});

  Future<void> _dismiss(WidgetRef ref, NextStep step) async {
    try {
      await ref
          .read(recommendationsRepositoryProvider)
          .setStatus(step.id, 'dismissed');
    } finally {
      ref.invalidate(nextStepsProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nextStepsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Next steps'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.studyPlan),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Study plan'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(nextStepsProvider),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: AppSpacing.screenPadding,
            children: [
              ErrorBanner(
                message: ErrorMessages.of(error),
                onRetry: () => ref.invalidate(nextStepsProvider),
              ),
            ],
          ),
          data: (steps) => steps.items.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    EmptyState(
                      title: 'No next steps yet',
                      message: steps.hint,
                      actionLabel: 'Go to Practice',
                      onAction: () => context.go(AppRoutes.practice),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: steps.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final step = steps.items[index];
                    return _StepCard(
                      step: step,
                      onOpen: () async {
                        await openAction(
                          context,
                          action: step.action,
                          target: step.target,
                          topicId: step.topicId,
                          conceptId: step.conceptId,
                        );
                        if (context.mounted) ref.invalidate(nextStepsProvider);
                      },
                      onDismiss: () => _dismiss(ref, step),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.onOpen,
    required this.onDismiss,
  });

  final NextStep step;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = actionStyle(step.action);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                  child: Icon(style.icon),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step.title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        [
                          if (step.unitNumber != null)
                            'Unit ${step.unitNumber}',
                          ?step.topic,
                          '${step.estimatedMinutes} min',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (step.priority == 1)
                  const AppChip(label: 'Do first', tone: AppChipTone.streak),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Why this was recommended: the rules are explainable.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(step.reason, style: theme.textTheme.bodyMedium),
            ),
            if (step.resource != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                [
                  ?step.resource!.channel,
                  if (step.resource!.durationSeconds != null)
                    '${(step.resource!.durationSeconds! / 60).round()} min video',
                ].join(' · '),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: style.label,
                    icon: style.icon,
                    onPressed: onOpen,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(onPressed: onDismiss, child: const Text('Not now')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
