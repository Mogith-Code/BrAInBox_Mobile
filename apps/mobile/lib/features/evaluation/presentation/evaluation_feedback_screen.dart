import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/evaluation_controller.dart';
import '../domain/evaluation_models.dart';

/// Feedback on a checked answer: the marking points covered, partly
/// covered and missing, the estimated marks, tips and the model answer.
///
/// Route: `/evaluation/feedback/:evaluationId`
class EvaluationFeedbackScreen extends ConsumerWidget {
  const EvaluationFeedbackScreen({super.key, required this.evaluationId});

  final String evaluationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(evaluationProvider(evaluationId));
    return Scaffold(
      appBar: AppBar(title: const Text('Answer feedback')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: ErrorMessages.of(error),
            onRetry: () => ref.invalidate(evaluationProvider(evaluationId)),
          ),
        ),
        data: (evaluation) {
          if (evaluation.isWorking) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AiGeneratingLoader(
                    message: 'Still checking your answer...',
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(evaluationProvider(evaluationId)),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }
          if (evaluation.status == 'ocr_ready') {
            return EmptyState(
              title: 'Check the text first',
              message: 'Your photos were read. Confirm the text to get marks.',
              actionLabel: 'Check the text',
              onAction: () => context.pushReplacement(
                AppRoutes.ocrPreviewPath(evaluation.id),
              ),
            );
          }
          if (!evaluation.isMarked) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'This answer could not be checked',
              message: evaluation.error,
              actionLabel: 'Try again',
              onAction: () => context.pushReplacement(
                AppRoutes.typedAnswerPath(evaluation.questionId),
              ),
            );
          }
          return _Feedback(evaluation: evaluation);
        },
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.evaluation});

  final Evaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = evaluation.percent ?? 0;
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Text(evaluation.question, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            children: [
              MasteryRing(
                value: percent / 100,
                size: 84,
                strokeWidth: 8,
                label: '$percent%',
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated marks', style: theme.textTheme.labelMedium),
                    Text(
                      '${formatMarks(evaluation.estimatedMarks)} / '
                      '${formatMarks(evaluation.maxMarks)}',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${evaluation.covered} covered · '
                      '${evaluation.partial} partial · '
                      '${evaluation.missing} missing',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          evaluation.disclaimer,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        if ((evaluation.feedback ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(evaluation.feedback!),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text('Marking points', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final point in evaluation.points) _PointTile(point: point),
        if (evaluation.tips.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  'How to improve',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (evaluation.tipsAiGenerated) const AiBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final tip in evaluation.tips)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.arrow_right,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  Expanded(child: Text(tip)),
                ],
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _Compare(evaluation: evaluation),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Try this question again',
          icon: Icons.replay,
          onPressed: () => context.pushReplacement(
            AppRoutes.typedAnswerPath(evaluation.questionId),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'See my next steps',
          variant: AppButtonVariant.secondary,
          onPressed: () => context.push(AppRoutes.nextSteps),
        ),
      ],
    );
  }
}

class _PointTile extends StatelessWidget {
  const _PointTile({required this.point});

  final PointResult point;

  @override
  Widget build(BuildContext context) {
    // Icon + word + colour, so the status never depends on colour alone.
    final (icon, color, label) = switch (point.status) {
      'covered' => (Icons.check_circle, AppColors.success, 'Covered'),
      'partial' => (Icons.adjust, AppColors.warning, 'Partly covered'),
      _ => (Icons.cancel, AppColors.error, 'Missing'),
    };
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(point.text),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$label · ${formatMarks(point.marksAwarded)} of '
                    '${formatMarks(point.marks)} mark'
                    '${point.marks == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  if ((point.evidence ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'You wrote: “${point.evidence}”',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Your answer next to the model answer (tabs, because a 360 px screen is
/// too narrow for two readable columns).
class _Compare extends StatelessWidget {
  const _Compare({required this.evaluation});

  final Evaluation evaluation;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Card(
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Your answer'),
                Tab(text: 'Model answer'),
              ],
            ),
            SizedBox(
              height: 260,
              child: TabBarView(
                children: [
                  for (final text in [
                    evaluation.answerText ?? '',
                    evaluation.modelAnswer ?? 'No model answer is available.',
                  ])
                    SingleChildScrollView(
                      padding: AppSpacing.cardPadding,
                      child: SelectableText(text),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
