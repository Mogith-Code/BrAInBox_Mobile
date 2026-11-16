import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../widgets/admin_page.dart';
import '../../syllabus_manager/application/syllabus_manager_controller.dart';
import '../application/question_bank_controller.dart';
import '../domain/question_bank_models.dart';
import 'widgets/student_preview.dart';

/// Edit question: stem, options with the misconception behind each wrong
/// option, explanation, syllabus mapping, difficulty and a live "Preview as
/// student". Save draft keeps it hidden; Publish approves it.
///
/// Route: `/question-bank/:questionId` (`new` = a new question).
class EditQuestionScreen extends ConsumerWidget {
  const EditQuestionScreen({super.key, required this.questionId});

  final String questionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(questionDetailProvider(questionId));
    return switch (state) {
      AsyncData(:final value) => _Editor(
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

class _Editor extends ConsumerStatefulWidget {
  const _Editor({super.key, required this.initial});

  final QuestionDetail initial;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late QuestionDetail _q = widget.initial;
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
              : _misconception[i].text.trim(),
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

  Future<void> _save({required bool publish}) async {
    final q = _current;
    final problems = publish
        ? q.problems
        : [if (q.stem.trim().isEmpty) 'Write the question stem.'];
    if (problems.isNotEmpty) {
      showAdminSnack(context, problems.first);
      return;
    }
    final saved = await ref
        .read(questionEditorProvider.notifier)
        .save(q, publish: publish);
    if (!mounted) return;
    if (saved == null) {
      showAdminSnack(context, "Couldn't save. Try again.");
      return;
    }
    setState(
      () => _q = _q.copyWith(
        id: saved.id,
        code: saved.code,
        status: saved.status,
      ),
    );
    showAdminSnack(context, publish ? 'Published.' : 'Draft saved.');
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(questionEditorProvider).isLoading;
    final textTheme = Theme.of(context).textTheme;
    final current = _current;

    final left = ListView(
      children: [
        AdminPanel(
          title: 'Question stem',
          trailing: _q.isAiGenerated ? const AiBadge() : null,
          child: TextField(
            controller: _stem,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Write the question'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AdminPanel(
          title: 'Options & misconceptions',
          trailing: Text(
            'Click the circle to set the correct answer',
            style: textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _q.options.length; i++) _option(i),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.warningDark,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Every wrong option needs a misconception so students '
                      'get targeted feedback.',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      ],
    );

    final right = ListView(
      children: [
        _MappingPanel(question: _q, onChanged: (q) => setState(() => _q = q)),
        const SizedBox(height: AppSpacing.lg),
        AdminPanel(
          title: 'Preview as student',
          trailing: const Icon(
            Icons.visibility_outlined,
            color: AppColors.muted,
          ),
          child: StudentPreview(question: current),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPageHeader(
          eyebrow: 'Question bank',
          title: _q.code == null
              ? 'New question'
              : 'Edit question · ${_q.code}',
          actions: [
            TextButton.icon(
              onPressed: () => context.go(AdminRoutes.questionBank),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
            ),
            TextButton(
              onPressed: saving ? null : () => _save(publish: false),
              child: const Text('Save draft'),
            ),
            FilledButton.icon(
              onPressed: saving ? null : () => _save(publish: true),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Publish'),
            ),
          ],
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) => box.maxWidth >= 1000
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: left),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(flex: 2, child: right),
                    ],
                  )
                : ListView(
                    children: [
                      SizedBox(height: 900, child: left),
                      SizedBox(height: 1000, child: right),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _option(int i) {
    final o = _q.options[i];
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
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
              child: CircleAvatar(
                radius: 18,
                backgroundColor: o.isCorrect
                    ? AppColors.successDark
                    : AppColors.white,
                child: o.isCorrect
                    ? const Icon(Icons.check, color: AppColors.white, size: 18)
                    : Text(o.label),
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
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.sell_outlined, size: 18),
                      hintText: 'Misconception',
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

/// Unit -> topic -> concept dropdowns (from the syllabus API) and the
/// difficulty buttons.
class _MappingPanel extends ConsumerWidget {
  const _MappingPanel({required this.question, required this.onChanged});

  final QuestionDetail question;
  final ValueChanged<QuestionDetail> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = question;
    final units = ref.watch(syllabusUnitsProvider).value ?? const [];
    final topics = q.unitId == null
        ? const []
        : ref.watch(unitTopicsProvider(q.unitId!)).value ?? const [];
    final concepts = q.topicId == null
        ? const []
        : ref.watch(topicConceptsProvider(q.topicId!)).value ?? const [];

    DropdownButtonFormField<String> dropdown(
      String label,
      String? value,
      List<(String, String)> items,
      ValueChanged<String?> onSelect,
    ) => DropdownButtonFormField<String>(
      initialValue: items.any((i) => i.$1 == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final (id, text) in items)
          DropdownMenuItem(
            value: id,
            child: Text(text, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onSelect,
    );

    return AdminPanel(
      title: 'Mapping',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          dropdown(
            'Unit',
            q.unitId,
            [
              for (final u in units)
                (u.id, '${u.number.toString().padLeft(2, '0')} ${u.title}'),
            ],
            (id) => onChanged(
              q.copyWith(unitId: id, topicId: null, conceptId: null),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          dropdown(
            'Topic',
            q.topicId,
            [for (final t in topics) (t.id, '${t.number} ${t.title}')],
            (id) => onChanged(q.copyWith(topicId: id, conceptId: null)),
          ),
          const SizedBox(height: AppSpacing.md),
          dropdown('Concept', q.conceptId, [
            for (final c in concepts) (c.id, c.name),
          ], (id) => onChanged(q.copyWith(conceptId: id))),
          const SizedBox(height: AppSpacing.md),
          Text('Difficulty', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<Difficulty>(
            segments: [
              for (final d in Difficulty.values)
                ButtonSegment(value: d, label: Text(d.label)),
            ],
            selected: {q.difficulty},
            onSelectionChanged: (s) =>
                onChanged(q.copyWith(difficulty: s.first)),
          ),
        ],
      ),
    );
  }
}
