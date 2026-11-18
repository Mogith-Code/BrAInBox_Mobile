import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../widgets/admin_page.dart';
import '../../question_bank/presentation/widgets/question_mapping_panel.dart';
import '../application/mcq_mapping_controller.dart';
import '../domain/mcq_mapping_models.dart';
import 'widgets/mcq_student_preview.dart';
import 'widgets/suggestions_panel.dart';

/// MCQ mapping: pick an MCQ, then edit its five options, the correct
/// answer, the explanation, the misconception behind each wrong option and
/// the unit / topic / concept it tests. "Suggest with AI" proposes the
/// misconceptions; the admin confirms each one.
///
/// Route: `/mcq-mapping?questionId=`. Data: `GET /admin/questions?type=mcq`,
/// `GET / PUT /admin/questions/{id}`,
/// `POST /admin/questions/{id}/misconception-suggestions`,
/// `PUT /admin/options/{option_id}/misconception`.
class McqMappingScreen extends ConsumerWidget {
  const McqMappingScreen({super.key, this.questionId});

  /// The MCQ being edited; null = none picked yet.
  final String? questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = _McqList(selectedId: questionId);
    final editor = questionId == null
        ? const AdminPanel(
            child: EmptyState(
              icon: Icons.touch_app_outlined,
              title: 'Pick an MCQ',
              message:
                  'Choose a question on the left to map a misconception to '
                  'each wrong option.',
            ),
          )
        : _EditorLoader(questionId: questionId!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AdminPageHeader(eyebrow: 'Question bank', title: 'MCQ mapping'),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => box.maxWidth >= 1000
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 320, child: list),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: editor),
                    ],
                  )
                : ListView(
                    children: [
                      SizedBox(height: 320, child: list),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(height: 1800, child: editor),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _McqList extends ConsumerWidget {
  const _McqList({required this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mcqListProvider);
    final pageNo = ref.watch(mcqPageProvider);
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.muted);

    return AdminPanel(
      title: 'MCQs',
      padding: const EdgeInsets.all(AppSpacing.md),
      child: switch (state) {
        AsyncData(:final value) when value.items.isEmpty => const EmptyState(
          icon: Icons.quiz_outlined,
          title: 'No MCQs yet',
          message: 'Add MCQs in the question bank first.',
        ),
        AsyncData(:final value) => Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Material(
                  type: MaterialType.transparency,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: value.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final q = value.items[i];
                      return ListTile(
                        minTileHeight: 56,
                        selected: q.id == selectedId,
                        selectedTileColor: AppColors.primarySoft,
                        onTap: () =>
                            context.go(AdminRoutes.mcqMappingPath(q.id)),
                        title: Text(
                          q.stem,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Wrap(
                          spacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(q.code, style: muted),
                            reviewBadge(
                              ReviewStatus.fromApi(q.status),
                              aiGenerated: q.isAiGenerated,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (value.total > QuestionFilter.pageSize)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Page $pageNo', style: muted),
                    IconButton(
                      tooltip: 'Previous page',
                      onPressed: pageNo > 1
                          ? () => ref
                                .read(mcqPageProvider.notifier)
                                .set(pageNo - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    IconButton(
                      tooltip: 'Next page',
                      onPressed: pageNo * QuestionFilter.pageSize < value.total
                          ? () => ref
                                .read(mcqPageProvider.notifier)
                                .set(pageNo + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
            ],
          ),
        ),
        AsyncError(:final error) => AdminLoadError(
          error: error,
          onRetry: () => ref.invalidate(mcqListProvider),
        ),
        _ => const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Center(child: CircularProgressIndicator()),
        ),
      },
    );
  }
}

class _EditorLoader extends ConsumerWidget {
  const _EditorLoader({required this.questionId});

  final String questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionDetailProvider(questionId));
    return switch (state) {
      AsyncData(:final value) when value.type != QuestionKind.mcq =>
        const AdminPanel(
          child: EmptyState(
            icon: Icons.info_outline,
            title: 'Not an MCQ',
            message: 'Only MCQs have options to map misconceptions to.',
          ),
        ),
      AsyncData(:final value) => McqEditor(
        key: ValueKey(questionId),
        initial: value,
      ),
      AsyncError(:final error) => AdminLoadError(
        error: error,
        onRetry: () => ref.invalidate(questionDetailProvider(questionId)),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// Always five options, A-E (missing ones are added empty).
QuestionDetail withFiveOptions(QuestionDetail q) {
  final byLabel = {for (final o in q.options) o.label: o};
  return q.copyWith(
    options: [
      for (final l in 'ABCDE'.split('')) byLabel[l] ?? OptionDraft(label: l),
    ],
  );
}

/// The one-MCQ editor.
class McqEditor extends ConsumerStatefulWidget {
  const McqEditor({super.key, required this.initial});

  final QuestionDetail initial;

  @override
  ConsumerState<McqEditor> createState() => _McqEditorState();
}

class _McqEditorState extends ConsumerState<McqEditor> {
  late QuestionDetail _q = withFiveOptions(widget.initial);

  /// What the server has, to tell whether there are unsaved changes.
  late QuestionDetail _saved = _q;
  late final _stem = TextEditingController(text: _q.stem);
  late final _explanation = TextEditingController(text: _q.explanation);
  late final _optionText = [
    for (final o in _q.options) TextEditingController(text: o.text),
  ];
  late final _misconception = [
    for (final o in _q.options)
      TextEditingController(text: o.misconception ?? ''),
  ];

  @override
  void dispose() {
    for (final c in [_stem, _explanation, ..._optionText, ..._misconception]) {
      c.dispose();
    }
    super.dispose();
  }

  /// The question as typed right now.
  QuestionDetail get _current => _q.copyWith(
    stem: _stem.text,
    explanation: _explanation.text,
    options: [
      for (var i = 0; i < _q.options.length; i++)
        _q.options[i].copyWith(
          text: _optionText[i].text,
          misconception: _q.options[i].isCorrect
              ? null
              : (_misconception[i].text.trim().isEmpty
                    ? null
                    : _misconception[i].text.trim()),
        ),
    ],
  );

  bool get _dirty => _normalised(_current) != _normalised(_saved);

  static QuestionDetail _normalised(QuestionDetail q) => q.copyWith(
    options: [
      for (final o in q.options)
        o.copyWith(
          misconception: o.isCorrect || (o.misconception ?? '').trim().isEmpty
              ? null
              : o.misconception!.trim(),
        ),
    ],
  );

  void _setCorrect(int index) => setState(
    () => _q = _q.copyWith(
      options: [
        for (var i = 0; i < _q.options.length; i++)
          _q.options[i].copyWith(isCorrect: i == index),
      ],
    ),
  );

  Future<void> _save() async {
    final q = _current;
    final problems = q.status == 'approved'
        ? q.problems
        : [if (q.stem.trim().isEmpty) 'Write the question stem.'];
    if (problems.isNotEmpty) {
      showAdminSnack(context, problems.first);
      return;
    }
    final result = await ref.read(mcqSaveProvider.notifier).save(q);
    if (!mounted) return;
    if (result.saved == null) {
      showAdminSnack(context, result.error ?? "Couldn't save. Try again.");
      return;
    }
    setState(() {
      _q = _q.copyWith(status: result.saved!.status);
      _saved = _current;
    });
    showAdminSnack(context, 'Saved.');
  }

  Future<void> _suggest() async {
    if (_dirty) {
      showAdminSnack(context, 'Save your changes first, so the AI sees them.');
      return;
    }
    await ref.read(suggestionsProvider(_q.id!).notifier).run();
  }

  Future<void> _accept(MisconceptionSuggestion s) async {
    final error = await ref
        .read(suggestionsProvider(_q.id!).notifier)
        .accept(s);
    if (!mounted) return;
    if (error != null) {
      showAdminSnack(context, error);
      return;
    }
    final i = _q.options.indexWhere((o) => o.label == s.label);
    if (i >= 0) {
      // Saved on the server already, so it is not an unsaved change.
      final wasDirty = _dirty;
      setState(() {
        _misconception[i].text = s.suggested;
        if (!wasDirty) _saved = _current;
      });
    }
    showAdminSnack(context, 'Option ${s.label} mapped.');
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(mcqSaveProvider);
    final textTheme = Theme.of(context).textTheme;
    final current = _current;
    final dirty = _dirty;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.muted);

    return ListView(
      children: [
        AdminPanel(
          title: current.code == null ? 'MCQ' : 'MCQ · ${current.code}',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (current.isAiGenerated) ...[
                const AiBadge(),
                const SizedBox(width: AppSpacing.sm),
              ],
              reviewBadge(
                ReviewStatus.fromApi(current.status),
                aiGenerated: current.isAiGenerated,
              ),
              const SizedBox(width: AppSpacing.sm),
              if (dirty)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Text('Unsaved changes', style: muted),
                ),
              FilledButton.icon(
                onPressed: saving || !dirty ? null : _save,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save'),
              ),
            ],
          ),
          child: TextField(
            controller: _stem,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Question stem'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AdminPanel(
          title: 'Options & misconceptions',
          trailing: Text(
            'Tap a letter to set the correct answer',
            style: muted,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (var i = 0; i < _q.options.length; i++) _option(i)],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SuggestionsPanel(
          questionId: _q.id,
          onSuggest: _suggest,
          onAccept: _accept,
        ),
        const SizedBox(height: AppSpacing.lg),
        AdminPanel(
          title: 'Explanation (shown after answering)',
          child: TextField(
            controller: _explanation,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        QuestionMappingPanel(
          question: _q,
          onChanged: (q) => setState(() => _q = q),
        ),
        const SizedBox(height: AppSpacing.lg),
        AdminPanel(
          title: 'Preview as student',
          trailing: const Icon(
            Icons.visibility_outlined,
            color: AppColors.muted,
          ),
          child: McqStudentPreview(question: current),
        ),
      ],
    );
  }

  Widget _option(int i) {
    final o = _q.options[i];
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: o.isCorrect ? AppColors.successSoft : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            selected: o.isCorrect,
            label: 'Mark ${o.label} as the correct answer',
            child: InkResponse(
              onTap: () => _setCorrect(i),
              radius: 24,
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: o.isCorrect
                        ? AppColors.successDark
                        : AppColors.white,
                    child: o.isCorrect
                        ? const Icon(
                            Icons.check,
                            color: AppColors.white,
                            size: 18,
                          )
                        : Text(o.label),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _optionText[i],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(hintText: 'Option ${o.label}'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: o.isCorrect
                ? const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.successDark,
                        size: 18,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(
                        'Correct answer',
                        style: TextStyle(
                          color: AppColors.successDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : TextField(
                    controller: _misconception[i],
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.sell_outlined, size: 18),
                      hintText: 'Misconception for ${o.label}',
                      filled: true,
                      fillColor: AppColors.primarySoft,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
