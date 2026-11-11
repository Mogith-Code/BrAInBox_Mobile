import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../widgets/admin_page.dart';
import '../application/question_bank_controller.dart';
import '../domain/question_bank_models.dart';

/// Question bank: filter, select rows for bulk actions, page through, and
/// open a question to edit it.
///
/// Route: `/question-bank`. Data: `/admin/questions`.
class QuestionBankScreen extends ConsumerStatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  ConsumerState<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends ConsumerState<QuestionBankScreen> {
  final _selected = <String>{};

  static const _statuses = [
    null,
    'approved',
    'pending_review',
    'draft',
    'rejected',
  ];

  Future<void> _bulk(BulkAction action) async {
    if (action == BulkAction.delete) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Delete ${_selected.length} questions?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    final ok = await ref
        .read(questionBankControllerProvider.notifier)
        .bulk(_selected.toList(), action);
    if (!mounted) return;
    showAdminSnack(
      context,
      ok ? '${action.label}: done.' : "Couldn't do that. Try again.",
    );
    if (ok) setState(_selected.clear);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questionBankControllerProvider);
    final filter = ref.watch(questionFilterControllerProvider);
    final filters = ref.read(questionFilterControllerProvider.notifier);
    final page = state.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPageHeader(
          eyebrow: page == null
              ? null
              : '${Formatters.thousands(page.total)} questions · '
                    '${page.pastPaperPercent}% from past papers',
          title: 'Question bank',
          actions: [
            TextButton.icon(
              onPressed: () => showAdminSnack(
                context,
                'CSV import uses POST /admin/questions/import.',
              ),
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: const Text('Import CSV'),
            ),
            FilledButton.icon(
              onPressed: () => context.go(AdminRoutes.questionEditPath('new')),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New question'),
            ),
          ],
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterDropdown<int?>(
              label: 'Unit',
              value: filter.unit,
              options: [null, for (var u = 1; u <= 10; u++) u],
              labelOf: (u) => u == null ? 'All units' : 'Unit $u',
              onChanged: (u) => filters.set(filter.copyWith(unit: u)),
            ),
            FilterDropdown<QuestionKind?>(
              label: 'Type',
              value: filter.type,
              options: const [null, ...QuestionKind.values],
              labelOf: (t) => t?.label ?? 'Any',
              onChanged: (t) => filters.set(filter.copyWith(type: t)),
            ),
            FilterDropdown<Difficulty?>(
              label: 'Difficulty',
              value: filter.difficulty,
              options: const [null, ...Difficulty.values],
              labelOf: (d) => d?.label ?? 'Any',
              onChanged: (d) => filters.set(filter.copyWith(difficulty: d)),
            ),
            FilterDropdown<String?>(
              label: 'Status',
              value: filter.status,
              options: _statuses,
              labelOf: (s) => s == null
                  ? 'Any'
                  : reviewBadge(ReviewStatus.fromApi(s)).label,
              onChanged: (s) => filters.set(filter.copyWith(status: s)),
            ),
            TextButton(
              onPressed: () => filters.set(const QuestionFilter()),
              child: const Text('Clear all'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: AdminPanel(
            padding: EdgeInsets.zero,
            child: Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selected.isNotEmpty) _bulkBar(),
                  Expanded(
                    child: switch (state) {
                      AsyncData(:final value) when value.items.isEmpty =>
                        const EmptyState(
                          icon: Icons.quiz_outlined,
                          title: 'No questions match',
                          message: 'Try other filters.',
                        ),
                      AsyncData(:final value) => _table(value.items),
                      AsyncError(:final error) => AdminLoadError(
                        error: error,
                        onRetry: () =>
                            ref.invalidate(questionBankControllerProvider),
                      ),
                      _ => const Center(child: CircularProgressIndicator()),
                    },
                  ),
                  if (page != null && page.items.isNotEmpty)
                    _Pager(
                      page: filter.page,
                      shown: page.items.length,
                      total: page.total,
                      onPage: filters.page,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bulkBar() {
    return Container(
      color: AppColors.ink,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            '${_selected.length} selected',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          for (final a in BulkAction.values)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: AppColors.white),
              onPressed: () => _bulk(a),
              icon: Icon(switch (a) {
                BulkAction.approve => Icons.check,
                BulkAction.markOutdated => Icons.warning_amber_rounded,
                BulkAction.delete => Icons.delete_outline,
              }, size: 18),
              label: Text(a.label),
            ),
          const Spacer(),
          IconButton(
            tooltip: 'Clear selection',
            color: AppColors.white,
            onPressed: () => setState(_selected.clear),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _table(List<QuestionRow> rows) {
    return ListView.separated(
      itemCount: rows.length + 1,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i == 0) {
          final all = rows.every((r) => _selected.contains(r.id));
          return _Line(
            leading: Checkbox(
              value: all,
              onChanged: (v) => setState(
                () => v == true
                    ? _selected.addAll(rows.map((r) => r.id))
                    : _selected.removeAll(rows.map((r) => r.id)),
              ),
            ),
            cells: const [
              TableHeading('ID'),
              TableHeading('Question'),
              TableHeading('Unit · Topic'),
              TableHeading('Type'),
              TableHeading('Difficulty'),
              TableHeading('Source'),
              TableHeading('Status'),
            ],
          );
        }
        final r = rows[i - 1];
        final muted = Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.muted);
        return InkWell(
          onTap: () => context.go(AdminRoutes.questionEditPath(r.id)),
          child: _Line(
            selected: _selected.contains(r.id),
            leading: Checkbox(
              value: _selected.contains(r.id),
              onChanged: (v) => setState(
                () => v == true ? _selected.add(r.id) : _selected.remove(r.id),
              ),
            ),
            cells: [
              Text(r.code, style: muted?.copyWith(fontFamily: 'monospace')),
              Text(r.stem, maxLines: 2, overflow: TextOverflow.ellipsis),
              Text(
                '${r.unitNumber == null ? '' : 'Unit ${r.unitNumber} · '}${r.topicTitle ?? ''}',
                style: muted,
              ),
              Text(r.type.label),
              Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(
                  label: r.difficulty.label,
                  showIcon: false,
                  tone: switch (r.difficulty) {
                    Difficulty.easy => BadgeTone.success,
                    Difficulty.medium => BadgeTone.warning,
                    Difficulty.hard => BadgeTone.danger,
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: r.sourceYear != null
                    ? Text('${r.sourceYear} paper', style: muted)
                    : r.isAiGenerated
                    ? const AiBadge(label: 'AI')
                    : Text('Teacher', style: muted),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: reviewBadge(
                  ReviewStatus.fromApi(r.status),
                  aiGenerated: r.isAiGenerated,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.leading,
    required this.cells,
    this.selected = false,
  });

  final Widget leading;
  final List<Widget> cells;
  final bool selected;

  static const _flex = [2, 8, 3, 2, 2, 2, 4];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: selected ? AppColors.primarySoft : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          leading,
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: _flex[i],
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: cells[i],
              ),
            ),
        ],
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
    required this.page,
    required this.shown,
    required this.total,
    required this.onPage,
  });

  final int page;
  final int shown;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final first = (page - 1) * QuestionFilter.pageSize + 1;
    final last = first + shown - 1;
    final pages = (total / QuestionFilter.pageSize).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            'Showing $first–$last of ${Formatters.thousands(total)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Previous page',
            onPressed: page > 1 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('$page / $pages'),
          IconButton(
            tooltip: 'Next page',
            onPressed: page < pages ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
