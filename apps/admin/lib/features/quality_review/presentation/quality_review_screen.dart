import 'package:brainbox_core/brainbox_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../widgets/admin_page.dart';
import '../application/quality_review_controller.dart';
import '../domain/quality_review_models.dart';

/// Question quality review: AI questions are checked automatically before a
/// human looks at them. Shows the queue numbers, each question's checks,
/// and a detail panel to Approve, Edit or Reject.
///
/// Route: `/quality-review`. Data: `/admin/questions/quality`.
class QualityReviewScreen extends ConsumerStatefulWidget {
  const QualityReviewScreen({super.key});

  @override
  ConsumerState<QualityReviewScreen> createState() =>
      _QualityReviewScreenState();
}

class _QualityReviewScreenState extends ConsumerState<QualityReviewScreen> {
  String? _selectedId;

  static const _columns = [
    'Single correct answer',
    'Distractor quality',
    'Syllabus match',
  ];

  Future<void> _done(Future<bool> action, String success) async {
    final ok = await action;
    if (mounted) {
      showAdminSnack(context, ok ? success : "Couldn't save. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qualityReviewControllerProvider);
    final controller = ref.read(qualityReviewControllerProvider.notifier);
    final queue = state.value;
    final items = queue?.items ?? const <QualityItem>[];
    // Open the worst one first: a failed check, then one needing review.
    final selected =
        items.where((i) => i.id == _selectedId).firstOrNull ??
        items
            .where((i) => i.checks.any((c) => c.result == CheckResult.fail))
            .firstOrNull ??
        items.where((i) => !i.allPass).firstOrNull ??
        items.firstOrNull;
    final passing = items.where((i) => i.allPass).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPageHeader(
          eyebrow: 'AI-generated questions · auto-checked before human review',
          title: 'Question quality review',
          actions: [
            TextButton.icon(
              onPressed: passing == 0
                  ? null
                  : () => _done(
                      controller.approveAllPassing(),
                      'Approved $passing questions.',
                    ),
              icon: const Icon(Icons.done_all, size: 18),
              label: Text('Approve all passing ($passing)'),
            ),
          ],
        ),
        if (queue != null) ...[
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _Stat('In queue', '${queue.inQueue}', AppColors.ink),
              _Stat(
                'Auto-check failed',
                '${queue.autoCheckFailed}',
                AppColors.error,
              ),
              _Stat(
                'With student reports',
                '${queue.withStudentReports}',
                AppColors.warningDark,
              ),
              _Stat(
                'Avg. time to review',
                queue.avgReviewMinutes == null
                    ? '—'
                    : Formatters.studyTime(
                        Duration(minutes: queue.avgReviewMinutes!),
                      ),
                AppColors.secondaryDark,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Expanded(
          child: switch (state) {
            AsyncData() when items.isEmpty => const EmptyState(
              icon: Icons.task_alt,
              title: 'Queue is empty',
              message: 'New AI questions are checked and land here.',
            ),
            AsyncData() => Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: AdminPanel(
                    padding: EdgeInsets.zero,
                    child: Expanded(
                      child: ListView.separated(
                        itemCount: items.length + 1,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) => i == 0
                            ? const _QueueRow(
                                cells: [
                                  TableHeading('Question'),
                                  TableHeading('Single correct answer'),
                                  TableHeading('Distractor quality'),
                                  TableHeading('Syllabus match'),
                                ],
                              )
                            : _itemRow(items[i - 1], selected),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 2,
                  child: selected == null
                      ? const SizedBox()
                      : _Detail(
                          item: selected,
                          onReview: (approve) => _done(
                            controller.review(selected.id, approve: approve),
                            approve ? 'Approved.' : 'Rejected.',
                          ),
                        ),
                ),
              ],
            ),
            AsyncError(:final error) => AdminLoadError(
              error: error,
              onRetry: () => ref.invalidate(qualityReviewControllerProvider),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }

  Widget _itemRow(QualityItem item, QualityItem? selected) {
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: AppColors.muted);
    return Material(
      color: item.id == selected?.id
          ? AppColors.primarySoft
          : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedId = item.id),
        child: _QueueRow(
          cells: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.stem,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${item.code} · Unit ${item.unitNumber ?? '—'} · ${item.topicCode ?? ''}',
                  style: muted,
                ),
              ],
            ),
            for (final name in _columns) _ResultChip(item.result(name)),
          ],
        ),
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.cells});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: i == 0 ? 4 : 2,
              child: Align(alignment: Alignment.centerLeft, child: cells[i]),
            ),
        ],
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip(this.result);

  final CheckResult? result;

  @override
  Widget build(BuildContext context) => switch (result) {
    null => const Text('—'),
    CheckResult.pass => const StatusBadge(
      label: 'Pass',
      tone: BadgeTone.success,
    ),
    CheckResult.review => const StatusBadge(
      label: 'Review',
      tone: BadgeTone.warning,
    ),
    CheckResult.fail => const StatusBadge(
      label: 'Fail',
      tone: BadgeTone.danger,
    ),
  };
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: AdminPanel(
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.item, required this.onReview});

  final QualityItem item;
  final ValueChanged<bool> onReview;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AdminPanel(
      child: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const AiBadge(),
                const SizedBox(width: AppSpacing.sm),
                Text(item.code, style: textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.stem,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(height: AppSpacing.xl),
            Expanded(
              child: ListView(
                children: [
                  for (final c in item.checks)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ResultChip(c.result),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  c.note,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (item.studentReports.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorSoft,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.reportTotal} student reports',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            item.studentReports
                                .map((r) => '"${r.text}" ×${r.count}')
                                .join(' · '),
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    onPressed: () => onReview(false),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.go(AdminRoutes.questionEditPath(item.id)),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.successDark,
                    ),
                    onPressed: () => onReview(true),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
