import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';

import '../../domain/mcq_mapping_models.dart';

/// The question as a student sees it, with the real [McqOptionTile]s. Tap
/// an option to see the feedback for it: right / wrong, the misconception
/// behind a wrong pick, and the explanation.
class McqStudentPreview extends StatefulWidget {
  const McqStudentPreview({super.key, required this.question});

  final QuestionDetail question;

  @override
  State<McqStudentPreview> createState() => _McqStudentPreviewState();
}

class _McqStudentPreviewState extends State<McqStudentPreview> {
  String? _picked;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final textTheme = Theme.of(context).textTheme;
    final picked = q.options.where((o) => o.label == _picked).firstOrNull;

    McqOptionState stateOf(OptionDraft o) {
      if (picked == null) return McqOptionState.normal;
      if (o.isCorrect) return McqOptionState.correct;
      if (o.label == picked.label) return McqOptionState.wrong;
      return McqOptionState.normal;
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              picked == null
                  ? 'Tap an option to see the feedback a student gets.'
                  : 'Tap another option to compare.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              q.stem.trim().isEmpty ? 'Your question appears here.' : q.stem,
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final o in q.options)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: McqOptionTile(
                  letter: o.label,
                  text: o.text.trim().isEmpty ? '—' : o.text,
                  state: stateOf(o),
                  onTap: () => setState(() => _picked = o.label),
                ),
              ),
            if (picked != null) ...[
              _Feedback(
                correct: picked.isCorrect,
                misconception: picked.misconception,
              ),
              if (q.explanation.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(q.explanation, style: textTheme.bodySmall),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.correct, required this.misconception});

  final bool correct;
  final String? misconception;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (correct) {
      return const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.successDark, size: 18),
          SizedBox(width: AppSpacing.xs),
          Text(
            'Correct!',
            style: TextStyle(
              color: AppColors.successDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    final hasMisconception = (misconception ?? '').trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: hasMisconception ? AppColors.primarySoft : AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasMisconception ? Icons.lightbulb_outline : Icons.warning_amber,
            size: 18,
            color: hasMisconception ? AppColors.primary : AppColors.warningDark,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              hasMisconception
                  ? 'Likely misconception: $misconception'
                  : 'No misconception mapped · the student gets no '
                        'targeted feedback.',
              style: textTheme.bodySmall?.copyWith(
                color: hasMisconception
                    ? AppColors.primary
                    : AppColors.warningDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
