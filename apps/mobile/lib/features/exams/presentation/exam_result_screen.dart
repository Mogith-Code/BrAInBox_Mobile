import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/exams_controller.dart';
import '../domain/exams_models.dart';
import 'exam_attempt_screen.dart' show kOptionLetters;

Color _scoreColor(double p) {
  if (p >= 75) return AppColors.success;
  if (p >= 50) return AppColors.warning;
  return AppColors.error;
}

/// Results screen displaying evaluation, score breakdown by topic, and question review.
///
/// Route: `/exams/result`
class ExamResultScreen extends ConsumerWidget {
  const ExamResultScreen({super.key, this.paper, this.result});

  final ExamPaper? paper;
  final EvalResult? result;

  List<int> _extractUnitNumbers(List<String> labels) {
    final out = <int>{};
    for (final label in labels) {
      final m = RegExp(r'^Unit (\d+)').firstMatch(label);
      if (m != null) {
        out.add(int.parse(m.group(1)!));
      } else {
        for (final entry in kBiologyUnits.entries) {
          if (label.toLowerCase().contains(entry.value.toLowerCase())) {
            out.add(entry.key);
          }
        }
      }
    }
    return out.toList()..sort();
  }

  void _openSetup(BuildContext context, WidgetRef ref, List<int> units) {
    ref.read(examSessionControllerProvider.notifier).reset();
    context.go(AppRoutes.generatePaper, extra: units);
  }

  Widget _buildSummary(BuildContext context, EvalResult res) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const Text(
              'Your score',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${res.percent.toStringAsFixed(res.percent % 1 == 0 ? 0 : 1)}%',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: _scoreColor(res.percent),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${res.marksObtained} / ${res.marksTotal} marks · ${res.correct} correct · '
              '${res.answered} answered · ${res.totalQuestions} questions',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildByTopic(BuildContext context, EvalResult res) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance by topic',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final t in res.byTopic) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      t.topic,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${t.correct}/${t.total} · ${t.percent.round()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _scoreColor(t.percent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: t.percent / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _scoreColor(t.percent),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: res.weakTopics.isEmpty
                    ? AppColors.successSoft
                    : AppColors.warningSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: res.weakTopics.isEmpty
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.warningBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    res.weakTopics.isEmpty
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    color: res.weakTopics.isEmpty
                        ? AppColors.successDark
                        : AppColors.warningDark,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      res.weakTopics.isEmpty
                          ? 'No weak topics detected in this paper. Great work!'
                          : 'Needs more practice: ${res.weakTopics.join(', ')}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: res.weakTopics.isEmpty
                            ? AppColors.successDark
                            : AppColors.warningDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewOption(String text, int idx, QuestionResult r) {
    final isCorrect = text == r.correctAnswer;
    final isSelected = text == r.selectedOption;

    Color? bg = AppColors.white;
    Color border = AppColors.border;

    if (isCorrect) {
      bg = AppColors.successSoft;
      border = AppColors.success;
    } else if (isSelected) {
      bg = AppColors.errorSoft;
      border = AppColors.error.withValues(alpha: 0.5);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${kOptionLetters[idx]}.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isCorrect
                  ? AppColors.successDark
                  : (isSelected ? AppColors.errorDark : AppColors.muted),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isCorrect
                    ? AppColors.successDark
                    : (isSelected ? AppColors.errorDark : AppColors.ink),
                fontWeight: (isCorrect || isSelected)
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          if (isCorrect)
            const Text(
              '  ✓ correct',
              style: TextStyle(
                color: AppColors.successDark,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          if (isSelected && !isCorrect)
            const Text(
              '  ✗ your answer',
              style: TextStyle(
                color: AppColors.errorDark,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(
    BuildContext context,
    int i,
    QuestionResult r,
    ExamPaper? activePaper,
  ) {
    ExamQuestion? q;
    if (activePaper != null) {
      for (final item in activePaper.questions) {
        if (item.id == r.questionId) q = item;
      }
    }
    final options = q?.options ?? [r.correctAnswer];

    final String status = r.selectedOption == null
        ? 'Not answered'
        : (r.isCorrect ? 'Correct' : 'Wrong');
    final Color statusColor = r.isCorrect
        ? AppColors.success
        : (r.selectedOption == null ? AppColors.muted : AppColors.error);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r.topic.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${i + 1}. ${r.question}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var idx = 0; idx < options.length; idx++)
              _buildReviewOption(options[idx], idx, r),
            if (r.explanation != null && r.explanation!.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'AI Explanation',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.explanation!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(examSessionControllerProvider);
    final activePaper = paper ?? session.paper;
    final activeResult = result ?? session.result;

    if (activeResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.bar_chart_outlined,
                  size: 64,
                  color: AppColors.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'No exam results found.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Generate paper',
                  onPressed: () => context.go(AppRoutes.generatePaper),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final weakUnitNumbers = _extractUnitNumbers(activeResult.weakTopics);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildSummary(context, activeResult),
          const SizedBox(height: AppSpacing.md),
          _buildByTopic(context, activeResult),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Question review',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < activeResult.results.length; i++)
            _buildReviewCard(context, i, activeResult.results[i], activePaper),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'New practice paper',
            onPressed: () => _openSetup(context, ref, const []),
          ),
          if (weakUnitNumbers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Practice weak topics (${weakUnitNumbers.length} units)',
              variant: AppButtonVariant.secondary,
              onPressed: () => _openSetup(context, ref, weakUnitNumbers),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: 'See my next steps',
            icon: Icons.route_rounded,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.push(AppRoutes.nextSteps),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
