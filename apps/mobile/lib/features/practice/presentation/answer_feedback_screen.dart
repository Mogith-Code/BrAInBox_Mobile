import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/practice_controller.dart';
import 'widgets/answer_feedback_card.dart';

/// The feedback for the question that was just answered, on its own page.
///
/// The quiz screen shows the same card under the question; this route
/// exists for links that open the feedback directly.
///
/// Route: `/practice/feedback`
class AnswerFeedbackScreen extends ConsumerWidget {
  const AnswerFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(quizSessionProvider);
    final feedback = session.currentFeedback;
    final question = session.current;
    return Scaffold(
      appBar: AppBar(title: const Text('Answer feedback')),
      body: feedback == null || question == null
          ? EmptyState(
              title: 'No answer to show yet',
              message: 'Answer a question in a quiz to see its feedback.',
              actionLabel: 'Set up a quiz',
              onAction: () => context.pushReplacement(AppRoutes.quizSetup),
            )
          : ListView(
              padding: AppSpacing.screenPadding,
              children: [
                Text(
                  question.stem,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                AnswerFeedbackCard(
                  feedback: feedback,
                  onRevise: feedback.topicId == null
                      ? null
                      : () => context.push(
                          AppRoutes.topicPath(feedback.topicId!),
                        ),
                ),
              ],
            ),
    );
  }
}
