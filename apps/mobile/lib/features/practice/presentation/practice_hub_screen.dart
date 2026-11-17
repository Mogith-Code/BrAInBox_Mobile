import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/practice_controller.dart';
import '../domain/practice_models.dart';

/// Practice tab: every way to practise, plus the quiz in progress and
/// recent results.
///
/// Route: `/practice`
class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(practiceHubProvider);
    return Scaffold(
      appBar: AppBar(title: const BrandAppBarTitle('Practice')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(practiceHubProvider),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            padding: AppSpacing.screenPadding,
            children: [
              ErrorBanner(
                message: ErrorMessages.of(error),
                onRetry: () => ref.invalidate(practiceHubProvider),
              ),
              const SizedBox(height: AppSpacing.lg),
              // The hub still works without its numbers.
              const _Actions(hub: PracticeHub()),
            ],
          ),
          data: (hub) => ListView(
            padding: AppSpacing.screenPadding,
            children: [
              if (hub.inProgress != null) ...[
                _ResumeCard(quiz: hub.inProgress!),
                const SizedBox(height: AppSpacing.lg),
              ],
              _Actions(hub: hub),
              if (hub.recent.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Recent quizzes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final quiz in hub.recent) _RecentTile(quiz: quiz),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.quiz});

  final QuizBrief quiz;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Continue where you stopped',
            style: TextStyle(color: AppColors.taglineOnDark, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            quiz.title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.primary,
              minimumSize: const Size(0, 48),
            ),
            onPressed: () =>
                context.push(AppRoutes.mcqQuestionPath(quiz.quizId)),
            child: Text('Resume quiz (${quiz.total} questions)'),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.hub});

  final PracticeHub hub;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.quiz_outlined,
          title: 'Topic quiz',
          subtitle: 'Choose a unit, the number of questions and the difficulty',
          onTap: () => context.push(AppRoutes.quizSetup),
        ),
        _ActionTile(
          icon: Icons.track_changes,
          title: 'Targeted practice',
          subtitle: hub.weakConcepts > 0
              ? '${hub.weakConcepts} weak concept'
                    '${hub.weakConcepts == 1 ? '' : 's'} to work on'
              : 'Questions from your weakest areas first',
          onTap: () => context.push(AppRoutes.quizSetupPath(mode: 'weak')),
        ),
        _ActionTile(
          icon: Icons.replay,
          title: 'Practice my mistakes',
          subtitle: hub.openMistakes > 0
              ? '${hub.openMistakes} question'
                    '${hub.openMistakes == 1 ? '' : 's'} you got wrong'
              : 'Nothing to fix yet',
          enabled: hub.openMistakes > 0,
          onTap: () => context.push(AppRoutes.quizSetupPath(mode: 'mistakes')),
        ),
        _ActionTile(
          icon: Icons.history_edu,
          title: 'Past papers',
          subtitle: 'Past A/L papers by year and type',
          onTap: () => context.push(AppRoutes.pastPapers),
        ),
        _ActionTile(
          icon: Icons.auto_awesome,
          title: 'Generate a model paper',
          subtitle: 'An A/L-style paper made for the units you choose',
          trailing: const AiBadge(label: 'AI'),
          onTap: () => context.push(AppRoutes.generatePaper),
        ),
        _ActionTile(
          icon: Icons.edit_note,
          title: 'Structured and essay practice',
          subtitle: 'Type or photograph your answer and see what is missing',
          onTap: () => context.push(AppRoutes.writtenQuestions),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        enabled: enabled,
        minVerticalPadding: AppSpacing.md,
        leading: CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          foregroundColor: AppColors.primary,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.quiz});

  final QuizBrief quiz;

  @override
  Widget build(BuildContext context) {
    final percent = quiz.percent ?? 0;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: MasteryRing(value: percent / 100, size: 44, strokeWidth: 5),
      title: Text(quiz.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${quiz.score ?? 0} of ${quiz.total} correct'),
      trailing: Text('$percent%'),
      onTap: () => context.push(AppRoutes.quizResultPath(quiz.quizId)),
    );
  }
}
