import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../widgets/admin_page.dart';
import '../../application/past_papers_controller.dart';
import '../../domain/past_papers_models.dart';

/// One paper's questions, one at a time: the OCR'd question, the model
/// answer and the marking keywords (1 mark each), with the AI's suggested
/// keywords from the marking scheme. "Save & next question" moves on.
class AnswerKeyEditor extends ConsumerStatefulWidget {
  const AnswerKeyEditor({super.key, required this.paper});

  final PastPaper paper;

  @override
  ConsumerState<AnswerKeyEditor> createState() => _AnswerKeyEditorState();
}

class _AnswerKeyEditorState extends ConsumerState<AnswerKeyEditor> {
  int _index = 0;
  String? _loadedId;
  final _answer = TextEditingController();
  final _newKeyword = TextEditingController();
  List<String> _keywords = [];

  @override
  void dispose() {
    _answer.dispose();
    _newKeyword.dispose();
    super.dispose();
  }

  /// Fills the form when a different question is shown.
  void _load(PaperQuestion q) {
    if (_loadedId == q.id) return;
    _loadedId = q.id;
    _answer.text = q.modelAnswer;
    _keywords = [...q.keywords];
  }

  void _addKeyword(String word) {
    final w = word.trim();
    if (w.isEmpty || _keywords.contains(w)) return;
    setState(() => _keywords = [..._keywords, w]);
    _newKeyword.clear();
  }

  Future<void> _saveAndNext(List<PaperQuestion> all, PaperQuestion q) async {
    final ok = await ref
        .read(answerEditorProvider.notifier)
        .save(
          widget.paper.id,
          q.copyWith(modelAnswer: _answer.text.trim(), keywords: _keywords),
        );
    if (!mounted) return;
    if (!ok) {
      showAdminSnack(context, "Couldn't save. Try again.");
      return;
    }
    _next(all);
  }

  void _next(List<PaperQuestion> all) {
    if (_index < all.length - 1) {
      setState(() => _index++);
    } else {
      showAdminSnack(context, 'That was the last question of this paper.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paperQuestionsProvider(widget.paper.id));
    final saving = ref.watch(answerEditorProvider).isLoading;
    final textTheme = Theme.of(context).textTheme;
    final paperTitle = '${widget.paper.year} ${widget.paper.paperType.label}';

    return switch (state) {
      AsyncData(:final value) when value.isEmpty => AdminPanel(
        title: paperTitle,
        child: const Text('No extracted questions yet.'),
      ),
      AsyncData(:final value) => () {
        final q = value[_index.clamp(0, value.length - 1)];
        _load(q);
        final suggestions = q.suggestedKeywords
            .where((s) => !_keywords.contains(s))
            .toList();
        return AdminPanel(
          title: '$paperTitle · ${q.label}',
          trailing: StatusBadge(
            label: '${q.marks} marks',
            tone: BadgeTone.neutral,
            showIcon: false,
          ),
          child: Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EXTRACTED QUESTION'
                              '${q.ocrConfidence == null ? '' : ' · OCR ${Formatters.percent(q.ocrConfidence!)}'}',
                              style: textTheme.labelSmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(q.text),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Model answer',
                        controller: _answer,
                        maxLines: 5,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text.rich(
                        TextSpan(
                          text: 'Marking keywords  ',
                          style: textTheme.titleSmall,
                          children: [
                            TextSpan(
                              text: '1 mark each · synonyms allowed',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          for (final k in _keywords)
                            InputChip(
                              label: Text(k),
                              backgroundColor: AppColors.successSoft,
                              onDeleted: () => setState(
                                () => _keywords = [..._keywords]..remove(k),
                              ),
                            ),
                          SizedBox(
                            width: 160,
                            child: TextField(
                              controller: _newKeyword,
                              decoration: const InputDecoration(
                                isDense: true,
                                hintText: '+ add keyword',
                              ),
                              onSubmitted: _addKeyword,
                            ),
                          ),
                        ],
                      ),
                      if (suggestions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.warningSoft,
                            border: Border.all(color: AppColors.warningBorder),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                          ),
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const AiBadge(label: 'suggests adding'),
                              for (final s in suggestions)
                                ActionChip(
                                  label: Text(s),
                                  onPressed: () => _addKeyword(s),
                                ),
                              Text(
                                '(found in marking scheme)',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.warningDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _next(value),
                      child: const Text('Skip'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        label: 'Save & next question',
                        isLoading: saving,
                        onPressed: () => _saveAndNext(value, q),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }(),
      AsyncError(:final error) => AdminLoadError(
        error: error,
        onRetry: () => ref.invalidate(paperQuestionsProvider(widget.paper.id)),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
