import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/practice_models.dart';

/// The instant feedback under an answered MCQ: right / wrong, the
/// misconception behind the chosen option, the explanation, the mastery
/// change and links to revise.
class AnswerFeedbackCard extends StatelessWidget {
  const AnswerFeedbackCard({
    super.key,
    required this.feedback,
    this.onRevise,
    this.onWatchVideo,
    this.onReport,
  });

  final AnswerFeedback feedback;

  /// Opens the concept's topic ("Revise this concept").
  final VoidCallback? onRevise;
  final VoidCallback? onWatchVideo;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correct = feedback.isCorrect;
    final tone = correct ? AppColors.successDark : AppColors.errorDark;
    final misconception = feedback.misconception;
    final explanation = feedback.optionExplanation ?? feedback.explanation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: correct ? AppColors.successSoft : AppColors.errorSoft,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Icon(correct ? Icons.check_circle : Icons.cancel, color: tone),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  correct ? 'Correct' : 'Not quite',
                  style: theme.textTheme.titleMedium?.copyWith(color: tone),
                ),
              ),
              if (feedback.masteryAfter != null)
                Text(
                  feedback.masteryBefore == null
                      ? 'Mastery ${feedback.masteryAfter}%'
                      : 'Mastery ${feedback.masteryBefore}% → '
                            '${feedback.masteryAfter}%',
                  style: theme.textTheme.labelMedium?.copyWith(color: tone),
                ),
            ],
          ),
        ),
        if (misconception != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              border: Border.all(color: AppColors.warningBorder),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.warningDark,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'What your answer suggests',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.warningDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(misconception.title, style: theme.textTheme.bodyLarge),
                if ((misconception.correction ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(misconception.correction!),
                ],
                if (feedback.recurring) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'You have made this mistake ${feedback.recurringCount} '
                    'times in the last 14 days.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.warningDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if ((explanation ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Explanation', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(explanation!),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            if (onRevise != null)
              TextButton.icon(
                onPressed: onRevise,
                icon: const Icon(Icons.menu_book_outlined),
                label: Text(
                  feedback.conceptName == null
                      ? 'Revise this topic'
                      : 'Revise: ${feedback.conceptName}',
                ),
              ),
            if (onWatchVideo != null)
              TextButton.icon(
                onPressed: onWatchVideo,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Watch a short video'),
              ),
            if (onReport != null)
              TextButton.icon(
                onPressed: onReport,
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Report this question'),
              ),
          ],
        ),
      ],
    );
  }
}
