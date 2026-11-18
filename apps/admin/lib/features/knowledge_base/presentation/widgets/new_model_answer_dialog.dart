import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/knowledge_base_controller.dart';
import '../../domain/knowledge_base_models.dart';

/// "Add model answer": the question, the answer, and its marking points
/// (text, marks, keywords). Save draft or Save and approve. Pops `true` once
/// saved.
class NewModelAnswerDialog extends ConsumerStatefulWidget {
  const NewModelAnswerDialog({super.key, this.takenQuestionIds = const {}});

  /// Questions that already have a model answer (one per question).
  final Set<String> takenQuestionIds;

  @override
  ConsumerState<NewModelAnswerDialog> createState() =>
      _NewModelAnswerDialogState();
}

class _PointFields {
  final text = TextEditingController();
  final marks = TextEditingController(text: '1');
  final keywords = TextEditingController();

  void dispose() {
    text.dispose();
    marks.dispose();
    keywords.dispose();
  }

  PointDraft get draft => PointDraft(
    text: text.text,
    marks: double.tryParse(marks.text.trim()) ?? 0,
    keywords: splitKeywords(keywords.text),
  );
}

class _NewModelAnswerDialogState extends ConsumerState<NewModelAnswerDialog> {
  final _answer = TextEditingController();
  final _points = [_PointFields()];
  String? _questionId;
  AnswerSource _source = AnswerSource.admin;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _answer.dispose();
    for (final p in _points) {
      p.dispose();
    }
    super.dispose();
  }

  Future<void> _save({required bool approve}) async {
    final answer = NewModelAnswer(
      questionId: _questionId ?? '',
      answerText: _answer.text,
      source: _source,
      approve: approve,
      points: [
        for (final p in _points)
          // A completely empty last row is ignored, not an error.
          if (p.text.text.trim().isNotEmpty || p.keywords.text.isNotEmpty)
            p.draft,
      ],
    );
    final problems = answer.problems;
    if (problems.isNotEmpty) {
      setState(() => _error = problems.first);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await ref.read(modelAnswersProvider.notifier).create(answer);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(writtenQuestionsProvider);
    final textTheme = Theme.of(context).textTheme;
    final total = _points.fold<double>(0, (s, p) => s + p.draft.marks);

    return AlertDialog(
      title: const Text('Add model answer'),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              switch (questions) {
                AsyncData(:final value) => _QuestionPicker(
                  questions: [
                    for (final q in value)
                      if (!widget.takenQuestionIds.contains(q.id)) q,
                  ],
                  value: _questionId,
                  onChanged: (id) => setState(() => _questionId = id),
                ),
                AsyncError(:final error) => ErrorBanner(
                  message: ErrorMessages.of(error),
                  onRetry: () => ref.invalidate(writtenQuestionsProvider),
                ),
                _ => const LinearProgressIndicator(),
              },
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<AnswerSource>(
                initialValue: _source,
                decoration: const InputDecoration(labelText: 'Source'),
                items: [
                  for (final s in AnswerSource.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: (s) => setState(() => _source = s ?? _source),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _answer,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Model answer',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Marking points · ${total == total.roundToDouble() ? total.toStringAsFixed(0) : total.toStringAsFixed(1)} marks',
                      style: textTheme.titleSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _points.length >= 30
                        ? null
                        : () => setState(() => _points.add(_PointFields())),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add point'),
                  ),
                ],
              ),
              for (final (i, p) in _points.indexed)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            TextField(
                              controller: p.text,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                labelText: 'Point ${i + 1}',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextField(
                              controller: p.keywords,
                              decoration: const InputDecoration(
                                labelText: 'Keywords (comma separated)',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: p.marks,
                          onChanged: (_) => setState(() {}),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'Marks'),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove point ${i + 1}',
                        onPressed: _points.length == 1
                            ? null
                            : () =>
                                  setState(() => _points.removeAt(i).dispose()),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Students can only practise the question once its model '
                'answer is approved and has marking points.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: _saving ? null : () => _save(approve: false),
          child: const Text('Save draft'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : () => _save(approve: true),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Save and approve'),
        ),
      ],
    );
  }
}

class _QuestionPicker extends StatelessWidget {
  const _QuestionPicker({
    required this.questions,
    required this.value,
    required this.onChanged,
  });

  final List<WrittenQuestion> questions;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Text(
        'Every structured and essay question already has a model answer.',
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Question (structured or essay)',
      ),
      items: [
        for (final q in questions)
          DropdownMenuItem(
            value: q.id,
            child: Text(
              '${q.code} · ${q.type == 'essay' ? 'Essay' : 'Structured'} · '
              '${q.stem}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
