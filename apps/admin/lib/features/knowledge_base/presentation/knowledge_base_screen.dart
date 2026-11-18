import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/admin_page.dart';
import '../application/knowledge_base_controller.dart';
import '../domain/knowledge_base_models.dart';
import 'widgets/new_model_answer_dialog.dart';

/// Knowledge base: model answers for structured / essay questions, each with
/// marking points (text, marks, keywords). Only an approved answer with
/// marking points lets students practise the question.
///
/// Route: `/knowledge-base`. Data: `GET /admin/model-answers`,
/// `POST /admin/model-answers`, `PUT /admin/model-answers/{id}/keywords`.
class KnowledgeBaseScreen extends ConsumerStatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  ConsumerState<KnowledgeBaseScreen> createState() =>
      _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends ConsumerState<KnowledgeBaseScreen> {
  String? _selectedId;

  Future<void> _add(List<ModelAnswer> existing) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => NewModelAnswerDialog(
        takenQuestionIds: {for (final a in existing) a.questionId},
      ),
    );
    if (created == true && mounted) {
      setState(
        () => _selectedId = ref.read(modelAnswersProvider).value?.first.id,
      );
      showAdminSnack(context, 'Model answer saved.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(modelAnswerStatusProvider);
    final state = ref.watch(modelAnswersProvider);
    final rows = state.value;
    final selected =
        rows?.where((a) => a.id == _selectedId).firstOrNull ??
        rows?.firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPageHeader(
          eyebrow: rows == null
              ? 'Model answers used to mark written answers'
              : '${rows.length} model answers · '
                    '${rows.where((a) => a.isPractisable).length} practisable',
          title: 'Knowledge base',
          actions: [
            FilterDropdown<ReviewStatus?>(
              label: 'Status',
              value: status,
              options: const [
                null,
                ReviewStatus.draft,
                ReviewStatus.pendingReview,
                ReviewStatus.approved,
                ReviewStatus.rejected,
                ReviewStatus.archived,
              ],
              labelOf: (s) => switch (s) {
                null => 'Any',
                ReviewStatus.pendingReview => 'Pending review',
                ReviewStatus.archived => 'Archived',
                _ => s.name[0].toUpperCase() + s.name.substring(1),
              },
              onChanged: (s) =>
                  ref.read(modelAnswerStatusProvider.notifier).set(s),
            ),
            FilledButton.icon(
              onPressed: rows == null ? null : () => _add(rows),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add model answer'),
            ),
          ],
        ),
        Expanded(
          child: switch (state) {
            AsyncError(:final error) when rows == null => AdminLoadError(
              error: error,
              onRetry: () => ref.invalidate(modelAnswersProvider),
            ),
            _ when rows == null => const Center(
              child: CircularProgressIndicator(),
            ),
            _ when rows.isEmpty => EmptyState(
              icon: Icons.menu_book_outlined,
              title: status == null
                  ? 'No model answers yet'
                  : 'No model answers with this status',
              message:
                  'Add a model answer with marking points so students can '
                  'practise a structured or essay question.',
            ),
            _ => LayoutBuilder(
              builder: (context, box) {
                final list = _AnswerList(
                  rows: rows,
                  selectedId: selected?.id,
                  onSelect: (id) => setState(() => _selectedId = id),
                );
                final detail = selected == null
                    ? const SizedBox.shrink()
                    : ModelAnswerDetail(
                        key: ValueKey(selected.id),
                        answer: selected,
                      );
                if (box.maxWidth >= 1000) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: list),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(child: detail),
                      ),
                    ],
                  );
                }
                return ListView(
                  children: [
                    SizedBox(height: 360, child: list),
                    const SizedBox(height: AppSpacing.lg),
                    detail,
                  ],
                );
              },
            ),
          },
        ),
      ],
    );
  }
}

/// Status badge + whether students can practise it (icon + word + colour).
class PractisableBadge extends StatelessWidget {
  const PractisableBadge({super.key, required this.answer});

  final ModelAnswer answer;

  @override
  Widget build(BuildContext context) => answer.isPractisable
      ? const StatusBadge(
          label: 'Students can practise',
          tone: BadgeTone.success,
        )
      : StatusBadge(
          label: answer.status == ReviewStatus.approved
              ? 'Not practisable · no marking points'
              : 'Not practisable',
          tone: BadgeTone.danger,
        );
}

class _AnswerList extends StatelessWidget {
  const _AnswerList({
    required this.rows,
    required this.selectedId,
    required this.onSelect,
  });

  final List<ModelAnswer> rows;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.muted);
    return AdminPanel(
      padding: EdgeInsets.zero,
      child: Flexible(
        child: Material(
          type: MaterialType.transparency,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final a = rows[i];
              return ListTile(
                minTileHeight: 64,
                selected: a.id == selectedId,
                selectedTileColor: AppColors.primarySoft,
                onTap: () => onSelect(a.id),
                title: Text(
                  '${a.questionCode ?? 'Question'} · '
                  '${a.questionStem ?? a.answerText}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      reviewBadge(a.status, aiGenerated: a.isAiWritten),
                      PractisableBadge(answer: a),
                      Text(
                        '${_marks(a.totalMarks)} marks · '
                        '${a.points.length} points',
                        style: muted,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

String _marks(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// One model answer: the text, its marking points and their keywords.
class ModelAnswerDetail extends ConsumerStatefulWidget {
  const ModelAnswerDetail({super.key, required this.answer});

  final ModelAnswer answer;

  @override
  ConsumerState<ModelAnswerDetail> createState() => _ModelAnswerDetailState();
}

class _ModelAnswerDetailState extends ConsumerState<ModelAnswerDetail> {
  bool _editing = false;
  bool _saving = false;
  final _fields = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _startEditing() {
    for (final p in widget.answer.points) {
      (_fields[p.id] ??= TextEditingController()).text = p.keywords.join(', ');
    }
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    final changed = <String, List<String>>{
      for (final p in widget.answer.points)
        if (splitKeywords(_fields[p.id]!.text) case final words
            when words.join('\n') != p.keywords.join('\n'))
          p.id: words,
    };
    if (changed.isEmpty) {
      setState(() => _editing = false);
      return;
    }
    setState(() => _saving = true);
    final error = await ref
        .read(modelAnswersProvider.notifier)
        .setKeywords(widget.answer.id, changed);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (error == null) _editing = false;
    });
    showAdminSnack(context, error ?? 'Keywords saved.');
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.answer;
    final textTheme = Theme.of(context).textTheme;
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.muted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPanel(
          title: a.questionCode ?? 'Question',
          trailing: a.isAiWritten ? const AiBadge() : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if ((a.questionStem ?? '').isNotEmpty)
                Text(
                  a.questionStem!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  reviewBadge(a.status, aiGenerated: a.isAiWritten),
                  PractisableBadge(answer: a),
                ],
              ),
              if (!a.isPractisable) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  a.status == ReviewStatus.approved
                      ? 'Add marking points so the evaluator can mark answers.'
                      : 'Students can\'t practise this question until its '
                            'model answer is approved. Approving an answer '
                            'that is already saved isn\'t available yet.',
                  style: muted,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text('Model answer', style: textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              SelectableText(a.answerText),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AdminPanel(
          title: 'Marking points · ${_marks(a.totalMarks)} marks',
          trailing: a.points.isEmpty
              ? null
              : _editing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() => _editing = false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: const Text('Save keywords'),
                    ),
                  ],
                )
              : TextButton.icon(
                  onPressed: _startEditing,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit keywords'),
                ),
          child: a.points.isEmpty
              ? Text('No marking points.', style: muted)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, p) in a.points.indexed) ...[
                      if (i > 0) const Divider(height: AppSpacing.lg),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primarySoft,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(p.text)),
                          Text(
                            '${_marks(p.marks)} '
                            '${p.marks == 1 ? 'mark' : 'marks'}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (_editing)
                        TextField(
                          controller: _fields[p.id],
                          decoration: InputDecoration(
                            labelText: 'Keywords for point ${i + 1}',
                            helperText: 'Separate with commas',
                          ),
                        )
                      else if (p.keywords.isEmpty)
                        Text('No keywords', style: muted)
                      else
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (final k in p.keywords)
                              Chip(
                                label: Text(k),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
