import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/practice_controller.dart';
import '../domain/practice_models.dart';

/// Quiz result: score, time, accuracy by topic, misconceptions found and
/// every answer to review.
///
/// Route: `/practice/result?quizId=...`
class QuizResultScreen extends ConsumerWidget {
  const QuizResultScreen({super.key, this.quizId});

  final String? quizId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = quizId ?? ref.watch(quizSessionProvider).quiz?.quizId;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz result')),
        body: EmptyState(
          title: 'No result to show',
          message: 'Finish a quiz to see how you did.',
          actionLabel: 'Go to Practice',
          onAction: () => context.go(AppRoutes.practice),
        ),
      );
    }
    final state = ref.watch(quizResultProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz result')),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: ErrorMessages.of(error),
            onRetry: () => ref.invalidate(quizResultProvider(id)),
          ),
        ),
        data: (result) => _Result(result: result),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.result});

  final QuizResult result;

  String get _time {
    final minutes = result.timeSeconds ~/ 60;
    final seconds = result.timeSeconds % 60;
    return minutes == 0 ? '${seconds}s' : '${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Center(
          child: MasteryRing(
            value: result.percent / 100,
            size: 120,
            strokeWidth: 10,
            label: '${result.percent}%',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            '${result.score} of ${result.total} correct',
            style: theme.textTheme.titleLarge,
          ),
        ),
        Center(
          child: Text(
            '${result.title} · $_time',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        if (result.mistakes > 0)
          AppButton(
            label: 'Practice my mistakes',
            icon: Icons.replay,
            onPressed: () =>
                context.push(AppRoutes.quizSetupPath(mode: 'mistakes')),
          ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          label: 'See my next steps',
          variant: AppButtonVariant.secondary,
          onPressed: () => context.push(AppRoutes.nextSteps),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Accuracy by topic', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final topic in result.byTopic)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(topic.topic)),
                    Text('${topic.correct}/${topic.total}'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                LinearProgressIndicator(
                  value: topic.percent / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  color: topic.percent < 40
                      ? AppColors.error
                      : topic.percent < 70
                      ? AppColors.warning
                      : AppColors.secondary,
                ),
              ],
            ),
          ),
        if (result.misconceptions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Misconceptions found', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final item in result.misconceptions)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.warningDark,
                ),
                title: Text(item.title),
                subtitle: (item.correction ?? '').isEmpty
                    ? null
                    : Text(item.correction!),
                trailing: Text('×${item.count}'),
              ),
            ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('Review your answers', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        for (final item in result.review) _ReviewTile(item: item),
        const SizedBox(height: AppSpacing.lg),
        Text(
          result.disclaimer,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.item});

  final ReviewItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(
          item.isCorrect ? Icons.check_circle : Icons.cancel,
          color: item.isCorrect ? AppColors.success : AppColors.error,
        ),
        title: Text(
          '${item.position}. ${item.stem}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(item.topic),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.stem),
          const SizedBox(height: AppSpacing.sm),
          Text('Your answer: ${item.selected ?? 'Not answered'}'),
          if (!item.isCorrect) Text('Correct answer: ${item.correct}'),
          if ((item.explanation ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(item.explanation!),
          ],
        ],
      ),
    );
  }
}
