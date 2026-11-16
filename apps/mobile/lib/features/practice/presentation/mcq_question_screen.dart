import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/practice_controller.dart';
import '../domain/practice_models.dart';
import 'widgets/answer_feedback_card.dart';

/// One MCQ of a quiz, A/L style with 5 options, and the instant feedback
/// after answering.
///
/// Route: `/practice/quiz?quizId=...`
class McqQuestionScreen extends ConsumerStatefulWidget {
  const McqQuestionScreen({super.key, this.quizId});

  final String? quizId;

  @override
  ConsumerState<McqQuestionScreen> createState() => _McqQuestionScreenState();
}

class _McqQuestionScreenState extends ConsumerState<McqQuestionScreen> {
  Timer? _ticker;
  bool _timeUp = false;

  @override
  void initState() {
    super.initState();
    final quizId = widget.quizId;
    if (quizId != null) {
      Future.microtask(
        () => ref.read(quizSessionProvider.notifier).load(quizId),
      );
    }
    // Repaint once a second for the countdown of a timed quiz.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Duration? _remaining(Quiz quiz) {
    final limit = quiz.timeLimitMinutes;
    final started = quiz.startedAt;
    if (limit == null || started == null) return null;
    final left = Duration(minutes: limit) - DateTime.now().difference(started);
    return left.isNegative ? Duration.zero : left;
  }

  void _tick() {
    final quiz = ref.read(quizSessionProvider).quiz;
    if (quiz == null || !mounted) return;
    final left = _remaining(quiz);
    if (left == null) return;
    setState(() {});
    if (left == Duration.zero && !_timeUp) {
      _timeUp = true;
      _finish(confirm: false);
    }
  }

  Future<void> _finish({bool confirm = true}) async {
    final session = ref.read(quizSessionProvider);
    final quiz = session.quiz;
    if (quiz == null) return;
    final unanswered = quiz.questions.length - quiz.answered;
    if (confirm && unanswered > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Finish the quiz?'),
          content: Text(
            '$unanswered question${unanswered == 1 ? ' is' : 's are'} not '
            'answered. They will count as wrong.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep going'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Finish'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    final done = await ref.read(quizSessionProvider.notifier).submit();
    if (!mounted || !done) return;
    context.pushReplacement(AppRoutes.quizResultPath(quiz.quizId));
  }

  Future<void> _report(QuizQuestion question) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('What is wrong with this question?')),
            for (final (value, label) in const [
              ('wrong_answer', 'The marked answer is wrong'),
              ('unclear', 'The question is unclear'),
              ('typo', 'It has a typing mistake'),
              ('out_of_syllabus', 'It is not in the syllabus'),
            ])
              ListTile(
                title: Text(label),
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;
    final error = await ref
        .read(quizSessionProvider.notifier)
        .report(question.id, reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Thanks. An admin will check it.')),
    );
  }

  void _openNavigator(Quiz quiz, int current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (index, q) in quiz.questions.indexed)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: !q.isAnswered
                          ? null
                          : q.isCorrect == true
                          ? AppColors.successSoft
                          : AppColors.errorSoft,
                      side: BorderSide(
                        color: index == current
                            ? AppColors.primary
                            : AppColors.border,
                        width: index == current ? 2 : 1,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(quizSessionProvider.notifier).goTo(index);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${index + 1}'),
                        if (q.flagged)
                          const Icon(
                            Icons.flag,
                            size: 12,
                            color: AppColors.warning,
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  McqOptionState _optionState(QuizQuestion question, QuizOption option) {
    if (!question.isAnswered) return McqOptionState.normal;
    if (option.id == question.correctOptionId) return McqOptionState.correct;
    if (option.id == question.selectedOptionId) return McqOptionState.wrong;
    return McqOptionState.normal;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(quizSessionProvider);
    final quiz = session.quiz;
    final question = session.current;

    if (quiz == null || question == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: session.isLoading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                title: session.errorMessage ?? 'No quiz is open',
                message: 'Start a quiz from the Practice tab.',
                actionLabel: 'Set up a quiz',
                onAction: () => context.pushReplacement(AppRoutes.quizSetup),
              ),
      );
    }

    final theme = Theme.of(context);
    final feedback = session.currentFeedback;
    final left = _remaining(quiz);
    final total = quiz.questions.length;
    final controller = ref.read(quizSessionProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${session.index + 1} of $total'),
        actions: [
          if (left != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Text(
                  '${left.inMinutes.toString().padLeft(2, '0')}:'
                  '${(left.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: left.inSeconds < 60 ? AppColors.error : null,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: question.flagged ? 'Remove flag' : 'Flag for review',
            icon: Icon(
              question.flagged ? Icons.flag : Icons.flag_outlined,
              color: question.flagged ? AppColors.warning : null,
            ),
            onPressed: controller.toggleFlag,
          ),
          IconButton(
            tooltip: 'All questions',
            icon: const Icon(Icons.grid_view),
            onPressed: () => _openNavigator(quiz, session.index),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: quiz.answered / total),
        ),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              AppChip(label: 'Unit ${question.unitCode}'),
              AppChip(label: question.topicTitle),
              AppChip(
                label:
                    question.difficulty[0].toUpperCase() +
                    question.difficulty.substring(1),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(question.stem, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          for (final option in question.options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: McqOptionTile(
                letter: option.label,
                text: option.text,
                state: _optionState(question, option),
                onTap: question.isAnswered || session.isAnswering
                    ? null
                    : () => controller.answer(option.id),
              ),
            ),
          if (session.isAnswering) const LinearProgressIndicator(),
          if (session.errorMessage != null)
            ErrorBanner(message: session.errorMessage!),
          if (feedback != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AnswerFeedbackCard(
              feedback: feedback,
              onRevise: feedback.topicId == null
                  ? null
                  : () => context.push(AppRoutes.topicPath(feedback.topicId!)),
              onWatchVideo: feedback.isCorrect || feedback.topicId == null
                  ? null
                  : () => context.push(AppRoutes.topicPath(feedback.topicId!)),
              onReport: () => _report(question),
            ),
          ] else if (question.isAnswered)
            // Answered in an earlier session: the options show the solution.
            Text(
              question.isCorrect == true
                  ? 'You answered this correctly.'
                  : 'You answered this wrongly. The correct option is marked.',
              style: theme.textTheme.bodyMedium,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Row(
            children: [
              if (session.index > 0)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: IconButton.outlined(
                    tooltip: 'Previous question',
                    onPressed: () => controller.goTo(session.index - 1),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
              Expanded(
                child: session.isLast
                    ? AppButton(
                        label: 'Finish quiz',
                        isLoading: session.isSubmitting,
                        onPressed: _finish,
                      )
                    : AppButton(
                        label: question.isAnswered ? 'Next question' : 'Skip',
                        variant: question.isAnswered
                            ? AppButtonVariant.primary
                            : AppButtonVariant.secondary,
                        onPressed: controller.next,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
