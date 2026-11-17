import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../application/evaluation_controller.dart';
import '../domain/evaluation_models.dart';

/// Structured and essay questions the student can answer and get checked.
///
/// Route: `/evaluation`
class WrittenQuestionsScreen extends ConsumerStatefulWidget {
  const WrittenQuestionsScreen({super.key});

  @override
  ConsumerState<WrittenQuestionsScreen> createState() =>
      _WrittenQuestionsScreenState();
}

class _WrittenQuestionsScreenState
    extends ConsumerState<WrittenQuestionsScreen> {
  String? _type;
  bool _hideOutdated = false;

  WrittenFilter get _filter => (type: _type, hideOutdated: _hideOutdated);

  void _open(WrittenQuestion question) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.keyboard_alt_outlined),
              title: const Text('Type my answer'),
              onTap: () {
                Navigator.pop(sheet);
                context.push(AppRoutes.typedAnswerPath(question.id));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Photograph my handwritten answer'),
              onTap: () {
                Navigator.pop(sheet);
                context.push(AppRoutes.handwrittenUploadPath(question.id));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(writtenQuestionsProvider(_filter));
    return Scaffold(
      appBar: AppBar(title: const Text('Structured and essay practice')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String?>(
                    segments: const [
                      ButtonSegment(value: null, label: Text('All')),
                      ButtonSegment(
                        value: 'structured',
                        label: Text('Structured'),
                      ),
                      ButtonSegment(value: 'essay', label: Text('Essay')),
                    ],
                    selected: {_type},
                    onSelectionChanged: (value) =>
                        setState(() => _type = value.first),
                  ),
                ),
              ],
            ),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Hide questions from the old syllabus'),
            value: _hideOutdated,
            onChanged: (value) => setState(() => _hideOutdated = value),
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: ErrorBanner(
                  message: ErrorMessages.of(error),
                  onRetry: () =>
                      ref.invalidate(writtenQuestionsProvider(_filter)),
                ),
              ),
              data: (questions) => questions.isEmpty
                  ? const EmptyState(
                      icon: Icons.edit_note,
                      title: 'No questions here yet',
                      message:
                          'Questions appear once their marking scheme is '
                          'approved.',
                    )
                  : ListView.separated(
                      padding: AppSpacing.screenPadding,
                      itemCount: questions.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) => _QuestionCard(
                        question: questions[index],
                        onTap: () => _open(questions[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.onTap});

  final WrittenQuestion question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  AppChip(
                    label: question.type == 'essay' ? 'Essay' : 'Structured',
                  ),
                  AppChip(label: '${formatMarks(question.marks)} marks'),
                  if (question.year != null) AppChip(label: '${question.year}'),
                  if (question.isOutdated)
                    const AppChip(
                      icon: Icons.history,
                      label: 'Outdated syllabus',
                      tone: AppChipTone.streak,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                question.stem,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                [
                  if (question.unitNumber != null)
                    'Unit ${question.unitNumber}',
                  ?question.topicTitle,
                  if (question.myAttempts > 0)
                    'Best: ${formatMarks(question.myBestMarks)}/'
                        '${formatMarks(question.marks)}',
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
