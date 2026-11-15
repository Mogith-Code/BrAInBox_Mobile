import 'dart:async';

import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/exams_controller.dart';
import '../domain/exams_models.dart';

const List<String> kOptionLetters = ['A', 'B', 'C', 'D', 'E'];

/// Timed exam attempt screen with MCQ answering and submission.
///
/// Route: `/exams/attempt/:paperId`
class ExamAttemptScreen extends ConsumerStatefulWidget {
  const ExamAttemptScreen({super.key, required this.paperId});

  final String paperId;

  @override
  ConsumerState<ExamAttemptScreen> createState() => _ExamAttemptScreenState();
}

class _ExamAttemptScreenState extends ConsumerState<ExamAttemptScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final session = ref.read(examSessionControllerProvider);
      if (!session.isSubmitting && mounted) {
        ref.read(examSessionControllerProvider.notifier).tick();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _submit(ExamPaper paper) async {
    final session = ref.read(examSessionControllerProvider);
    final unanswered = paper.questions.length - session.answers.length;

    if (unanswered > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Submit paper?'),
          content: Text(
            'You have $unanswered unanswered question(s). Are you sure you want to finish and submit now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep working'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    try {
      await ref.read(examSessionControllerProvider.notifier).submit();
      if (!mounted) return;
      context.pushReplacement(AppRoutes.examResult);
    } catch (e) {
      if (!mounted) return;
      // Friendly text for every case (offline, timeout, backend codes).
      final msg = ErrorMessages.of(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildOption(ExamQuestion q, int idx, String? selectedLetter) {
    final letter = kOptionLetters[idx];
    final isSelected = selectedLetter == letter;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          ref
              .read(examSessionControllerProvider.notifier)
              .selectAnswer(q.id, letter);
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primarySoft : AppColors.white,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.mutedLight,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.white : AppColors.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  q.options[idx],
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? AppColors.ink : AppColors.ink,
                    fontWeight: isSelected
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int i, ExamQuestion q, String? selectedLetter) {
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
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    q.topic.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${q.marks} mark${q.marks > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${i + 1}. ${q.question}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var idx = 0; idx < q.options.length; idx++)
              _buildOption(q, idx, selectedLetter),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(examSessionControllerProvider);
    final paper = session.paper;

    if (paper == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exam Mode')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: AppColors.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'No active exam paper found.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Please generate a paper first to start an exam attempt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
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

    final total = paper.questions.length;
    final answeredCount = session.answers.length;
    final progress = total == 0 ? 0.0 : answeredCount / total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice paper'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(session.elapsedSeconds),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            paper.title.isNotEmpty
                ? '$total questions · ${paper.title}'
                : '$total questions',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          if (paper.warnings.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: Text(
                'Some topics could not be generated fully:\n${paper.warnings.join('\n')}',
                style: const TextStyle(
                  color: AppColors.warningDark,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < total; i++)
            _buildQuestionCard(
              i,
              paper.questions[i],
              session.answers[paper.questions[i].id],
            ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceMuted,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Answered $answeredCount/$total · ${_formatTime(session.elapsedSeconds)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Text(
                    'AI explanations',
                    style: TextStyle(fontSize: 13, color: AppColors.ink),
                  ),
                  Switch(
                    value: session.explain,
                    activeThumbColor: AppColors.primary,
                    onChanged: session.isSubmitting
                        ? null
                        : (v) => ref
                              .read(examSessionControllerProvider.notifier)
                              .toggleExplain(v),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AppButton(
                label: session.isSubmitting
                    ? 'Marking answers...'
                    : 'Submit paper',
                isLoading: session.isSubmitting,
                onPressed: session.isSubmitting ? null : () => _submit(paper),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
