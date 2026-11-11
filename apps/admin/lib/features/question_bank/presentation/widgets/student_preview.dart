import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/question_bank_models.dart';

/// A phone-shaped preview of the question as a student sees it after
/// picking the first wrong option: that option red, the answer green, and
/// the misconception they probably have.
class StudentPreview extends StatelessWidget {
  const StudentPreview({super.key, required this.question});

  final QuestionDetail question;

  @override
  Widget build(BuildContext context) {
    final q = question;
    final textTheme = Theme.of(context).textTheme;
    final wrong = q.options.where((o) => !o.isCorrect).firstOrNull;

    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.ink, width: 6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Question preview',
              style: textTheme.labelSmall?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              q.stem.isEmpty ? 'Your question appears here.' : q.stem,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final o in q.options)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: o.isCorrect
                      ? AppColors.successSoft
                      : o == wrong
                      ? AppColors.errorSoft
                      : null,
                  border: Border.all(
                    color: o.isCorrect
                        ? AppColors.success
                        : o == wrong
                        ? AppColors.error
                        : AppColors.border,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      o.isCorrect
                          ? Icons.check_circle_outline
                          : o == wrong
                          ? Icons.cancel_outlined
                          : Icons.circle_outlined,
                      size: 16,
                      color: o.isCorrect
                          ? AppColors.successDark
                          : o == wrong
                          ? AppColors.error
                          : AppColors.muted,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        o.text.isEmpty ? o.label : o.text,
                        style: textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            if ((wrong?.misconception ?? '').isNotEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Text.rich(
                  TextSpan(
                    text: 'Likely misconception: ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                    children: [
                      TextSpan(
                        text: wrong!.misconception,
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
